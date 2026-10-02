import 'package:flutter/material.dart';

/// AirPlay remains system routing of local playback. The user taps Apple's
/// real route button; no Cast session or media-server URL is created.
class AirPlayOutputTile extends StatelessWidget {
  const AirPlayOutputTile({
    super.key,
    required this.remoteActive,
    required this.connecting,
    required this.onReturnToLocal,
    this.isSelected = false,
    this.deviceName = '',
  });
  final bool remoteActive;
  final bool connecting;
  final VoidCallback onReturnToLocal;
  final bool isSelected;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final needsLocalPlayback = remoteActive || connecting;
    final selected = isSelected && !needsLocalPlayback;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      selected: selected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: selected ? cs.primary.withValues(alpha: 0.12) : null,
      leading: const Icon(Icons.airplay),
      title: const Text('AirPlay'),
      subtitle: Text(
        needsLocalPlayback
            ? 'Switch playback to this iPhone to use AirPlay'
            : selected
            ? 'Playing on ${deviceName.isEmpty ? 'AirPlay device' : deviceName}'
            : 'Tap the AirPlay button to choose a speaker or TV',
      ),
      onTap: needsLocalPlayback && !connecting ? onReturnToLocal : null,
      trailing: needsLocalPlayback
          ? const Icon(Icons.chevron_right)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) Icon(Icons.check_rounded, color: cs.primary),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: UiKitView(
                    key: ValueKey('airplay_system_picker'),
                    viewType: 'com.ppplayer.app/airplay_picker',
                  ),
                ),
              ],
            ),
    );
  }
}

/// Returning to the local engine does not disconnect a system AirPlay route.
/// Let the user choose this iPhone with the public native route picker.
Future<void> showLocalAirPlayRoutePicker(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Play on this iPhone'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose this iPhone using the AirPlay button below.'),
            SizedBox(height: 12),
            SizedBox(
              width: 48,
              height: 48,
              child: UiKitView(viewType: 'com.ppplayer.app/airplay_picker'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
