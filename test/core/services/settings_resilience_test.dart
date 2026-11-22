import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/core/theme/app_theme.dart';

class _ControlledSettingsNotifier extends SettingsNotifier {
  _ControlledSettingsNotifier({required this.openBoxHandler});

  final Future<Box<dynamic>> Function() openBoxHandler;

  @override
  Future<Box<dynamic>> openSettingsBox() => openBoxHandler();
}

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('ppplayer_settings_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test(
    'SettingsNotifier recovers safely from corrupted Hive types and preserves valid unrelated settings',
    () async {
      final box = await Hive.openBox('settings');
      await box.put('selected_country', 'BR');
      await box.put('user_name', 'Release Tester');
      await box.put('autoplay_enabled', false);
      await box.put('show_video', 'yes');
      await box.put('theme_index', 999);
      await box.put('subtitle_text_size', 'huge');
      await box.put('subtitle_bg_color', 'transparent');
      await box.put('player_view', 'invalid');
      await box.close();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider);
      await container.read(settingsProvider.notifier).loadSettled;

      final state = container.read(settingsProvider);
      expect(state.isLoaded, isTrue);
      expect(state.selectedCountry, 'BR');
      expect(state.userName, 'Release Tester');
      expect(state.autoplayEnabled, isFalse);
      expect(state.showVideo, isTrue);
      expect(state.playerView, PlayerView.video);
      expect(state.themeIndex, AppTheme.themeColors.length - 1);
      expect(state.subtitleTextSize, 24.0);
      expect(state.subtitleBackgroundColor, 0x80000000);
    },
  );

  test(
    'SettingsNotifier recovers safely when selected_country is corrupted and clamps negative themeIndex',
    () async {
      final box = await Hive.openBox('settings');
      await box.put('selected_country', 12345);
      await box.put('theme_index', -42);
      await box.close();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider);
      await container.read(settingsProvider.notifier).loadSettled;

      final state = container.read(settingsProvider);
      expect(state.isLoaded, isTrue);
      expect(state.selectedCountry, 'US');
      expect(state.themeIndex, 0);
    },
  );

  test(
    'disposing ProviderContainer before _loadSettings completes does not throw',
    () async {
      final container = ProviderContainer();
      container.read(settingsProvider);
      final loadFuture = container.read(settingsProvider.notifier).loadSettled;
      container.dispose();
      await loadFuture;
    },
  );

  test(
    'rapid concurrent toggleVideo calls update state deterministically without stale reversions',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider);
      final notifier = container.read(settingsProvider.notifier);
      await notifier.loadSettled;
      expect(container.read(settingsProvider).showVideo, isTrue);
      expect(container.read(settingsProvider).playerView, PlayerView.video);

      // Fire 11 rapid toggles without awaiting between calls (odd -> hidden).
      final oddBatch = <Future<void>>[];
      for (var i = 0; i < 11; i++) {
        oddBatch.add(notifier.toggleVideo());
        final expectedShow = i.isOdd;
        expect(container.read(settingsProvider).showVideo, expectedShow);
        expect(
          container.read(settingsProvider).playerView,
          expectedShow ? PlayerView.video : PlayerView.artwork,
        );
      }
      await Future.wait(oddBatch);

      expect(container.read(settingsProvider).showVideo, isFalse);
      expect(container.read(settingsProvider).playerView, PlayerView.artwork);

      // Fire 11 more rapid toggles (-> visible).
      final evenBatch = <Future<void>>[];
      for (var i = 0; i < 11; i++) {
        evenBatch.add(notifier.toggleVideo());
      }
      await Future.wait(evenBatch);

      expect(container.read(settingsProvider).showVideo, isTrue);
      expect(container.read(settingsProvider).playerView, PlayerView.video);

      final box = await Hive.openBox('settings');
      expect(box.get('show_video'), isTrue);
      expect(box.get('player_view'), PlayerView.video.index);
    },
  );

  test(
    'rapid toggles followed by normal shutdown and immediate restart restore last persisted state and preserve other preferences',
    () async {
      final container1 = ProviderContainer();
      container1.read(settingsProvider);
      final notifier1 = container1.read(settingsProvider.notifier);
      await notifier1.loadSettled;

      await notifier1.setCountry('JP');
      await notifier1.setTheme(2);
      await notifier1.setUserName('Audio Enthusiast');

      // 25 rapid toggles -> odd -> showVideo == false, playerView == artwork.
      for (var i = 0; i < 25; i++) {
        unawaited(notifier1.toggleVideo());
      }
      await notifier1.persistSettled;
      container1.dispose();

      // Simulate full app shutdown (close Hive box) and fresh restart.
      await Hive.close();
      Hive.init(hiveDir.path);

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      container2.read(settingsProvider);
      await container2.read(settingsProvider.notifier).loadSettled;

      final restored = container2.read(settingsProvider);
      expect(restored.isLoaded, isTrue);
      expect(restored.showVideo, isFalse);
      expect(restored.playerView, PlayerView.artwork);
      expect(restored.selectedCountry, 'JP');
      expect(restored.themeIndex, 2);
      expect(restored.userName, 'Audio Enthusiast');

      // Immediate second restart without closing Hive box (e.g. hot restart / scope rebuild).
      final container3 = ProviderContainer();
      addTearDown(container3.dispose);
      container3.read(settingsProvider);
      await container3.read(settingsProvider.notifier).loadSettled;
      expect(container3.read(settingsProvider).showVideo, isFalse);
      expect(container3.read(settingsProvider).playerView, PlayerView.artwork);
    },
  );

  test(
    'provider disposal mid-persist flushes already-enqueued toggle cleanly and ignores post-dispose calls',
    () async {
      final gate = Completer<void>();
      var openCalls = 0;

      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            () => _ControlledSettingsNotifier(
              openBoxHandler: () async {
                openCalls++;
                // Allow initial _loadSettings (call 1), pause first _persist (call 2).
                if (openCalls >= 2) {
                  await gate.future;
                }
                return Hive.openBox('settings');
              },
            ),
          ),
        ],
      );

      container.read(settingsProvider);
      final notifier = container.read(settingsProvider.notifier);
      await notifier.loadSettled;

      // Enqueue rapid toggles (3 -> hidden) while Hive open is gated.
      final p1 = notifier.toggleVideo(); // false
      final p2 = notifier.toggleVideo(); // true
      final p3 = notifier.toggleVideo(); // false
      expect(container.read(settingsProvider).showVideo, isFalse);

      // Dispose provider immediately before gated writes complete.
      container.dispose();

      // Post-dispose calls must be safe no-ops and never throw.
      await notifier.toggleVideo();
      await notifier.setPlayerView(PlayerView.video);

      // Release gated Hive open: queued writes flush cleanly without StateError.
      gate.complete();
      await Future.wait([p1, p2, p3, notifier.persistSettled]);
      expect(notifier.lastPersistError, isNull);

      final box = await Hive.openBox('settings');
      expect(box.get('show_video'), isFalse);
      expect(box.get('player_view'), PlayerView.artwork.index);
    },
  );

  test(
    'toggles fired before initial _loadSettings finishes are never clobbered by stale disk values',
    () async {
      final seedBox = await Hive.openBox('settings');
      await seedBox.put('show_video', true);
      await seedBox.put('player_view', PlayerView.video.index);
      await seedBox.put('selected_country', 'DE');
      await seedBox.close();

      final loadGate = Completer<void>();
      var openCount = 0;
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            () => _ControlledSettingsNotifier(
              openBoxHandler: () async {
                openCount++;
                if (openCount == 1) {
                  await loadGate.future;
                }
                return Hive.openBox('settings');
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(settingsProvider);
      final notifier = container.read(settingsProvider.notifier);

      // User toggles hidden before initial load completes.
      final toggleFuture = notifier.toggleVideo();
      expect(container.read(settingsProvider).showVideo, isFalse);
      expect(container.read(settingsProvider).playerView, PlayerView.artwork);

      // Now let _loadSettings finish with stale show_video=true on disk.
      loadGate.complete();
      await Future.wait([notifier.loadSettled, toggleFuture]);

      final finalState = container.read(settingsProvider);
      expect(finalState.isLoaded, isTrue);
      expect(finalState.selectedCountry, 'DE');
      expect(finalState.showVideo, isFalse);
      expect(finalState.playerView, PlayerView.artwork);
    },
  );

  test(
    'rapid interleaved toggleVideo and setPlayerView (including queue) keep final state and Hive consistent',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider);
      final notifier = container.read(settingsProvider.notifier);
      await notifier.loadSettled;

      final futures = <Future<void>>[
        notifier.toggleVideo(), // false / artwork
        notifier.setPlayerView(PlayerView.queue), // false / queue
        notifier.setPlayerView(PlayerView.video), // true / video
        notifier.setPlayerView(PlayerView.queue), // true / queue
        notifier.toggleVideo(), // false / queue (stays in queue!)
        notifier.setPlayerView(PlayerView.artwork), // false / artwork
        notifier.toggleVideo(), // true / video
      ];
      await Future.wait(futures);

      expect(container.read(settingsProvider).showVideo, isTrue);
      expect(container.read(settingsProvider).playerView, PlayerView.video);

      final box = await Hive.openBox('settings');
      expect(box.get('show_video'), isTrue);
      expect(box.get('player_view'), PlayerView.video.index);
    },
  );

  test(
    'simulated Hive persistence failure records error without unhandled exception and recovers on next write',
    () async {
      var failWrites = true;
      var openedOnce = false;

      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            () => _ControlledSettingsNotifier(
              openBoxHandler: () async {
                if (!openedOnce) {
                  openedOnce = true;
                  return Hive.openBox('settings');
                }
                if (failWrites) {
                  throw FileSystemException('Simulated disk full');
                }
                return Hive.openBox('settings');
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(settingsProvider);
      final notifier = container.read(settingsProvider.notifier);
      await notifier.loadSettled;

      // Toggle while persistence fails -> must NOT throw unhandled error,
      // must keep in-memory state consistent, and must surface error via lastPersistError.
      await notifier.toggleVideo();
      expect(container.read(settingsProvider).showVideo, isFalse);
      expect(container.read(settingsProvider).playerView, PlayerView.artwork);
      expect(notifier.lastPersistError, isA<FileSystemException>());

      // Once storage recovers, subsequent toggle persists cleanly and clears lastPersistError.
      failWrites = false;
      await notifier.toggleVideo();
      await notifier.persistSettled;

      expect(container.read(settingsProvider).showVideo, isTrue);
      expect(container.read(settingsProvider).playerView, PlayerView.video);
      expect(notifier.lastPersistError, isNull);

      final box = await Hive.openBox('settings');
      expect(box.get('show_video'), isTrue);
      expect(box.get('player_view'), PlayerView.video.index);
    },
  );
}
