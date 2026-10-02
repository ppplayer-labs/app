import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

class AirPlayRoute {
  const AirPlayRoute({this.connected = false, this.name = ''});
  final bool connected;
  final String name;

  factory AirPlayRoute.fromEvent(dynamic event) {
    final map = event as Map;
    return AirPlayRoute(
      connected: map['connected'] == true,
      name: map['name'] as String? ?? '',
    );
  }

  bool isLocalDeviceSelectedFor(NetworkOutputState state) =>
      !connected &&
      state.selectedOutput.kind == OutputKind.local &&
      !state.connected &&
      !state.connecting;

  bool isSelectedFor(NetworkOutputState state) =>
      connected &&
      state.selectedOutput.kind == OutputKind.local &&
      !state.connected &&
      !state.connecting;
}

/// Separate system-route events also work when the Cast client is a fake.
/// iOS emits the current route upon subscription and subsequent route changes.
final airPlayRouteEventsProvider = Provider<Stream<dynamic>>((ref) {
  if (!Platform.isIOS) return Stream.value({'connected': false, 'name': ''});
  return const EventChannel(
    'com.ppplayer.app/airplay_route_events',
  ).receiveBroadcastStream();
});

final airPlayRouteProvider = StreamProvider<AirPlayRoute>((ref) {
  return ref.watch(airPlayRouteEventsProvider).map((event) {
    final route = AirPlayRoute.fromEvent(event);
    debugPrint(
      '[AirPlay] route connected=${route.connected} name=${route.name}',
    );
    return route;
  });
});
