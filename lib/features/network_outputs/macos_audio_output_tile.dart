import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/network_outputs/macos_audio_route.dart';

Future<void> showMacOSSoundSettings(BuildContext context) async {
  try {
    await openMacOSSoundSettings();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.soundSettingsError),
        ),
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
    title: Text(AppLocalizations.of(context)!.airPlayAudioOutput),
    subtitle: Text(
      remoteActive || connecting
          ? AppLocalizations.of(context)!.returnForAirPlay
          : route?.available == true
          ? '${isSelected ? AppLocalizations.of(context)!.playingOn(route!.name) : '${AppLocalizations.of(context)!.systemOutput}: ${route!.name}'}\n${AppLocalizations.of(context)!.openSoundSettings}'
          : AppLocalizations.of(context)!.openSoundSettings,
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
