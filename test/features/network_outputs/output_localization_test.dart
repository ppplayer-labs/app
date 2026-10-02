import 'package:ppplayer/l10n/app_localization_delegates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/network_outputs/macos_audio_route.dart';
import 'package:ppplayer/features/network_outputs/macos_audio_output_tile.dart';
import 'package:ppplayer/l10n/app_localizations.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('output selection fits a narrow window in $locale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Builder(
                    builder: (context) =>
                        Text(AppLocalizations.of(context)!.playOn),
                  ),
                  MacOSAudioOutputTile(
                    route: const MacOSAudioRoute(
                      available: true,
                      name: 'MacBook',
                      airPlay: true,
                    ),
                    isSelected: true,
                    remoteActive: false,
                    connecting: false,
                    onReturnToLocal: () async {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MacOSAudioOutputTile));
      final strings = AppLocalizations.of(context)!;
      expect(strings.localeName, locale.toString());
      expect(find.text(strings.playOn), findsOneWidget);
      expect(find.textContaining(strings.playingOn('MacBook')), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(
        Directionality.of(context),
        ['ar', 'fa', 'ur'].contains(locale.languageCode)
            ? TextDirection.rtl
            : TextDirection.ltr,
      );
      if (['gn', 'pcm'].contains(locale.languageCode)) {
        expect(MaterialLocalizations.of(context).cancelButtonLabel, strings.cancel);
        expect(MaterialLocalizations.of(context).copyButtonLabel, isNot('Copy'));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
