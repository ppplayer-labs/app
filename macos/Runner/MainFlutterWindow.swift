import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {

  override func awakeFromNib() {
    // PPPlayer publishes its own Now Playing session and remote commands.
    // Configure the Chromium host before the Flutter engine can initialize it.
    setenv("CEF_SYSTEM_MEDIA_CONTROLS", "0", 1)
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    self.delegate = self
    self.collectionBehavior.insert(.fullScreenPrimary)

    let channel = FlutterMethodChannel(name: "com.ppplayer.window", binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      if call.method == "setFullScreen" {
        if let args = call.arguments as? [String: Any], let isFullscreen = args["isFullscreen"] as? Bool {
          let currentlyFullscreen = self.styleMask.contains(.fullScreen)
          if isFullscreen != currentlyFullscreen {
            self.toggleFullScreen(nil)
          }
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing isFullscreen boolean", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  func windowDidResignKey(_ notification: Notification) {
    #if DEBUG
    NSLog("[ppplayer] windowDidResignKey (window lost focus)")
    #endif
  }

  func windowDidBecomeKey(_ notification: Notification) {
    #if DEBUG
    NSLog("[ppplayer] windowDidBecomeKey (window gained focus)")
    #endif
  }

  func windowWillClose(_ notification: Notification) {
    // If the user clicks the red X, it triggers this.
    // If they use Command+Q or QUIT, it triggers applicationShouldTerminate.
    #if DEBUG
    NSLog("[ppplayer] windowWillClose")
    #endif
  }
}
