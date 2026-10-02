import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/network_outputs/airplay_route.dart';
import 'package:ppplayer/core/network_outputs/models.dart';

void main() {
  test(
    'MacBook AirPlay route deselects This Device; disconnected route selects it',
    () {
      const state = NetworkOutputState();
      final mac = AirPlayRoute.fromEvent({
        'connected': true,
        'name': 'My MacBook',
      });
      expect(mac.name, 'My MacBook');
      expect(mac.isSelectedFor(state), isTrue);
      expect(mac.isLocalDeviceSelectedFor(state), isFalse);
      const local = AirPlayRoute();
      expect(local.isSelectedFor(state), isFalse);
      expect(local.isLocalDeviceSelectedFor(state), isTrue);
    },
  );

  test('an active system audio route does not replace Cast selection', () {
    const route = AirPlayRoute(connected: true, name: 'MacBook');
    final state = NetworkOutputState(
      selectedOutput: PlaybackOutput(
        id: 'cast',
        name: 'Cast',
        kind: OutputKind.googleCast,
        capabilities: const OutputCapabilities(audio: true),
      ),
    );
    expect(route.isSelectedFor(state), isFalse);
    expect(route.isLocalDeviceSelectedFor(state), isFalse);
    expect(
      route.isSelectedFor(const NetworkOutputState(connecting: true)),
      isFalse,
    );
  });

  test(
    'initial and subsequent native route events update provider selection',
    () async {
      final events = StreamController<dynamic>();
      final container = ProviderContainer(
        overrides: [
          airPlayRouteEventsProvider.overrideWithValue(events.stream),
        ],
      );
      final subscription = container.listen(airPlayRouteProvider, (_, _) {});
      try {
        events.add({'connected': true, 'name': 'My MacBook'});
        final initial = await container.read(airPlayRouteProvider.future);
        expect(initial.isSelectedFor(const NetworkOutputState()), isTrue);
        events.add({'connected': false, 'name': ''});
        await Future<void>.delayed(Duration.zero);
        final next = container.read(airPlayRouteProvider).asData!.value;
        expect(next.isSelectedFor(const NetworkOutputState()), isFalse);
        expect(
          next.isLocalDeviceSelectedFor(const NetworkOutputState()),
          isTrue,
        );
      } finally {
        subscription.close();
        container.dispose();
        await events.close();
      }
    },
  );
}
