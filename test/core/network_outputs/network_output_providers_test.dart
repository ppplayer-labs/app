import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ppplayer/core/network_outputs/network_output_capabilities.dart';
import 'package:ppplayer/core/network_outputs/network_output_providers.dart';
import 'package:ppplayer/core/network_outputs/network_output_backend.dart';
import 'package:ppplayer/core/network_outputs/dlna/dlna_discovery.dart';
import 'package:ppplayer/core/network_outputs/dlna/dlna_output_backend.dart';
import 'package:ppplayer/core/network_outputs/cast/cast_output_backend.dart';
import 'package:ppplayer/core/network_outputs/models.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class MockPlaybackController implements PlaybackController {
  @override
  Stream<PlaybackEvent> get eventStream => const Stream.empty();
  @override
  Stream<PlaybackStatus> get statusStream => const Stream.empty();
  @override
  PlaybackStatus get currentStatus => const PlaybackStatus(
    track: null,
    state: PlaybackState.idle,
    position: Duration.zero,
    duration: Duration.zero,
    volume: 1.0,
    speed: 1.0,
    generation: 0,
    isLive: false,
    isSeekable: false,
    hasVideo: false,
  );
  @override
  dynamic get renderer => null;
  @override
  YoutubePlayerController? get youtubeController => null;
  @override
  bool get supportsSpeed => false;
  @override
  bool get supportsTrackSelection => false;
  @override
  bool get supportsExternalSubtitles => false;
  @override
  bool get supportsSubtitleDelay => false;
  @override
  bool get supportsSubtitleTextSize => false;
  @override
  bool get supportsSubtitleBackgroundStyling => false;
  @override
  bool get supportsVideoFitMode => false;

  @override
  Future<void> dispose() async {}
  @override
  Future<void> pause({
    String caller = 'user',
    bool failOnTimeout = false,
  }) async {}
  @override
  Future<void> play(
    PlaybackTrack track, {
    Duration startAt = Duration.zero,
    bool play = true,
  }) async {}
  @override
  Future<void> prepare(PlaybackTrack track, {Duration? position}) async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> seekTo(Duration position) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setSubtitleAppearance({
    double? textSize,
    int? backgroundColor,
  }) async {}
  @override
  Future<void> setSubtitleDelay(Duration delay) async {}
  @override
  Future<void> setSubtitleTrack(String? uri) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> stop() async {}
}

class MockBackend implements NetworkOutputBackend {
  final OutputKind _kind;
  MockBackend(this._kind);

  @override
  OutputKind get kind => _kind;
  @override
  Stream<List<PlaybackOutput>> get outputs => const Stream.empty();
  @override
  Stream<NetworkOutputSessionState> get sessionState => const Stream.empty();
  @override
  Future<void> connect(
    PlaybackOutput output, {
    required String sessionId,
  }) async {}
  @override
  Future<void> disconnect({
    required String sessionId,
    required bool stopPlayback,
  }) async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<RemoteLoadResult> load(
    NetworkMediaItem item, {
    required String sessionId,
    required String itemId,
    Duration position = Duration.zero,
    bool autoplay = true,
  }) async => const RemoteLoadResult(success: false, error: 'mock');
  @override
  Future<void> pause({
    required String sessionId,
    required String itemId,
  }) async {}
  @override
  Future<void> play({
    required String sessionId,
    required String itemId,
  }) async {}
  @override
  Future<void> seek(
    Duration position, {
    required String sessionId,
    required String itemId,
  }) async {}
  @override
  Future<void> setMute(
    bool muted, {
    required String sessionId,
    required String itemId,
  }) async {}
  @override
  Future<void> setVolume(
    double volume, {
    required String sessionId,
    required String itemId,
  }) async {}
  @override
  Future<void> startDiscovery() async {}
  @override
  Future<void> stop({
    required String sessionId,
    required String itemId,
  }) async {}
  @override
  Future<void> stopDiscovery() async {}
}

class MockDlnaBackend extends MockBackend implements DlnaOutputBackend {
  MockDlnaBackend() : super(OutputKind.dlna);

  @override
  DlnaDiscovery get discovery => throw UnimplementedError();
}

class MockCastBackend extends MockBackend implements CastOutputBackend {
  MockCastBackend() : super(OutputKind.googleCast);
}

void main() {
  ProviderContainer makeContainer({
    required NetworkOutputsCapabilities capabilities,
  }) {
    final container = ProviderContainer(
      overrides: [
        networkOutputCapabilitiesProvider.overrideWith((ref) => capabilities),
        localPlaybackControllerProvider.overrideWith(
          (ref) => MockPlaybackController(),
        ),
        dlnaOutputBackendProvider.overrideWith((ref) => MockDlnaBackend()),
        castOutputBackendProvider.overrideWith((ref) => MockCastBackend()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('iOS + DLNA disabled: DlnaOutputBackend not registered', () async {
    final container = makeContainer(
      capabilities: const NetworkOutputsCapabilities(
        dlnaAvailable: false,
        googleCastAvailable: true,
      ),
    );

    // Wait for the async capabilities to be processed
    await container.read(networkOutputCapabilitiesProvider.future);
    final controller = container.read(networkOutputControllerProvider);

    expect(controller.backends.any((b) => b.kind == OutputKind.dlna), isFalse);
    expect(
      controller.backends.any((b) => b.kind == OutputKind.googleCast),
      isTrue,
    );
  });

  test('iOS + DLNA enabled: DlnaOutputBackend registered', () async {
    final container = makeContainer(
      capabilities: const NetworkOutputsCapabilities(
        dlnaAvailable: true,
        googleCastAvailable: true,
      ),
    );

    await container.read(networkOutputCapabilitiesProvider.future);
    final controller = container.read(networkOutputControllerProvider);

    expect(controller.backends.any((b) => b.kind == OutputKind.dlna), isTrue);
    expect(
      controller.backends.any((b) => b.kind == OutputKind.googleCast),
      isTrue,
    );
  });

  test('Android: DLNA preserved, Cast preserved', () async {
    final container = makeContainer(
      capabilities: const NetworkOutputsCapabilities(
        dlnaAvailable: true,
        googleCastAvailable: true,
      ),
    );

    await container.read(networkOutputCapabilitiesProvider.future);
    final controller = container.read(networkOutputControllerProvider);

    expect(controller.backends.any((b) => b.kind == OutputKind.dlna), isTrue);
    expect(
      controller.backends.any((b) => b.kind == OutputKind.googleCast),
      isTrue,
    );
  });

  test('macOS: DLNA preserved, Cast disabled', () async {
    final container = makeContainer(
      capabilities: const NetworkOutputsCapabilities(
        dlnaAvailable: true,
        googleCastAvailable: false,
      ),
    );

    await container.read(networkOutputCapabilitiesProvider.future);
    final controller = container.read(networkOutputControllerProvider);

    expect(controller.backends.any((b) => b.kind == OutputKind.dlna), isTrue);
    expect(
      controller.backends.any((b) => b.kind == OutputKind.googleCast),
      isFalse,
    );
  });
}
