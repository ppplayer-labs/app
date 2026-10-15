import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:ppplayer/features/player/queue_presentation.dart';

void main() {
  group('QueuePanelWidthNotifier', () {
    test('initializes with default width of 360px', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final width = container.read(queuePanelWidthProvider);
      expect(width, equals(kDefaultQueuePanelWidth));
      expect(width, equals(360.0));
    });

    test('setWidth clamps within allowed min and max bounds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(queuePanelWidthProvider.notifier);

      notifier.setWidth(450.0);
      expect(container.read(queuePanelWidthProvider), equals(450.0));

      // Attempt width below minimum
      notifier.setWidth(100.0);
      expect(
        container.read(queuePanelWidthProvider),
        equals(kMinQueuePanelWidth),
      );

      // Attempt width above maximum
      notifier.setWidth(1200.0);
      expect(
        container.read(queuePanelWidthProvider),
        equals(kMaxQueuePanelWidth),
      );
    });

    test('reset restores default width', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(queuePanelWidthProvider.notifier);

      notifier.setWidth(520.0);
      expect(container.read(queuePanelWidthProvider), equals(520.0));

      notifier.reset();
      expect(
        container.read(queuePanelWidthProvider),
        equals(kDefaultQueuePanelWidth),
      );
    });

    test('persists queue panel width across app sessions via Hive', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'queue-width-test-',
      );
      Hive.init(tempDir.path);
      await Hive.openBox('settings');

      try {
        // Session 1: User resizes queue to 480px
        final container1 = ProviderContainer();
        container1.read(queuePanelWidthProvider.notifier).setWidth(480.0);
        expect(container1.read(queuePanelWidthProvider), equals(480.0));

        // Allow debounce timer to flush write to Hive
        await Future<void>.delayed(const Duration(milliseconds: 350));

        // Close app (dispose container)
        container1.dispose();

        // Session 2: User reopens app
        final container2 = ProviderContainer();
        final loadedWidth = container2.read(queuePanelWidthProvider);
        expect(loadedWidth, equals(480.0));
        container2.dispose();
      } finally {
        await Hive.close();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
