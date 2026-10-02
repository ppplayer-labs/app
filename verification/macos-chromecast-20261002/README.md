# macOS Chromecast sender verification — October 2, 2026

Real sender implementation: native Bonjour discovery, CASTV2 TLS/protobuf, Default
Media Receiver launch, LOAD acknowledgement, playback/seek/volume/mute controls,
heartbeat and disconnect handling. Existing controller and file leases retained.

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: all 312 tests pass.
- 10 new tests cover sender messages, identities, receiver errors, socket loss,
  local file serving through the existing controller, and real loopback TLS
  framing with fragmented/coalesced protobuf messages.
- Native macOS debug build passes and the workspace app launches.
- Live Bonjour discovery currently reports zero receivers; physical Chromecast
  playback is **not verified**. Protocol tests use a receiver test double; the
  TLS test uses an actual loopback TLS server, not Chromecast hardware.

Changed sender implementation: `desktop_cast_platform_client.dart`,
`desktop_cast_transport.dart`, provider/capability wiring, Cast event mapping,
`macos/Runner/AppDelegate.swift`, `Info.plist`, and pinned pub dependencies.
Tests are `desktop_cast_platform_client_test.dart`,
`desktop_cast_transport_test.dart`, and their public localhost TLS fixtures.

Live check: receiver powered on and on the same LAN; imported local song → Play
On → Chromecast. Verify audible playback, pause/resume, seeking, volume/mute,
returning to This device, and the receiver fetching the LAN URL. Keep the Mac
running while serving local files. YouTube sources are unsupported in this flow.

Evidence here includes safe discovery logs and test output. Application logs with
HTTP request headers or account tokens are deliberately excluded.
