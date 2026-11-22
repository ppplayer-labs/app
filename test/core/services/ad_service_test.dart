import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppplayer/core/services/ad_service.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/features/settings/settings_screen.dart';
import 'package:ppplayer/l10n/app_localization_delegates.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/shared/widgets/banner_ad_widget.dart';

class _StaticSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => SettingsState(
    selectedCountry: 'US',
    showVideo: true,
    themeIndex: 0,
    performanceMode: PerformanceMode.high,
    lowDataMode: false,
    autoplayEnabled: false,
    isLoaded: true,
  );
}

void main() {
  group('AdService (temporary ads-free release)', () {
    test(
      'reports advertising disabled with no unit IDs or promo data',
      () async {
        final service = AdService();
        await service.initialization;

        expect(service.isAdsEnabled, isFalse);
        expect(service.isMobileAdsSupported, isFalse);
        expect(service.canRequestAds, isFalse);
        expect(service.canRequestAdsListenable.value, isFalse);
        expect(service.privacyOptionsRequired, isFalse);
        expect(service.privacyOptionsRequiredListenable.value, isFalse);
        expect(service.bannerAdUnitId, isEmpty);
        expect(service.getPromoData(), isEmpty);
        expect(await service.isPrivacyOptionsRequired(), isFalse);
        expect(await service.refreshConsentStatus(), isFalse);
        expect(await service.showPrivacyOptionsForm(), isFalse);
      },
    );

    test(
      'provider exposes disabled AdService without pending timers',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(adServiceProvider);
        await service.initialization;

        expect(service.isAdsEnabled, isFalse);
        expect(service.canRequestAds, isFalse);
        expect(service.bannerAdUnitId, isEmpty);
      },
    );
  });

  group('BannerAdWidget (temporary ads-free release)', () {
    testWidgets('renders zero-size widget with no reserved banner space', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Center(child: BannerAdWidget())),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(BannerAdWidget)), Size.zero);
      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsScreen (temporary ads-free release)', () {
    testWidgets(
      'hides Ad privacy options tile while keeping unrelated settings intact',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(_StaticSettingsNotifier.new),
              appVersionProvider.overrideWith((ref) async => '4.0.2+14'),
            ],
            child: MaterialApp(
              localizationsDelegates: appLocalizationDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        await tester.scrollUntilVisible(
          find.text('Clear Recently Played'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump(const Duration(seconds: 2));

        expect(find.text('Ad privacy options'), findsNothing);
        expect(find.text('Clear Recently Played'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('4.0.2+14'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Ad privacy options'), findsNothing);
        expect(find.text('4.0.2+14'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });
}
