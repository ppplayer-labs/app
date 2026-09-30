import Flutter
import UIKit
import AVFoundation
import WebKit
import MediaPlayer

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
        navigator.mediaSession.metadata = null;
        navigator.mediaSession.setActionHandler('play', null);
        navigator.mediaSession.setActionHandler('pause', null);
        navigator.mediaSession.setActionHandler('seekto', null);
        navigator.mediaSession.setActionHandler('previoustrack', null);
        navigator.mediaSession.setActionHandler('nexttrack', null);
      }

      // Swallow visibilitychange at the capture phase on both window and document
      // so YouTube's iframe listener never sees document.hidden === true.
      const stop = (e) => { e.stopImmediatePropagation(); };
      window.addEventListener('visibilitychange', stop, true);
      window.addEventListener('webkitvisibilitychange', stop, true);
      window.addEventListener('pagehide', stop, true);
      window.addEventListener('blur', stop, true);
      document.addEventListener('visibilitychange', stop, true);
      document.addEventListener('webkitvisibilitychange', stop, true);

      // Immediately reassert 'visible' so any already-registered listeners
      // that fire synchronously on foreground return see the patched value.
      document.dispatchEvent(new Event('visibilitychange'));
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

    // Re-apply the visibility patch in two critical windows:
    //
    // 1. willResignActive (going to background) — fires BEFORE iOS dispatches
    //    the real visibilitychange to WKWebView. This prevents YouTube's iframe
    //    listener from seeing document.hidden === true and pausing.
    //
    // 2. willEnterForeground (coming back) — fires BEFORE the WKWebView
    //    processes any pending visibility events that queued while backgrounded.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillEnterForeground),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil
    )

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    startupLog("super.application complete")
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    startupLog("didInitializeImplicitFlutterEngine — registering plugins")
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    startupLog("plugins registered")

    // Expose an activation method so Dart can trigger setActive(true) right
    // before starting playback rather than at app launch.
    // applicationRegistrar conforms to FlutterBaseRegistrar which exposes messenger().
    let channel = FlutterMethodChannel(
      name: "com.ppplayer.app/ios_media_controls",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "activateAudioSession":
        self?.activateAudioSession()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // ---------------------------------------------------------------------------
  // AVAudioSession helpers
  // ---------------------------------------------------------------------------

  /// Called when app returns to foreground — re-injects the visibility patch
  /// immediately so it's in place before the WKWebView fires visibilitychange.
  @objc private func appWillEnterForeground() {
    NSLog("[ppplayer] appWillEnterForeground — re-injecting visibility patch")
    for webView in patchedWebViews.allObjects {
      // Reset the guard flag so the IIFE re-runs on next evaluation.
      webView.evaluateJavaScript(
        "window.__ppplayerVisibilityPatched = false;",
        completionHandler: nil
      )
      webView.evaluateJavaScript(visibilityPatchScript, completionHandler: nil)
    }
  }

  /// Activates the audio session right before playback starts.
  /// Called from Dart via the ios_media_controls method channel.
  @objc func activateAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setActive(true)
      NSLog("[ppplayer] AVAudioSession activated for playback.")
    } catch {
      NSLog("[ppplayer] AVAudioSession activation failed: %@", error.localizedDescription)
    }
  }

  /// Handles system audio interruptions (phone call, Siri, other apps).
  @objc private func handleAudioInterruption(_ notification: Notification) {
    guard let info = notification.userInfo,
          let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

    if type == .ended {
      // Re-activate after interruption ends so playback can resume.
      let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
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

      if !hasInjected {
        webView.configuration.userContentController.addUserScript(script)
        webView.evaluateJavaScript(self.visibilityPatchScript, completionHandler: nil)
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
