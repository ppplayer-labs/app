import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      expect(container.read(queuePanelWidthProvider), equals(kMinQueuePanelWidth));

      // Attempt width above maximum
      notifier.setWidth(1200.0);
      expect(container.read(queuePanelWidthProvider), equals(kMaxQueuePanelWidth));
    });

    test('reset restores default width', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(queuePanelWidthProvider.notifier);

      notifier.setWidth(520.0);
      expect(container.read(queuePanelWidthProvider), equals(520.0));

      notifier.reset();
      expect(container.read(queuePanelWidthProvider), equals(kDefaultQueuePanelWidth));
    });
  });
}
