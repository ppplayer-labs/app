import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

/// macOS system output routing, independent of Cast/DLNA sessions.
class MacOSAudioRoute {
  const MacOSAudioRoute({
    this.available = false,
    this.name = '',
    this.builtIn = false,
    this.airPlay = false,
  });
  final bool available;
  final String name;
  final bool builtIn;
  final bool airPlay;

  factory MacOSAudioRoute.fromEvent(dynamic event) {
    final map = event as Map;
    return MacOSAudioRoute(
      available: map['available'] == true,
      name: map['name'] as String? ?? '',
      builtIn: map['builtIn'] == true,
      airPlay: map['airPlay'] == true,
    );
  }

  bool _localEngine(NetworkOutputState state) =>
      state.selectedOutput.kind == OutputKind.local &&
      !state.connected &&
      !state.connecting;
  bool isSelectedFor(NetworkOutputState state) =>
      available && !builtIn && _localEngine(state);
  bool isLocalDeviceSelectedFor(NetworkOutputState state) =>
      available && builtIn && _localEngine(state);
}

final macOSAudioRouteEventsProvider = Provider<Stream<dynamic>>((ref) {
  if (!Platform.isMacOS) return Stream.value({'available': false});
  return const EventChannel(
    'com.ppplayer.app/system_audio_route_events',
  ).receiveBroadcastStream();
});

final macOSAudioRouteProvider = StreamProvider<MacOSAudioRoute>((ref) {
  return ref
      .watch(macOSAudioRouteEventsProvider)
      .map(MacOSAudioRoute.fromEvent);
});

Future<void> openMacOSSoundSettings() => const MethodChannel(
  'com.ppplayer.app/network_outputs',
).invokeMethod<void>('openSystemSoundSettings');
