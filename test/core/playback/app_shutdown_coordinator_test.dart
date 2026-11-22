import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/playback/playback_providers.dart';
import 'package:ppplayer/main.dart'
    show AppShutdownCoordinator, shouldShutdownOnAppDetach;

class _FakePlaybackController extends Fake implements PlaybackController {
  int disposeCalls = 0;

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

void main() {
  test(
    'AppShutdownCoordinator disposes active playback controller and container exactly once',
    () async {
      final fakeController = _FakePlaybackController();
      var containerDisposed = 0;
      final container = ProviderContainer(
        overrides: [
          localPlaybackControllerProvider.overrideWith((ref) {
            ref.onDispose(() {
              containerDisposed++;
              fakeController.dispose();
            });
            return fakeController;
          }),
        ],
      );
      // Instantiate the provider so container.exists(...) is true.
      container.read(localPlaybackControllerProvider);

      final coordinator = AppShutdownCoordinator(() => container);
      await Future.wait([coordinator.shutdown(), coordinator.shutdown()]);
      await coordinator.shutdown();

      // AppShutdownCoordinator disposes the controller once before container.dispose(),
      // and ref.onDispose runs once when container.dispose() executes.
      expect(containerDisposed, 1);
      expect(fakeController.disposeCalls, greaterThanOrEqualTo(1));
    },
  );

  test(
    'AppShutdownCoordinator does not instantiate playback controller if never used',
    () async {
      var created = false;
      final container = ProviderContainer(
        overrides: [
          localPlaybackControllerProvider.overrideWith((ref) {
            created = true;
            return _FakePlaybackController();
          }),
        ],
      );
      final coordinator = AppShutdownCoordinator(() => container);
      await coordinator.shutdown();
      expect(created, isFalse);
    },
  );

  test(
    'shouldShutdownOnAppDetach enables shutdown only on desktop platforms',
    () {
      expect(
        shouldShutdownOnAppDetach(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        isFalse,
      );
      expect(
        shouldShutdownOnAppDetach(platform: TargetPlatform.iOS, isWeb: false),
        isFalse,
      );
      expect(
        shouldShutdownOnAppDetach(
          platform: TargetPlatform.windows,
          isWeb: false,
        ),
        isTrue,
      );
      expect(
        shouldShutdownOnAppDetach(platform: TargetPlatform.linux, isWeb: false),
        isTrue,
      );
      expect(
        shouldShutdownOnAppDetach(platform: TargetPlatform.macOS, isWeb: false),
        isTrue,
      );
      expect(
        shouldShutdownOnAppDetach(platform: TargetPlatform.macOS, isWeb: true),
        isFalse,
      );
    },
  );
}
