import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/features/network_outputs/airplay_output_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter/platform_views'),
          (_) async => null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter/platform_views'),
          null,
        );
  });

  testWidgets(
    'remote playback must return locally before presenting system routing',
    (tester) async {
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AirPlayOutputTile(
              remoteActive: true,
              connecting: false,
              onReturnToLocal: () => returned = true,
            ),
          ),
        ),
      );
      expect(find.byType(UiKitView), findsNothing);
      await tester.tap(find.text('AirPlay'));
      expect(returned, isTrue);
    },
  );

  testWidgets(
    'connecting output cannot trigger an overlapping return-to-local command',
    (tester) async {
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AirPlayOutputTile(
              remoteActive: false,
              connecting: true,
              onReturnToLocal: () => returned = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('AirPlay'));
      expect(returned, isFalse);
      expect(find.byType(UiKitView), findsNothing);
    },
  );

  testWidgets('local playback exposes the registered native AirPlay picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AirPlayOutputTile(
            remoteActive: false,
            connecting: false,
            onReturnToLocal: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    final picker = tester.widget<UiKitView>(find.byType(UiKitView));
    expect(picker.viewType, 'com.ppplayer.app/airplay_picker');
  });
  testWidgets(
    'active MacBook AirPlay route shows its name and selected check',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AirPlayOutputTile(
              remoteActive: false,
              connecting: false,
              isSelected: true,
              deviceName: 'My MacBook',
              onReturnToLocal: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Playing on My MacBook'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(tester.widget<ListTile>(find.byType(ListTile)).selected, isTrue);
    },
  );
}
