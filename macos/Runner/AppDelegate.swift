import Cocoa
import FlutterMacOS
import WebKit

@main
class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var networkOutputsHost: PPNetworkOutputsHost?
  private var localFilesHost: PPLocalFilesHost?
  
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
      case "getPlatformCapabilities":
        result(["googleCastAvailable": false, "googleCastUnavailableReason": "Google Cast has no supported native desktop sender integration.", "airPlayPickerAvailable": false, "airPlayVerified": false, "airPlayUnavailableReason": "The current macOS playback engines do not expose a routable AVPlayer.", "dlnaDiscoveryAvailable": true, "dlnaUnavailableReason": ""])
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
