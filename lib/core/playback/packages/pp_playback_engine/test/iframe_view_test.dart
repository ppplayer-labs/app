import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pp_playback_engine/pp_playback_engine.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'fake_youtube_controller.dart';

class MockPlaybackController extends Mock implements PlaybackController {}

class _ViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _ViewWidget(params);
}

class _ViewWidget extends PlatformWebViewWidget {
  _ViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: ValueKey('test_webview_surface'));
}

class _ViewController extends PlatformWebViewController {
  _ViewController()
    : super.implementation(const PlatformWebViewControllerCreationParams());

  @override
  Future<void> setBackgroundColor(Color color) async {}
}

class _YoutubeViewController extends FakeYoutubeController {
  @override
  final webViewController = WebViewController.fromPlatform(_ViewController());

  @override
  Future<void> init() async {}
}

void main() {
  late MockPlaybackController mockController;
  WebViewPlatform? originalPlatform;

  setUp(() {
    mockController = MockPlaybackController();
    originalPlatform = WebViewPlatform.instance;
    WebViewPlatform.instance = _ViewPlatform();
  });
  tearDown(() {
    // The platform setter rejects null. When no plugin was registered, the
    // fake remains confined to this test file's isolate.
    if (originalPlatform != null) {
      WebViewPlatform.instance = originalPlatform;
    }
  });

  testWidgets('PlaybackView renders YoutubePlayer when in IFrame mode', (
    WidgetTester tester,
  ) async {
    // 1. Setup mock state
    const status = PlaybackStatus(
      track: PlaybackTrack(id: 'test_id', title: 'Test Track'),
      state: PlaybackState.playing,
      isIFrameMode: true,
    );

    final ytController = _YoutubeViewController();
    addTearDown(ytController.close);

    when(() => mockController.currentStatus).thenReturn(status);
    when(
      () => mockController.statusStream,
    ).thenAnswer((_) => Stream.value(status));


    // 2. Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackView(controller: mockController, status: status),
        ),
      ),
    );

    // 3. Verify YoutubePlayer is present
    expect(find.byType(yt.YoutubePlayer), findsOneWidget);
    expect(find.byKey(const ValueKey('test_webview_surface')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PlaybackView logic branch verification', (
    WidgetTester tester,
  ) async {
    // This test specifically verifies that the build method switches correctly
    // without actually rendering the heavy media_kit widget which fails in tests.

    const statusIFrame = PlaybackStatus(isIFrameMode: true);

    when(() => mockController.currentStatus).thenReturn(statusIFrame);
    when(
      () => mockController.statusStream,
    ).thenAnswer((_) => Stream.value(statusIFrame));
    // Verify IFrame branch doesn't throw even with null renderer (it should handle it in build)
    await tester.pumpWidget(
      MaterialApp(
        home: PlaybackView(controller: mockController, status: statusIFrame),
      ),
    );

    // We expect it to NOT find YoutubePlayer if controller is null, which is correct handling
    expect(find.byType(yt.YoutubePlayer), findsNothing);
  });
}
