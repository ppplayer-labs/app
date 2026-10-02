import 'package:flutter/material.dart';
import '../../core/network_outputs/macos_audio_route.dart';

Future<void> showMacOSSoundSettings(BuildContext context) async {
  try {
    await openMacOSSoundSettings();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Sound settings.')),
      );
    }
  }
}

class MacOSAudioOutputTile extends StatelessWidget {
  const MacOSAudioOutputTile({
    super.key,
    required this.route,
    required this.isSelected,
    required this.remoteActive,
    required this.connecting,
    required this.onReturnToLocal,
  });
  final MacOSAudioRoute? route;
  final bool isSelected;
  final bool remoteActive;
  final bool connecting;
  final Future<void> Function() onReturnToLocal;

  @override
  Widget build(BuildContext context) => ListTile(
    selected: isSelected,
    leading: Icon(route?.airPlay == true ? Icons.airplay : Icons.speaker),
    title: const Text('AirPlay & audio output'),
    subtitle: Text(
      remoteActive || connecting
          ? 'Return playback to this Mac to choose a system output'
          : route?.available == true
          ? '${isSelected ? 'Playing on' : 'System output'} ${route!.name}. Open Sound settings to change it.'
          : 'Open Sound settings to choose an output',
    ),
    trailing: Icon(isSelected ? Icons.check_rounded : Icons.open_in_new),
    onTap: connecting
        ? null
        : () async {
            try {
              if (remoteActive) await onReturnToLocal();
              if (context.mounted) await showMacOSSoundSettings(context);
            } catch (_) {
              // Return-to-local failures remain visible in the output picker.
            }
          },
  );
}
