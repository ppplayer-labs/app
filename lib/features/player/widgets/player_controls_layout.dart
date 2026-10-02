import 'package:flutter/material.dart';

class PlayerControlAction {
  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool selected;

  const PlayerControlAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.selected = false,
  });
}

/// Gives transport controls and queue navigation distinct places at each width.
class PlayerControlsLayout extends StatelessWidget {
  final Widget transport;
  final Widget fullscreenButton;
  final List<PlayerControlAction> actions;
  final String queueLabel;
  final String optionsLabel;
  final bool queueSelected;
  final VoidCallback onToggleQueue;
  final VoidCallback onInteraction;

  const PlayerControlsLayout({
    super.key,
    required this.transport,
    required this.fullscreenButton,
    required this.actions,
    required this.queueLabel,
    required this.optionsLabel,
    required this.queueSelected,
    required this.onToggleQueue,
    required this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final queue = Semantics(
      selected: queueSelected,
      child: OutlinedButton.icon(
        key: const ValueKey('queue_toggle_button'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: queueSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.1),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: onToggleQueue,
        icon: const Icon(Icons.queue_music, size: 22),
        label: Text(queueLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
    final options = PopupMenuButton<PlayerControlAction>(
      key: const ValueKey('playback_options_button'),
      tooltip: optionsLabel,
      icon: const Icon(Icons.tune, color: Colors.white),
      onOpened: onInteraction,
      onSelected: (action) {
        onInteraction();
        action.onSelected();
      },
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            child: Row(
              children: [
                Icon(
                  action.icon,
                  color: action.selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(action.label)),
              ],
            ),
          ),
      ],
    );
    final utilities = Row(
      mainAxisSize: MainAxisSize.min,
      children: [options, fullscreenButton],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Text scaling can make a single line impractical even on a tablet.
        final wide =
            constraints.maxWidth >= 600 &&
            MediaQuery.textScalerOf(context).scale(16) <= 24;
        if (wide) {
          return Row(
            children: [
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: queue),
              ),
              transport,
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: utilities,
                ),
              ),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            transport,
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(child: queue),
                const SizedBox(width: 8),
                utilities,
              ],
            ),
          ],
        );
      },
    );
  }
}
