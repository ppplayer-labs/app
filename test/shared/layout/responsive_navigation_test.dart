import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/shared/layout/responsive_navigation.dart';

void main() {
  Future<void> checkLayout(
    WidgetTester tester,
    TargetPlatform platform,
    Size size,
    bool wide,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) =>
                Text(usesWideNavigation(context) ? 'wide' : 'compact'),
          ),
        ),
      ),
    );
    expect(find.text(wide ? 'wide' : 'compact'), findsOneWidget);
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform phone remains compact through rotation', (
      tester,
    ) async {
      await checkLayout(tester, platform, const Size(390, 844), false);
      await checkLayout(tester, platform, const Size(844, 390), false);
      await checkLayout(tester, platform, const Size(390, 844), false);
    });
    testWidgets('$platform tablet keeps wide navigation through rotation', (
      tester,
    ) async {
      await checkLayout(tester, platform, const Size(768, 1024), true);
      await checkLayout(tester, platform, const Size(1024, 768), true);
    });
  }

  testWidgets('desktop responds to width even in a short window', (
    tester,
  ) async {
    await checkLayout(tester, TargetPlatform.macOS, const Size(844, 390), true);
    await checkLayout(
      tester,
      TargetPlatform.macOS,
      const Size(590, 390),
      false,
    );
  });
}
