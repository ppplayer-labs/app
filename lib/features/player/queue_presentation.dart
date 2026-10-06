import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'queue_page.dart';

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
