import 'package:ppplayer/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/network_outputs/capability_resolver.dart';
import '../../core/network_outputs/models.dart';
import 'airplay_output_tile.dart';
import 'macos_audio_output_tile.dart';
import '../../core/network_outputs/macos_audio_route.dart';
import '../../core/network_outputs/airplay_route.dart';
import '../../core/network_outputs/network_output_providers.dart';
import '../../core/player/player_provider.dart';
import '../../core/playback/playback_providers.dart';

/// Shows the output picker as a bottom-sheet (mobile) or dialog (desktop/tablet).
/// Caller must ensure the app has local-network permission before calling this.
Future<void> showOutputPicker(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(networkOutputControllerProvider);
  unawaited(controller.startDiscovery().catchError((_) {}));

  if (Platform.isIOS || Platform.isAndroid) {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _OutputPickerSheet(),
    );
  } else {
    await showDialog<void>(
      context: context,
      builder: (_) => const _OutputPickerDialog(),
    );
  }

  // Stop discovery only when no remote session is active.
  final state = ref.read(networkOutputSnapshotProvider);
  if (!state.connected) {
    unawaited(controller.stopDiscovery().catchError((_) {}));
  }
}

// ── Mobile bottom-sheet ───────────────────────────────────────────────────

class _OutputPickerSheet extends StatelessWidget {
  const _OutputPickerSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: _OutputPickerContent(scrollController: scrollController),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop dialog ────────────────────────────────────────────────────────

class _OutputPickerDialog extends StatelessWidget {
  const _OutputPickerDialog();

  @override
  Widget build(BuildContext context) => Dialog(
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: SizedBox(
      width: 380,
      height: 520,
      child: _OutputPickerContent(scrollController: ScrollController()),
    ),
  );
}

// ── Shared content ────────────────────────────────────────────────────────

class _OutputPickerContent extends ConsumerWidget {
  const _OutputPickerContent({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(networkOutputSnapshotProvider);
    final track = ref.watch(playerProvider).currentTrack;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final localOutputs = state.availableOutputs
        .where((o) => o.kind == OutputKind.local)
        .toList();
    final remoteOutputs = state.availableOutputs
        .where((o) => o.kind != OutputKind.local)
        .toList();
    final selected = state.selectedOutput;
    final showAirPlay =
        Platform.isIOS &&
        (ref
                .watch(networkOutputCapabilitiesProvider)
                .asData
                ?.value
                .airPlayPickerAvailable ??
            false);
    final route = showAirPlay
        ? ref.watch(airPlayRouteProvider).asData?.value
        : null;
    final airPlaySelected = route?.isSelectedFor(state) ?? false;
    final showMacOSRouting = Platform.isMacOS;
    final macRoute = showMacOSRouting
        ? ref.watch(macOSAudioRouteProvider).asData?.value
        : null;
    final macExternalSelected = macRoute?.isSelectedFor(state) ?? false;
    PlaybackTrack? pbTrack;
    try {
      pbTrack = track?.toPlaybackTrack();
    } catch (_) {}

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.playOn,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (kDebugMode)
                IconButton(
                  icon: const Icon(Icons.bug_report, size: 20),
                  onPressed: () {
                    final urls = ref
                        .read(localMediaServerProvider)
                        .debugActiveUrls;
                    if (urls.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No active local media URLs')),
                      );
                      return;
                    }
                    Clipboard.setData(ClipboardData(text: urls.join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Copied ${urls.length} URLs to clipboard',
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        if (state.error != null)
          _ErrorBanner(
            message: AppLocalizations.of(context)!.error(state.error!),
          ),
        if (state.connecting) _ConnectingTile(output: state.connectingOutput),

        _SectionHeader(label: AppLocalizations.of(context)!.thisDevice),
        for (final output in localOutputs)
          _OutputTile(
            output: output,
            isSelected:
                selected.kind == OutputKind.local &&
                (!showMacOSRouting ||
                    (macRoute?.isLocalDeviceSelectedFor(state) ?? false)) &&
                (!showAirPlay ||
                    (route?.isLocalDeviceSelectedFor(state) ?? false)),
            onTapOverride: airPlaySelected
                ? () => showLocalAirPlayRoutePicker(context)
                : macExternalSelected
                ? () => showMacOSSoundSettings(context)
                : null,
            isConnected: false,
            pbTrack: pbTrack,
            state: state,
          ),

        if (showAirPlay ||
            showMacOSRouting ||
            remoteOutputs.isNotEmpty ||
            state.discoveryActive) ...[
          const SizedBox(height: 8),
          _SectionHeader(label: AppLocalizations.of(context)!.availableDevices),
        ],
        if (showMacOSRouting)
          MacOSAudioOutputTile(
            route: macRoute,
            isSelected: macExternalSelected,
            remoteActive: state.connected,
            connecting: state.connecting,
            onReturnToLocal: () => ref
                .read(networkOutputControllerProvider)
                .selectOutput(PlaybackOutput.local),
          ),
        if (showAirPlay)
          AirPlayOutputTile(
            isSelected: airPlaySelected,
            deviceName: route?.name ?? '',
            remoteActive: state.connected,
            connecting: state.connecting,
            onReturnToLocal: () async {
              try {
                await ref
                    .read(networkOutputControllerProvider)
                    .selectOutput(PlaybackOutput.local);
              } catch (_) {
                // The controller exposes failures in the existing error banner.
              }
            },
          ),
        if (state.discoveryActive && remoteOutputs.isEmpty)
          const _SearchingTile(),
        for (final output in remoteOutputs)
          _OutputTile(
            output: output,
            isSelected: state.connected && selected.id == output.id,
            isConnected: state.connected && selected.id == output.id,
            pbTrack: pbTrack,
            state: state,
          ),

        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            icon: Icon(Icons.refresh, size: 18, color: cs.primary),
            label: Text(AppLocalizations.of(context)!.refresh),
            onPressed: () {
              unawaited(
                ref
                    .read(networkOutputControllerProvider)
                    .refreshDiscovery()
                    .catchError((_) {}),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    ),
  );
}

class _SearchingTile extends StatelessWidget {
  const _SearchingTile();

  @override
  Widget build(BuildContext context) => ListTile(
    leading: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    title: Text(
      AppLocalizations.of(context)!.searchingDevices,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(
          Icons.warning_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ConnectingTile extends StatelessWidget {
  const _ConnectingTile({this.output});
  final PlaybackOutput? output;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    title: Text(
      output != null
          ? AppLocalizations.of(context)!.connectingTo(output!.name)
          : AppLocalizations.of(context)!.connecting,
    ),
  );
}

class _OutputTile extends ConsumerWidget {
  const _OutputTile({
    required this.output,
    required this.isSelected,
    required this.isConnected,
    required this.pbTrack,
    required this.state,
    this.onTapOverride,
  });

  final PlaybackOutput output;
  final bool isSelected;
  final bool isConnected;
  final PlaybackTrack? pbTrack;
  final NetworkOutputState state;
  final VoidCallback? onTapOverride;

  IconData _iconFor(OutputKind kind) => switch (kind) {
    OutputKind.local => Icons.smartphone,
    OutputKind.dlna => Icons.tv_outlined,
    OutputKind.googleCast => Icons.cast,
    OutputKind.airPlay => Icons.airplay,
    _ => Icons.devices,
  };

  String _subtitleFor(OutputKind kind) => switch (kind) {
    OutputKind.dlna => 'DLNA',
    OutputKind.googleCast => 'Chromecast',
    OutputKind.airPlay => 'AirPlay',
    _ => '',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    final isUnsupported =
        pbTrack != null &&
        output.kind != OutputKind.local &&
        !const OutputCapabilityResolver()
            .sourceSupport(pbTrack!, output)
            .supported;

    return Opacity(
      opacity: isUnsupported ? 0.5 : 1.0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? cs.primary.withValues(alpha: 0.12) : null,
        leading: Icon(
          _iconFor(output.kind),
          color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
        ),
        title: Text(
          output.kind == OutputKind.local
              ? AppLocalizations.of(context)!.thisDevice
              : output.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? cs.primary : cs.onSurface,
          ),
        ),
        subtitle: Text(
          isUnsupported
              ? AppLocalizations.of(context)!.unsupportedOutput
              : isConnected
              ? AppLocalizations.of(context)!.connected
              : _subtitleFor(output.kind),
          style: TextStyle(
            fontSize: 12,
            color: isConnected
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_rounded, color: cs.primary)
            : null,
        onTap:
            onTapOverride ??
            (isUnsupported
                ? null
                : () async {
                    final ctrl = ref.read(networkOutputControllerProvider);
                    if (output.kind == OutputKind.local || isSelected) {
                      if (context.mounted) Navigator.of(context).pop();
                      if (!isSelected || output.kind != OutputKind.local) {
                        unawaited(ctrl.returnToLocal().catchError((_) {}));
                      }
                    } else {
                      if (context.mounted) Navigator.of(context).pop();
                      unawaited(ctrl.selectOutput(output).catchError((_) {}));
                    }
                  }),
      ),
    );
  }
}
