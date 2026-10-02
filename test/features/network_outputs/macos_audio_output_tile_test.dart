import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/network_outputs/macos_audio_route.dart';
import 'package:ppplayer/features/network_outputs/macos_audio_output_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ppplayer.app/network_outputs');
  final calls = <String>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Future<void> mount(
    WidgetTester tester, {
    bool remote = false,
    bool connecting = false,
    bool failReturn = false,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MacOSAudioOutputTile(
          route: const MacOSAudioRoute(
            available: true,
            name: 'Living Room',
            airPlay: true,
          ),
          isSelected: !remote && !connecting,
          remoteActive: remote,
          connecting: connecting,
          onReturnToLocal: () async {
            calls.add('return');
            if (failReturn) throw StateError('failed');
          },
        ),
      ),
    ),
  );

  testWidgets(
    'active receiver is named and system settings opens from Play On',
    (tester) async {
      await mount(tester);
      expect(find.textContaining('Playing on Living Room'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byType(UiKitView), findsNothing);
      await tester.tap(find.text('AirPlay & audio output'));
      await tester.pump();
      expect(calls, ['openSystemSoundSettings']);
    },
  );
  testWidgets('remote playback returns locally before opening settings', (
    tester,
  ) async {
    await mount(tester, remote: true);
    await tester.tap(find.text('AirPlay & audio output'));
    await tester.pump();
    expect(calls, ['return', 'openSystemSoundSettings']);
  });
  testWidgets('connecting output cannot open settings or overlap a command', (
    tester,
  ) async {
    await mount(tester, connecting: true);
    await tester.tap(find.text('AirPlay & audio output'));
    await tester.pump();
    expect(calls, isEmpty);
  });
  testWidgets('failed local handoff does not open system routing', (
    tester,
  ) async {
    await mount(tester, remote: true, failReturn: true);
    await tester.tap(find.text('AirPlay & audio output'));
    await tester.pump();
    expect(calls, ['return']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('settings failure is visible and handled cleanly', (
    tester,
  ) async {
    await mount(tester);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'unavailable');
        });
    await tester.tap(find.text('AirPlay & audio output'));
    await tester.pump();
    expect(find.text('Could not open Sound settings.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
