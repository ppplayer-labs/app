import Flutter
import UIKit
import AVFoundation
import WebKit
import MediaPlayer
import AVKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // ---------------------------------------------------------------------------
  // Startup timing — helps diagnose slow-launch issues.
  // Remove or guard with #if DEBUG when no longer needed.
  // ---------------------------------------------------------------------------
  private let startupStart = CFAbsoluteTimeGetCurrent()
  private func startupLog(_ msg: String) {
    let ms = Int((CFAbsoluteTimeGetCurrent() - startupStart) * 1000)
    NSLog("[ppplayer-startup %dms] %@", ms, msg)
  }

  // ---------------------------------------------------------------------------
  // WKWebView visibility-patch state
  // ---------------------------------------------------------------------------
  private var patchTimer: Timer?
  private var networkOutputsHost: PPNetworkOutputsHost?
  private var localFilesHost: PPLocalFilesHost?
  private var airPlayRoutes: PPAirPlayRouteObserver?
  private var mediaCommands: PPIOSMediaCommands?

  // Weak set of all WKWebViews that have been patched, for fast re-injection
  // when the app returns from background.
  private var patchedWebViews = NSHashTable<WKWebView>.weakObjects()
  private let visibilityPatchScript = """
    (function() {
      if (window.__ppplayerVisibilityPatched) return;
      window.__ppplayerVisibilityPatched = true;

      Object.defineProperty(document, 'hidden', { get: () => false, configurable: true });
      Object.defineProperty(document, 'visibilityState', { get: () => 'visible', configurable: true });
      Object.defineProperty(document, 'webkitHidden', { get: () => false, configurable: true });
      Object.defineProperty(document, 'webkitVisibilityState', { get: () => 'visible', configurable: true });

      if (navigator.mediaSession) {
        // WebKit's active video session can receive system controls instead of
        // MPRemoteCommandCenter. Forward those actions to Flutter too, so a
        // deliberate pause changes intent before pause recovery can run.
        const session = navigator.mediaSession;
        const setAction = session.setActionHandler.bind(session);
        const commands = {
          play: 'play', pause: 'pause', seekto: 'seek',
          previoustrack: 'previous', nexttrack: 'next'
        };
        const forward = (action) => (details) => {
          const message = {command: commands[action]};
          if (action === 'seekto') {
            if (!details || !Number.isFinite(details.seekTime)) return;
            message.positionMs = Math.round(details.seekTime * 1000);
          }
          window.webkit.messageHandlers.ppplayerMediaCommand.postMessage(message);
        };
        // YouTube installs its own handlers after initialization. Keep our
        // intent bridge installed when it subsequently sets or clears them.
        session.setActionHandler = (action, handler) => {
          setAction(action, commands[action] ? forward(action) : handler);
        };
        for (const action of Object.keys(commands)) {
          try { setAction(action, forward(action)); } catch (_) {}
        }
      }

      // Swallow visibilitychange at the capture phase on both window and document
      // so YouTube's iframe listener never sees document.hidden === true.
      const stop = (e) => { e.stopImmediatePropagation(); };
      window.addEventListener('visibilitychange', stop, true);
      window.addEventListener('webkitvisibilitychange', stop, true);
      window.addEventListener('pagehide', stop, true);
      window.addEventListener('blur', stop, true);
      window.addEventListener('focus', stop, true);
      window.addEventListener('focusin', stop, true);
      window.addEventListener('focusout', stop, true);
      document.addEventListener('visibilitychange', stop, true);
      document.addEventListener('webkitvisibilitychange', stop, true);

    })();
  """

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    startupLog("didFinishLaunchingWithOptions begin")

    // Configure the audio *category* synchronously — this is fast and does not
    // block waiting for SpringBoard XPC. We intentionally do NOT call
    // setActive(true) here because it can block the main thread for several
    // seconds when another app (Spotify, YouTube, etc.) is actively playing.
    // Session activation is deferred to the moment playback actually starts,
    // via activateAudioSession() which is called from the Dart side over the
    // ios_media_controls channel before the first play command.
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .default,
        options: []
      )
    } catch {
      NSLog("[ppplayer] Failed to configure audio category: %@", error.localizedDescription)
    }

    // Register for audio interruptions and route changes so we can
    // reactivate the session after an interruption ends.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance()
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRouteChange(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: AVAudioSession.sharedInstance()
    )

    startupLog("audio category configured")
    schedulePatchScan()
    startupLog("schedulePatchScan called")



    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    startupLog("super.application complete")
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    startupLog("didInitializeImplicitFlutterEngine — registering plugins")
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PPNetworkOutputs") {
      networkOutputsHost = PPNetworkOutputsHost(messenger: registrar.messenger())
      localFilesHost = PPLocalFilesHost(messenger: registrar.messenger())
      airPlayRoutes = PPAirPlayRouteObserver(messenger: registrar.messenger())
      registrar.register(PPAirPlayPickerFactory(), withId: "com.ppplayer.app/airplay_picker")
    }
    startupLog("plugins registered")

    // Expose an activation method so Dart can trigger setActive(true) right
    // before starting playback rather than at app launch.
    // applicationRegistrar conforms to FlutterBaseRegistrar which exposes messenger().
    let channel = FlutterMethodChannel(
      name: "com.ppplayer.app/ios_media_controls",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    mediaCommands = PPIOSMediaCommands(channel: channel)
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "activateAudioSession":
        if self?.activateAudioSession() == true {
          result(nil)
        } else {
          result(FlutterError(code: "audio_session_activation_failed", message: "Could not activate playback audio session", details: nil))
        }
      case "updateNowPlaying":
        guard let values = call.arguments as? [String: Any] else {
          result(FlutterError(code: "invalid_now_playing", message: "Expected playback metadata", details: nil))
          return
        }
        self?.mediaCommands?.updateNowPlaying(values)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // ---------------------------------------------------------------------------
  // AVAudioSession helpers
  // ---------------------------------------------------------------------------



  /// Activates the audio session right before playback starts.
  /// Called from Dart via the ios_media_controls method channel.
  @discardableResult
  @objc func activateAudioSession() -> Bool {
    do {
      let session = AVAudioSession.sharedInstance()
      // Media renderers can change the shared category after app startup.
      // Restore background-capable playback when starting/resuming audio.
      if session.category != .playback || session.mode != .default {
        try session.setCategory(.playback, mode: .default, options: [])
      }
      try session.setActive(true)
      NSLog("[ppplayer-audio] session activated category=%@ appState=%ld", session.category.rawValue, UIApplication.shared.applicationState.rawValue)
      return true
    } catch {
      NSLog("[ppplayer] AVAudioSession activation failed: %@", error.localizedDescription)
      return false
    }
  }

  /// Handles system audio interruptions (phone call, Siri, other apps).
  @objc private func handleAudioInterruption(_ notification: Notification) {
    guard let info = notification.userInfo,
          let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

    let suspended = info[AVAudioSessionInterruptionWasSuspendedKey] as? Bool ?? false
    NSLog("[ppplayer-audio] interruption=%@ suspended=%d category=%@ appState=%ld", type == .began ? "began" : "ended", suspended ? 1 : 0, AVAudioSession.sharedInstance().category.rawValue, UIApplication.shared.applicationState.rawValue)

    if type == .ended {
      // Re-activate after interruption ends so playback can resume.
      let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
      NSLog("[ppplayer-audio] interruption shouldResume=%d", options.contains(.shouldResume) ? 1 : 0)
      if options.contains(.shouldResume) {
        activateAudioSession()
      }
    }
  }

  /// Handles audio route changes (headphone plug/unplug, Bluetooth connect).
  @objc private func handleRouteChange(_ notification: Notification) {
    guard let info = notification.userInfo,
          let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

    NSLog("[ppplayer-audio] routeChange reason=%lu", reasonValue)

    switch reason {
    case .oldDeviceUnavailable:
      // Headphones unplugged — iOS convention is to pause. We log; Dart
      // handles the actual pause via audio_session's interruptionStream.
      NSLog("[ppplayer] Route change: old device unavailable (headphones removed).")
    default:
      break
    }
  }

  // ---------------------------------------------------------------------------
  // WKWebView visibility patch
  // ---------------------------------------------------------------------------

  private func schedulePatchScan() {
    patchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
      guard let self = self else { timer.invalidate(); return }

      let scenes = UIApplication.shared.connectedScenes
      let windowScenes = scenes.compactMap { $0 as? UIWindowScene }
      let windows = windowScenes.flatMap { $0.windows }

      var found = false
      for window in windows {
        if self.injectPatches(into: window) {
          found = true
        }
      }

      if found {
        timer.invalidate()
        self.patchTimer = nil
        NSLog("[ppplayer] Visibility patch injected into WKWebView(s) on iOS.")
      }
    }
  }

  @discardableResult
  private func injectPatches(into view: UIView) -> Bool {
    var found = false

    if let webView = view as? WKWebView {
      let script = WKUserScript(
        source: visibilityPatchScript,
        injectionTime: .atDocumentStart,
        forMainFrameOnly: false
      )

      var hasInjected = false
      for s in webView.configuration.userContentController.userScripts {
        if s.source == self.visibilityPatchScript {
          hasInjected = true
          break
        }
      }

      if !hasInjected, let mediaCommands = mediaCommands {
        webView.configuration.userContentController.add(mediaCommands, name: "ppplayerMediaCommand")
        webView.configuration.userContentController.addUserScript(script)
        // Install in the current wrapper immediately. A child frame created
        // before this scan needs one navigation to receive document-start
        // scripts; retain the wrapper and its Flutter JavaScript channels.
        webView.evaluateJavaScript(self.visibilityPatchScript + """
          document.querySelectorAll('iframe').forEach((frame) => {
            if (/^https:\\/\\/(www\\.)?youtube(-nocookie)?\\.com\\//.test(frame.src)) {
              frame.src = frame.src;
            }
          });
          """, completionHandler: nil)
      }
      // Track this webView for fast foreground re-injection.
      patchedWebViews.add(webView)
      found = true
    }

    for sub in view.subviews {
      if injectPatches(into: sub) { found = true }
    }
    return found
  }
}

/// Public system routing UI. The user taps the real AVRoutePickerView button.
private final class PPAirPlayPickerFactory: NSObject, FlutterPlatformViewFactory {
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return PPAirPlayPicker(frame: frame)
  }
}

private final class PPAirPlayPicker: NSObject, FlutterPlatformView {
  private let picker: AVRoutePickerView
  init(frame: CGRect) {
    picker = AVRoutePickerView(frame: frame)
    picker.prioritizesVideoDevices = true
    super.init()
  }
  func view() -> UIView { picker }
}

private final class PPNetworkOutputsHost: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var routeObserver: NSObjectProtocol?
  private var leases: [String: (URL, Bool)] = [:]
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private var castHost: PPCastHost?

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(name: "com.ppplayer.app/network_outputs", binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(name: "com.ppplayer.app/network_output_events", binaryMessenger: messenger)
    super.init()
    castHost = PPCastHost(methodChannel: methodChannel, eventSink: { [weak self] in self?.eventSink })
    methodChannel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
    eventChannel.setStreamHandler(self)
    routeObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance(), queue: .main) { [weak self] _ in self?.emitRoute() }
  }

  deinit {
    if let observer = routeObserver { NotificationCenter.default.removeObserver(observer) }
    for (_, lease) in leases where lease.1 { lease.0.stopAccessingSecurityScopedResource() }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    emitRoute()
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { eventSink = nil; return nil }

  private func emitRoute() {
    let route = AVAudioSession.sharedInstance().currentRoute.outputs.first { $0.portType == .airPlay }
    eventSink?(["event": "airPlayRoute", "connected": route != nil, "name": route?.portName ?? ""])
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    do {
      switch call.method {
      case "getPlatformCapabilities":
        let multicastEnabled = dlnaMulticastEnabled

        result(["googleCastAvailable": true, "googleCastUnavailableReason": "", "airPlayPickerAvailable": true, "airPlayVerified": false, "dlnaDiscoveryAvailable": multicastEnabled, "dlnaUnavailableReason": multicastEnabled ? "" : "DLNA discovery requires Apple multicast approval and an enabled build configuration."])
      case "startDiscovery":
        castHost?.startDiscovery()
        result(nil)
      case "stopDiscovery":
        castHost?.stopDiscovery()
        result(nil)
      case "connect":
        if let id = args["endpointId"] as? String {
            try castHost?.connect(endpointId: id)
            result(nil)
        } else {
            result(FlutterError(code: "INVALID", message: "Missing endpointId", details: nil))
        }
      case "disconnect":
        castHost?.disconnect(stopPlayback: args["stopPlayback"] as? Bool ?? false)
        result(nil)
      case "load":
        if let item = args["item"] as? [String: Any], let sid = args["sessionId"] as? String, let id = args["itemId"] as? String {
            castHost?.load(item: item, sessionId: sid, itemId: id, autoplay: args["autoplay"] as? Bool ?? true, positionMs: args["positionMs"] as? Double ?? 0.0, result: result)
        } else {
            result(FlutterError(code: "INVALID", message: "Missing load args", details: nil))
        }
      case "play":
        castHost?.play()
        result(nil)
      case "pause":
        castHost?.pause()
        result(nil)
      case "stop":
        castHost?.stop()
        result(nil)
      case "seek":
        castHost?.seek(positionMs: args["positionMs"] as? Double ?? 0.0)
        result(nil)
      case "setVolume":
        castHost?.setVolume(args["volume"] as? Float ?? 1.0)
        result(nil)
      case "setMute":
        castHost?.setMute(args["muted"] as? Bool ?? false)
        result(nil)
      case "getAirPlayRoute":
        let route = AVAudioSession.sharedInstance().currentRoute.outputs.first { $0.portType == .airPlay }
        result(["connected": route != nil, "name": route?.portName ?? ""])
      case "getWebKitAirPlayConfiguration":
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
        var values: [Bool] = []
        func visit(_ view: UIView) {
          if let webView = view as? WKWebView { values.append(webView.configuration.allowsAirPlayForMediaPlayback) }
          view.subviews.forEach(visit)
        }
        windows.forEach(visit)
        result(["webViewCount": values.count, "allowsAirPlay": values])
      case "acquireFileLease":
        guard leases.count < 8 else { throw NSError(domain: "PPNetworkOutputs", code: 1, userInfo: [NSLocalizedDescriptionKey: "Too many active file leases."]) }
        let url: URL
        if let bookmark = args["bookmark"] as? String, let data = Data(base64Encoded: bookmark) {
          var stale = false
          var options: URL.BookmarkResolutionOptions = [.withoutUI]
          if #available(iOS 14.2, *) { options.insert(.withoutImplicitStartAccessing) }
          url = try URL(resolvingBookmarkData: data, options: options, relativeTo: nil, bookmarkDataIsStale: &stale)
          guard !stale else { result(FlutterError(code: "BOOKMARK_STALE", message: "Select this file again to renew access.", details: nil)); return }
        } else {
          guard let uri = args["uri"] as? String, let parsed = URL(string: uri), parsed.isFileURL else { result(FlutterError(code: "UNSUPPORTED_URI", message: "A file URL or bookmark is required.", details: nil)); return }
          url = parsed
        }
        let scoped = url.startAccessingSecurityScopedResource()
        let canonical = url.resolvingSymlinksInPath().standardizedFileURL
        do {
          let values = try canonical.resourceValues(forKeys: [.isRegularFileKey])
          guard values.isRegularFile == true, FileManager.default.isReadableFile(atPath: canonical.path) else { throw NSError(domain: "PPNetworkOutputs", code: 2, userInfo: [NSLocalizedDescriptionKey: "The selected file cannot be read."]) }
        } catch {
          if scoped { url.stopAccessingSecurityScopedResource() }
          throw error
        }
        let id = UUID().uuidString
        leases[id] = (url, scoped)
        result(["leaseId": id, "canonicalPath": canonical.path])
      case "releaseFileLease":
        if let id = args["leaseId"] as? String, let lease = leases.removeValue(forKey: id), lease.1 { lease.0.stopAccessingSecurityScopedResource() }
        result(nil)
      case "setMulticastLock": result(nil)
      default: result(FlutterError(code: "OUTPUT_UNAVAILABLE", message: "This network output is unavailable on iOS.", details: nil))
      }
    } catch {
      result(FlutterError(code: "FILE_ACCESS", message: error.localizedDescription, details: nil))
    }
  }
}
import Foundation
import Flutter
import GoogleCast

class PPCastHost: NSObject, GCKDiscoveryManagerListener, GCKSessionManagerListener, GCKRemoteMediaClientListener, GCKRequestDelegate {
    private let methodChannel: FlutterMethodChannel
    private let eventSink: () -> FlutterEventSink?
    
    private var castSession: GCKCastSession? {
        return GCKCastContext.sharedInstance().sessionManager.currentCastSession
    }
    
    private var castClient: GCKRemoteMediaClient? {
        return castSession?.remoteMediaClient
    }
    
    init(methodChannel: FlutterMethodChannel, eventSink: @escaping () -> FlutterEventSink?) {
        self.methodChannel = methodChannel
        self.eventSink = eventSink
        super.init()
        
        let criteria = GCKDiscoveryCriteria(applicationID: "CC1AD845")
        let options = GCKCastOptions(discoveryCriteria: criteria)
        options.suspendSessionsWhenBackgrounded = false
        GCKCastContext.setSharedInstanceWith(options)
        
        GCKCastContext.sharedInstance().discoveryManager.add(self)
        GCKCastContext.sharedInstance().sessionManager.add(self)
    }
    
    private func emitEvent(_ event: [String: Any]) {
        eventSink()?(event)
    }
    
    // MARK: - Discovery
    
    func startDiscovery() {
        NSLog("[PPCastHost] startDiscovery() called. current state: %ld", GCKCastContext.sharedInstance().discoveryManager.discoveryState.rawValue)
        GCKCastContext.sharedInstance().discoveryManager.startDiscovery()
        NSLog("[PPCastHost] startDiscovery() invoked on manager. new state: %ld", GCKCastContext.sharedInstance().discoveryManager.discoveryState.rawValue)
        emitDevices()
    }
    
    func stopDiscovery() {
        NSLog("[PPCastHost] stopDiscovery() called.")
        GCKCastContext.sharedInstance().discoveryManager.stopDiscovery()
    }

    func didStartDiscovery(forDeviceCategory deviceCategory: String) {
        NSLog("[PPCastHost] didStartDiscovery for category: %@", deviceCategory)
    }

    func didUpdateDiscoveryState(_ discoveryState: GCKDiscoveryState) {
        NSLog("[PPCastHost] didUpdateDiscoveryState: %ld", discoveryState.rawValue)
    }
    
    func didInsert(_ device: GCKDevice, at index: UInt) {
        NSLog("[PPCastHost] didInsert device: %@ at index: %lu", device.friendlyName ?? "Unknown", index)
        emitDevices()
    }
    func didUpdate(_ device: GCKDevice, at index: UInt) {
        NSLog("[PPCastHost] didUpdate device: %@ at index: %lu", device.friendlyName ?? "Unknown", index)
        emitDevices()
    }
    func didUpdate(_ device: GCKDevice, at index: UInt, andMoveTo newIndex: UInt) {
        NSLog("[PPCastHost] didUpdate/Move device: %@ to index: %lu", device.friendlyName ?? "Unknown", newIndex)
        emitDevices()
    }
    func didRemove(_ device: GCKDevice, at index: UInt) {
        NSLog("[PPCastHost] didRemove device: %@ at index: %lu", device.friendlyName ?? "Unknown", index)
        emitDevices()
    }
    
    private func emitDevices() {
        let count = GCKCastContext.sharedInstance().discoveryManager.deviceCount
        NSLog("[PPCastHost] emitDevices called. Total count: %lu", count)
        var devices = [[String: Any]]()
        for i in 0..<count {
            let d = GCKCastContext.sharedInstance().discoveryManager.device(at: UInt(i))
            devices.append([
                "id": d.deviceID,
                "name": d.friendlyName ?? "Unknown Cast Device",
                "model": d.modelName ?? "Unknown",
                "audio": true,
                "video": true
            ])
        }
        emitEvent(["event": "devices", "kind": "googleCast", "devices": devices])
    }
    
    // MARK: - Connection
    
    func connect(endpointId: String) throws {
        let count = GCKCastContext.sharedInstance().discoveryManager.deviceCount
        var dev: GCKDevice?
        for i in 0..<count {
            let d = GCKCastContext.sharedInstance().discoveryManager.device(at: UInt(i))
            if d.deviceID == endpointId { dev = d; break }
        }
        if let dev = dev {
            GCKCastContext.sharedInstance().sessionManager.startSession(with: dev)
        } else {
            throw NSError(domain: "PPCast", code: 1, userInfo: [NSLocalizedDescriptionKey: "Device not found"])
        }
    }
    
    func disconnect(stopPlayback: Bool) {
        GCKCastContext.sharedInstance().sessionManager.endSessionAndStopCasting(stopPlayback)
    }
    
    // MARK: - Session Listener
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        emitSessionEvent(state: "connected")
        if let castSession = session as? GCKCastSession {
            castSession.remoteMediaClient?.add(self)
            emitStatusEvent()
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        emitSessionEvent(state: "connected")
        if let castSession = session as? GCKCastSession {
            castSession.remoteMediaClient?.add(self)
            emitStatusEvent()
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        emitSessionEvent(state: "disconnected")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        emitSessionEvent(state: "disconnected")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKSession, with reason: GCKConnectionSuspendReason) {
        // Ignored, we reconnect automatically or wait for didEnd
    }
    
    private func emitSessionEvent(state: String) {
        let sid = castSession?.sessionID ?? ""
        emitEvent(["event": "session_state", "state": state, "sessionId": sid])
    }
    
    // MARK: - Media Listener
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        emitStatusEvent()
    }
    
    private func emitStatusEvent() {
        guard let client = castClient else { return }
        let sid = castSession?.sessionID ?? ""
        
        let status = client.mediaStatus
        let info = status?.mediaInformation
        let customData = info?.customData as? [String: Any]
        
        let stateString: String
        switch status?.playerState {
        case .idle: stateString = "idle"
        case .playing: stateString = "playing"
        case .paused: stateString = "paused"
        case .buffering: stateString = "buffering"
        default: stateString = "idle"
        }
        
        let duration = info?.streamDuration ?? 0
        let pos = client.approximateStreamPosition()
        
        var map: [String: Any] = [
            "event": "session_status",
            "sessionId": sid,
            "itemId": customData?["ppItemId"] as? String ?? "",
            "state": stateString,
            "volume": castSession?.currentDeviceVolume ?? 1.0,
            "muted": castSession?.currentDeviceMuted ?? false,
            "positionMs": Int(pos * 1000),
            "idleReason": status?.idleReason == .finished ? "finished" : "none"
        ]
        if duration > 0 && !duration.isInfinite {
            map["durationMs"] = Int(duration * 1000)
        }
        
        emitEvent(map)
    }
    
    // MARK: - Load
    
    private var pendingLoadResult: FlutterResult?
    private var pendingLoadItemId: String?
    
    func load(item: [String: Any], sessionId: String, itemId: String, autoplay: Bool, positionMs: Double, result: @escaping FlutterResult) {
        guard let uri = item["uri"] as? String, let url = URL(string: uri) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "item required", details: nil))
            return
        }
        
        if let host = url.host?.lowercased(), host == "youtu.be" || host.hasSuffix("youtube.com") || host.hasSuffix("youtube-nocookie.com") {
            result(FlutterError(code: "UNSUPPORTED_SOURCE", message: "YouTube iframe media cannot use the generic Cast receiver.", details: nil))
            return
        }
        
        let meta = GCKMediaMetadata(metadataType: (item["isVideo"] as? Bool == true) ? .movie : .musicTrack)
        if let title = item["title"] as? String { meta.setString(title, forKey: kGCKMetadataKeyTitle) }
        if let artist = item["artist"] as? String { meta.setString(artist, forKey: kGCKMetadataKeyArtist) }
        if let album = item["album"] as? String { meta.setString(album, forKey: kGCKMetadataKeyAlbumTitle) }
        if let artwork = item["artworkUri"] as? String, let artUrl = URL(string: artwork) {
            meta.addImage(GCKImage(url: artUrl, width: 512, height: 512))
        }
        
        let live = item["isLive"] as? Bool == true
        let infoBuilder = GCKMediaInformationBuilder(contentURL: url)
        infoBuilder.contentType = item["mimeType"] as? String ?? "application/octet-stream"
        infoBuilder.streamType = live ? .live : .buffered
        infoBuilder.metadata = meta
        infoBuilder.customData = ["ppSessionId": sessionId, "ppItemId": itemId]
        
        if !live, let durMs = item["durationMs"] as? Double {
            infoBuilder.streamDuration = durMs / 1000.0
        }
        
        let options = GCKMediaLoadOptions()
        options.autoplay = autoplay
        if !live {
            options.playPosition = positionMs / 1000.0
        }
        
        guard let client = castClient else {
            result(FlutterError(code: "NO_SESSION", message: "No active session", details: nil))
            return
        }
        
        self.pendingLoadResult = result
        self.pendingLoadItemId = itemId
        
        let req = client.loadMedia(infoBuilder.build(), with: options)
        req.delegate = self
    }
    
    func requestDidComplete(_ request: GCKRequest) {
        if let pr = pendingLoadResult {
            pr(["success": true])
            pendingLoadResult = nil
        }
    }
    
    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        if let pr = pendingLoadResult {
            pr(["success": false, "error": error.localizedDescription])
            pendingLoadResult = nil
        }
    }
    
    // MARK: - Control
    func play() { castClient?.play() }
    func pause() { castClient?.pause() }
    func stop() { castClient?.stop() }
    func seek(positionMs: Double) {
        let opts = GCKMediaSeekOptions()
        opts.interval = positionMs / 1000.0
        castClient?.seek(with: opts)
    }
    func setVolume(_ vol: Float) { castSession?.setDeviceVolume(vol) }
    func setMute(_ mute: Bool) { castSession?.setDeviceMuted(mute) }
}

private var dlnaMulticastEnabled: Bool {
    guard let infoDict = Bundle.main.infoDictionary,
          let value = infoDict["PPDLNAMulticastEnabled"] else {
        return false
    }
    if let boolValue = value as? Bool {
        return boolValue
    }
    if let stringValue = value as? String {
        return stringValue.lowercased() == "yes" || stringValue.lowercased() == "true"
    }
    return false
}

// Local-library bookmark access. Each successful resolution owns one access
// reference, including simultaneous local playback and HTTP file leases.
private final class PPLocalFilesHost {
  private let channel: FlutterMethodChannel
  private var accesses: [String: [(URL, Bool)]] = [:]

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.ppplayer.app/local_files", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  deinit {
    for entries in accesses.values {
      for (url, scoped) in entries where scoped { url.stopAccessingSecurityScopedResource() }
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    do {
      switch call.method {
      case "createBookmark":
        guard let path = args["path"] as? String else { result(nil); return }
        let url = path.hasPrefix("file://") ? URL(string: path)! : URL(fileURLWithPath: path)
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        result(try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil).base64EncodedString())
      case "resolveBookmark":
        guard let bookmark = args["bookmark"] as? String, let data = Data(base64Encoded: bookmark) else { result(nil); return }
        var stale = false
        var options: URL.BookmarkResolutionOptions = [.withoutUI]
        if #available(iOS 14.2, *) { options.insert(.withoutImplicitStartAccessing) }
        let url = try URL(resolvingBookmarkData: data, options: options, relativeTo: nil, bookmarkDataIsStale: &stale)
        guard !stale else { result(FlutterError(code: "BOOKMARK_STALE", message: "Select the file again.", details: nil)); return }
        let scoped = url.startAccessingSecurityScopedResource()
        guard FileManager.default.isReadableFile(atPath: url.path) else {
          if scoped { url.stopAccessingSecurityScopedResource() }
          result(FlutterError(code: "BOOKMARK_REVOKED", message: "The file cannot be read.", details: nil))
          return
        }
        accesses[bookmark, default: []].append((url, scoped))
        result(url.path)
      case "stopBookmarkAccess":
        if let bookmark = args["bookmark"] as? String, var entries = accesses[bookmark], let entry = entries.popLast() {
          if entry.1 { entry.0.stopAccessingSecurityScopedResource() }
          if entries.isEmpty { accesses.removeValue(forKey: bookmark) } else { accesses[bookmark] = entries }
        }
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    } catch {
      result(FlutterError(code: "BOOKMARK_REVOKED", message: "The bookmark could not be resolved.", details: nil))
    }
  }
}

/// System audio routing has its own stream so a fake or native Cast client
/// cannot replace its subscription. The initial event reflects the real route.
private final class PPAirPlayRouteObserver: NSObject, FlutterStreamHandler {
  private let channel: FlutterEventChannel
  private var sink: FlutterEventSink?
  private var observer: NSObjectProtocol?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterEventChannel(name: "com.ppplayer.app/airplay_route_events", binaryMessenger: messenger)
    super.init()
    channel.setStreamHandler(self)
    observer = NotificationCenter.default.addObserver(
      forName: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance(), queue: .main
    ) { [weak self] _ in self?.emit() }
  }

  deinit {
    if let observer = observer { NotificationCenter.default.removeObserver(observer) }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    emit()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  private func emit() {
    let route = AVAudioSession.sharedInstance().currentRoute.outputs.first { $0.portType == .airPlay }
    sink?(["connected": route != nil, "name": route?.portName ?? ""])
  }
}

/// Forward system controls into the same intent handling used by Flutter UI.
/// Retain and remove only our own targets; WebKit owns its media targets too.
private final class PPIOSMediaCommands: NSObject, WKScriptMessageHandler {
  private let channel: FlutterMethodChannel
  private var targets: [(MPRemoteCommand, Any)] = []
  private var lastItemId: String?
  private var lastPlaying: Bool?
  private var artworkPath: String?
  private var artwork: MPMediaItemArtwork?

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    let center = MPRemoteCommandCenter.shared()
    bind(center.pauseCommand, method: "pause")
    bind(center.playCommand, method: "play")
    bind(center.togglePlayPauseCommand, method: "togglePlayPause")
    bind(center.nextTrackCommand, method: "next")
    bind(center.previousTrackCommand, method: "previous")
    center.changePlaybackPositionCommand.isEnabled = true
    let target = center.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let self = self, let position = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
      self.send("seek", arguments: ["positionMs": Int(position.positionTime * 1000)])
      return .success
    }
    targets.append((center.changePlaybackPositionCommand, target))
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let values = message.body as? [String: Any],
          let command = values["command"] as? String,
          ["play", "pause", "seek", "next", "previous"].contains(command) else { return }
    if command == "seek" {
      guard let position = values["positionMs"] as? NSNumber,
            position.doubleValue.isFinite, position.doubleValue >= 0 else { return }
      send(command, arguments: ["positionMs": position.intValue, "source": "webKit"])
    } else {
      send(command, arguments: ["source": "webKit"])
    }
  }

  private func bind(_ command: MPRemoteCommand, method: String) {
    command.isEnabled = true
    let target = command.addTarget { [weak self] _ in
      guard let self = self else { return .commandFailed }
      self.send(method)
      return .success
    }
    targets.append((command, target))
  }

  func updateNowPlaying(_ values: [String: Any]) {
    guard let id = values["id"] as? String, let title = values["title"] as? String else {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
      lastItemId = nil
      lastPlaying = nil
      return
    }
    let playing = values["playing"] as? Bool ?? false
    let speed = values["speed"] as? Double ?? 1
    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: values["artist"] as? String ?? "",
      MPMediaItemPropertyAlbumTitle: values["album"] as? String ?? "",
      MPNowPlayingInfoPropertyExternalContentIdentifier: id,
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: (values["positionMs"] as? Double ?? 0) / 1000,
      MPNowPlayingInfoPropertyPlaybackRate: playing ? speed : 0,
      MPNowPlayingInfoPropertyDefaultPlaybackRate: speed
    ]
    if let duration = values["durationMs"] as? Double {
      info[MPMediaItemPropertyPlaybackDuration] = duration / 1000
    }
    let path = values["artCacheFile"] as? String
    if path != artworkPath {
      artworkPath = path
      artwork = nil
      if let path = path, let image = UIImage(contentsOfFile: path) {
        artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
      }
    }
    info[MPMediaItemPropertyArtwork] = artwork
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    if id != lastItemId || playing != lastPlaying {
      NSLog("[ppplayer-audio] Now Playing published playing=%@ item=%@", playing.description, id)
    }
    lastItemId = id
    lastPlaying = playing
  }

  private func send(_ method: String, arguments: Any? = nil) {
    DispatchQueue.main.async { [weak self] in
      self?.channel.invokeMethod(method, arguments: arguments)
      NSLog("[ppplayer-audio] remote command=%@ forwarded", method)
    }
  }

  deinit {
    for (command, target) in targets { command.removeTarget(target) }
  }
}
