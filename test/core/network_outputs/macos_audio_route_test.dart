import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/network_outputs/macos_audio_route.dart';
import 'package:ppplayer/core/network_outputs/models.dart';

void main() {
  test('built-in and AirPlay routes select mutually exclusive output rows', () {
    const state = NetworkOutputState();
    final builtIn = MacOSAudioRoute.fromEvent({
      'available': true,
      'name': 'MacBook Speakers',
      'builtIn': true,
    });
    expect(builtIn.isLocalDeviceSelectedFor(state), isTrue);
    expect(builtIn.isSelectedFor(state), isFalse);
    final airPlay = MacOSAudioRoute.fromEvent({
      'available': true,
      'name': 'Living Room',
      'airPlay': true,
    });
    expect(airPlay.isSelectedFor(state), isTrue);
    expect(airPlay.isLocalDeviceSelectedFor(state), isFalse);
    expect(airPlay.airPlay, isTrue);
    expect(airPlay.name, 'Living Room');
    const unavailable = MacOSAudioRoute();
    expect(unavailable.isSelectedFor(state), isFalse);
    expect(unavailable.isLocalDeviceSelectedFor(state), isFalse);
  });

  test('external system route cannot override remote or connecting output', () {
    const route = MacOSAudioRoute(available: true, name: 'USB Audio');
    expect(route.airPlay, isFalse);
    expect(route.isSelectedFor(const NetworkOutputState()), isTrue);
    for (final state in [
      const NetworkOutputState(connected: true),
      const NetworkOutputState(connecting: true),
      const NetworkOutputState(
        selectedOutput: PlaybackOutput(
          id: 'dlna',
          name: 'Receiver',
          kind: OutputKind.dlna,
          capabilities: OutputCapabilities(audio: true),
        ),
      ),
    ]) {
      expect(route.isSelectedFor(state), isFalse);
      expect(route.isLocalDeviceSelectedFor(state), isFalse);
    }
  });

  test(
    'route events update receiver name and return to built-in output',
    () async {
      final events = StreamController<dynamic>();
      final container = ProviderContainer(
        overrides: [
          macOSAudioRouteEventsProvider.overrideWithValue(events.stream),
        ],
      );
      final sub = container.listen(macOSAudioRouteProvider, (_, _) {});
      try {
        events.add({'available': true, 'name': 'Bedroom', 'airPlay': true});
        final route = await container.read(macOSAudioRouteProvider.future);
        expect(route.name, 'Bedroom');
        events.add({
          'available': true,
          'name': 'Mac Speakers',
          'builtIn': true,
        });
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(macOSAudioRouteProvider).requireValue.builtIn,
          isTrue,
        );
      } finally {
        sub.close();
        container.dispose();
        await events.close();
      }
    },
  );
}
