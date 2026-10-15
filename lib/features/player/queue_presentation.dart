import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import 'queue_page.dart';

const double kDefaultQueuePanelWidth = 360.0;
const double kMinQueuePanelWidth = 260.0;
const double kMaxQueuePanelWidth = 640.0;

class QueuePanelWidthNotifier extends Notifier<double> {
  static const _boxName = 'settings';
  static const _queueWidthKey = 'queue_panel_width';

  Timer? _saveDebounce;

  @override
  double build() {
    ref.onDispose(() {
      _saveDebounce?.cancel();
    });

    try {
      if (Hive.isBoxOpen(_boxName)) {
        final saved = Hive.box(_boxName).get(_queueWidthKey);
        if (saved is num) {
          return saved.toDouble().clamp(kMinQueuePanelWidth, kMaxQueuePanelWidth);
        }
      } else {
        _loadPersistedWidth();
      }
    } catch (_) {
      // In case Hive is not initialized (e.g. simple unit tests)
    }

    return kDefaultQueuePanelWidth;
  }

  Future<void> _loadPersistedWidth() async {
    try {
      final box = await Hive.openBox(_boxName);
      final saved = box.get(_queueWidthKey);
      if (saved is num) {
        state = saved.toDouble().clamp(kMinQueuePanelWidth, kMaxQueuePanelWidth);
      }
    } catch (_) {
      // Ignore storage errors on startup or in unit tests
    }
  }

  void setWidth(double width) {
    final clamped = width.clamp(kMinQueuePanelWidth, kMaxQueuePanelWidth);
    state = clamped;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      _persistWidth(clamped);
    });
  }

  void reset() {
    state = kDefaultQueuePanelWidth;
    _saveDebounce?.cancel();
    _persistWidth(kDefaultQueuePanelWidth);
  }

  Future<void> _persistWidth(double width) async {
    try {
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      await box.put(_queueWidthKey, width);
    } catch (_) {
      // Ignore storage errors in unit tests
    }
  }
}

final queuePanelWidthProvider =
    NotifierProvider<QueuePanelWidthNotifier, double>(
  QueuePanelWidthNotifier.new,
);

class QueuePanelVisibility extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void close() => state = false;
}

final queuePanelProvider = NotifierProvider<QueuePanelVisibility, bool>(
  QueuePanelVisibility.new,
);

bool supportsQueuePanel(BuildContext context) =>
    {
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    }.contains(defaultTargetPlatform) &&
    MediaQuery.sizeOf(context).width >= 900;

Future<void> openQueue(BuildContext context, WidgetRef ref) async {
  if (supportsQueuePanel(context)) {
    ref.read(queuePanelProvider.notifier).toggle();
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * 0.9,
      child: QueuePage(onClose: () => Navigator.of(sheetContext).pop()),
    ),
  );
}
