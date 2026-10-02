import Cocoa
import FlutterMacOS
import WebKit
import CoreAudio

// Use the system Bonjour browser in the sandbox instead of raw multicast UDP.
private final class PPMacOSCastDiscovery: NSObject, FlutterStreamHandler, NetServiceBrowserDelegate, NetServiceDelegate {
  private let methods: FlutterMethodChannel
  private let events: FlutterEventChannel
  private let browser = NetServiceBrowser()
  private var sink: FlutterEventSink?
  private var browsing = false
  private var services: [String: NetService] = [:]
  private var devices: [String: [String: Any]] = [:]

  init(messenger: FlutterBinaryMessenger) {
    methods = FlutterMethodChannel(name: "com.ppplayer.app/cast_discovery", binaryMessenger: messenger)
    events = FlutterEventChannel(name: "com.ppplayer.app/cast_discovery_events", binaryMessenger: messenger)
    super.init()
    browser.delegate = self
    events.setStreamHandler(self)
    methods.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "startDiscovery":
        if !self.browsing {
          self.browsing = true
          self.devices.removeAll()
          self.browser.searchForServices(ofType: "_googlecast._tcp.", inDomain: "local.")
        }
        self.publish()
        result(nil)
      case "stopDiscovery": self.stop(); result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
  }
  private func key(_ service: NetService) -> String { "\(service.name)|\(service.type)|\(service.domain)" }
  private func publish() { sink?(["devices": Array(devices.values)]) }
  private func stop() {
    browsing = false
    browser.stop()
    services.values.forEach { $0.stop(); $0.delegate = nil }
    services.removeAll()
    devices.removeAll()
  }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events; publish(); return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil; stop(); return nil
  }
  func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
    guard browsing else { return }
    services[key(service)] = service
    service.delegate = self
    service.resolve(withTimeout: 8)
  }
  func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    let id = key(service)
    services.removeValue(forKey: id)?.stop()
    devices.removeValue(forKey: id)
    publish()
  }
  func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
    stop()
    sink?(["error": "Chromecast discovery failed. Check local network access in System Settings."])
  }
  func netServiceDidResolveAddress(_ sender: NetService) {
    guard browsing, services[key(sender)] === sender,
          let host = sender.hostName, sender.port > 0 else { return }
    let txt = sender.txtRecordData().map(NetService.dictionary(fromTXTRecord:)) ?? [:]
    func text(_ name: String) -> String? { txt[name].flatMap { String(data: $0, encoding: .utf8) } }
    let capabilities = Int(text("ca") ?? "") ?? 5
    devices[key(sender)] = [
      "id": text("id") ?? key(sender), "name": text("fn") ?? sender.name,
      "model": text("md") ?? "Chromecast", "host": host, "port": sender.port,
      "audio": capabilities & 4 != 0, "video": capabilities & 1 != 0,
    ]
    NSLog("[DesktopCast] Bonjour resolved device=%@ port=%ld", text("fn") ?? sender.name, sender.port)
    publish()
  }
  func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
    devices.removeValue(forKey: key(sender)); publish()
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var networkOutputsHost: PPNetworkOutputsHost?
  private var localFilesHost: PPLocalFilesHost?
  private var audioRoutes: PPMacOSAudioRoutes?
  private var castDiscovery: PPMacOSCastDiscovery?
  
  private var isPlaying = false
  private var isShuffle = false
  private var repeatMode = "none"
  private var activityToken: NSObjectProtocol?


  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Prevent App Nap so the next song can start automatically when minimized
    activityToken = ProcessInfo.processInfo.beginActivity(
      options: .userInitiatedAllowingIdleSystemSleep,
      reason: "Continuous background audio playback"
    )

    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      networkOutputsHost = PPNetworkOutputsHost(messenger: controller.engine.binaryMessenger)
      localFilesHost = PPLocalFilesHost(messenger: controller.engine.binaryMessenger)
      audioRoutes = PPMacOSAudioRoutes(messenger: controller.engine.binaryMessenger)
      castDiscovery = PPMacOSCastDiscovery(messenger: controller.engine.binaryMessenger)
      methodChannel = FlutterMethodChannel(name: "com.ppplayer/dock_menu", binaryMessenger: controller.engine.binaryMessenger)
      
      methodChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "updateState" {
          if let args = call.arguments as? [String: Any] {
            if let playing = args["isPlaying"] as? Bool { self?.isPlaying = playing }
            if let shuffle = args["isShuffle"] as? Bool { self?.isShuffle = shuffle }
            if let repMode = args["repeatMode"] as? String { self?.repeatMode = repMode }
          }
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    let menu = NSMenu(title: "Dock Menu")

    let playPauseItem = NSMenuItem(title: isPlaying ? "Pause" : "Play", action: #selector(playPauseClicked), keyEquivalent: "")
    menu.addItem(playPauseItem)

    menu.addItem(NSMenuItem(title: "Next", action: #selector(nextClicked), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Previous", action: #selector(previousClicked), keyEquivalent: ""))
    
    menu.addItem(NSMenuItem.separator())
    
    let shuffleTitle = isShuffle ? "Shuffle (On)" : "Shuffle"
    menu.addItem(NSMenuItem(title: shuffleTitle, action: #selector(shuffleClicked), keyEquivalent: ""))
    
    let repeatTitle: String
    switch repeatMode {
    case "one": repeatTitle = "Repeat (One)"
    case "all": repeatTitle = "Repeat (All)"
    default: repeatTitle = "Repeat"
    }
    menu.addItem(NSMenuItem(title: repeatTitle, action: #selector(repeatClicked), keyEquivalent: ""))

    return menu
  }

  @objc func playPauseClicked() { methodChannel?.invokeMethod("playPause", arguments: nil) }
  @objc func nextClicked() { methodChannel?.invokeMethod("next", arguments: nil) }
  @objc func previousClicked() { methodChannel?.invokeMethod("previous", arguments: nil) }
  @objc func shuffleClicked() { methodChannel?.invokeMethod("toggleShuffle", arguments: nil) }
  @objc func repeatClicked() { methodChannel?.invokeMethod("toggleRepeat", arguments: nil) }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // When we minimize the window, we call orderOut(nil) to hide it.
    // If this returns true, the app will terminate when the window is hidden.
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// When the user clicks the app Dock icon and the window is hidden
  /// (because we intercept minimize → hide), re-show the window.
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      sender.windows.first?.makeKeyAndOrderFront(nil)
    }
    return true
  }
}

/// Observe the system output followed by the existing macOS playback engines.
/// No AVPlayer or remote protocol session is created for system audio routing.
private final class PPMacOSAudioRoutes: NSObject, FlutterStreamHandler {
  private let channel: FlutterEventChannel
  private var sink: FlutterEventSink?
  private var systemListeners: [(AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
  private var deviceListeners: [(AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)] = []
  private var observedDevice: AudioObjectID = 0

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterEventChannel(name: "com.ppplayer.app/system_audio_route_events", binaryMessenger: messenger)
    super.init()
    channel.setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    remove(&systemListeners)
    remove(&deviceListeners)
    observedDevice = 0
    sink = events
    for selector in [kAudioHardwarePropertyDefaultOutputDevice, kAudioHardwarePropertyDevices] {
      if let listener = listen(AudioObjectID(kAudioObjectSystemObject), selector) { systemListeners.append(listener) }
    }
    refresh()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    remove(&systemListeners)
    remove(&deviceListeners)
    observedDevice = 0
    return nil
  }

  private func listen(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> (AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)? {
    var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.refresh() }
    guard AudioObjectAddPropertyListenerBlock(object, &address, .main, block) == noErr else { return nil }
    return (object, address, block)
  }

  private func remove(_ listeners: inout [(AudioObjectID, AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)]) {
    for (object, property, block) in listeners {
      var address = property
      AudioObjectRemovePropertyListenerBlock(object, &address, .main, block)
    }
    listeners.removeAll()
  }

  private func readUInt(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> UInt32? {
    var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    guard AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value) == noErr else { return nil }
    return value
  }

  private func refresh() {
    guard let sink = sink else { return }
    let device = readUInt(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice) ?? 0
    if device != observedDevice {
      remove(&deviceListeners)
      observedDevice = device
      if device != 0 {
        for selector in [kAudioObjectPropertyName, kAudioDevicePropertyTransportType] {
          if let listener = listen(device, selector) { deviceListeners.append(listener) }
        }
      }
    }
    var address = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var name: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    let hasName = device != 0 && AudioObjectGetPropertyData(device, &address, 0, nil, &size, &name) == noErr
    let label = hasName ? name?.takeRetainedValue() as String? ?? "Audio output" : "Audio output"
    let transport = readUInt(device, kAudioDevicePropertyTransportType)
    let values: [String: Any] = [
      "available": device != 0 && hasName && transport != nil,
      "name": label,
      "builtIn": transport == kAudioDeviceTransportTypeBuiltIn,
      "airPlay": transport == kAudioDeviceTransportTypeAirPlay
    ]
    NSLog("[ppplayer-audio] macOS system output=%@ transport=%u", label, transport ?? 0)
    sink(values)
  }

  deinit {
    remove(&systemListeners)
    remove(&deviceListeners)
  }
}

private final class PPNetworkOutputsHost {
  private var leases: [String: (URL, Bool)] = [:]
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.ppplayer.app/network_outputs", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }
  deinit {
    for (_, lease) in leases where lease.1 { lease.0.stopAccessingSecurityScopedResource() }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    do {
      switch call.method {
      case "openSystemSoundSettings":
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound")!
        guard NSWorkspace.shared.open(url) else {
          result(FlutterError(code: "SOUND_SETTINGS_UNAVAILABLE", message: "Could not open Sound settings", details: nil))
          return
        }
        result(nil)
      case "getPlatformCapabilities":
        result(["googleCastAvailable": true, "googleCastUnavailableReason": "", "airPlayPickerAvailable": false, "airPlayVerified": false, "airPlayUnavailableReason": "The current macOS playback engines do not expose a routable AVPlayer.", "dlnaDiscoveryAvailable": true, "dlnaUnavailableReason": ""])
      case "getWebKitAirPlayConfiguration":
        var values: [Bool] = []
        func visit(_ view: NSView) {
          if let webView = view as? WKWebView { values.append(webView.configuration.allowsAirPlayForMediaPlayback) }
          view.subviews.forEach(visit)
        }
        NSApplication.shared.windows.compactMap { $0.contentView }.forEach(visit)
        result(["webViewCount": values.count, "allowsAirPlay": values])
      case "acquireFileLease":
        guard leases.count < 8 else { throw NSError(domain: "PPNetworkOutputs", code: 1, userInfo: [NSLocalizedDescriptionKey: "Too many active file leases."]) }
        let url: URL
        if let bookmark = args["bookmark"] as? String, let data = Data(base64Encoded: bookmark) {
          var stale = false
          var options: URL.BookmarkResolutionOptions = [.withSecurityScope, .withoutUI]
          if #available(macOS 11.2, *) { options.insert(.withoutImplicitStartAccessing) }
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
      default: result(FlutterError(code: "OUTPUT_UNAVAILABLE", message: "This network output is unavailable on macOS.", details: nil))
      }
    } catch {
      result(FlutterError(code: "FILE_ACCESS", message: error.localizedDescription, details: nil))
    }
  }
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
        result(try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil).base64EncodedString())
      case "resolveBookmark":
        guard let bookmark = args["bookmark"] as? String, let data = Data(base64Encoded: bookmark) else { result(nil); return }
        var stale = false
        var options: URL.BookmarkResolutionOptions = [.withSecurityScope, .withoutUI]
        if #available(macOS 11.2, *) { options.insert(.withoutImplicitStartAccessing) }
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
