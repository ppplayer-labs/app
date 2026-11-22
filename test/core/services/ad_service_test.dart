import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ppplayer/core/services/ad_service.dart';
import 'package:ppplayer/core/services/settings_provider.dart';
import 'package:ppplayer/features/settings/settings_screen.dart';
import 'package:ppplayer/l10n/app_localization_delegates.dart';
import 'package:ppplayer/l10n/app_localizations.dart';
import 'package:ppplayer/shared/widgets/banner_ad_widget.dart';

class _FakeBannerAd extends Fake implements BannerAd {
  _FakeBannerAd({
    required this.adUnitId,
    required this.size,
    required this.listener,
    this.onLoadCalled,
  });

  @override
  final String adUnitId;

  @override
  final AdSize size;

  @override
  final BannerAdListener listener;

  final Future<void> Function(_FakeBannerAd ad)? onLoadCalled;
  int loadCount = 0;
  int disposeCount = 0;

  @override
  Future<void> load() async {
    loadCount++;
    await onLoadCalled?.call(this);
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

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
  group('AdService', () {
    test('uses test Android unit ID in debug and production ID in release', () {
      final debugService = AdService(
        initializationDelay: Duration.zero,
        isAndroid: true,
        isIOS: false,
        isReleaseMode: false,
        gatherConsent: () async => false,
        checkPrivacyOptionsRequired: () async => false,
        initializeMobileAds: () async => InitializationStatus({}),
      );
      final releaseService = AdService(
        initializationDelay: Duration.zero,
        isAndroid: true,
        isIOS: false,
        isReleaseMode: true,
        gatherConsent: () async => false,
        checkPrivacyOptionsRequired: () async => false,
        initializeMobileAds: () async => InitializationStatus({}),
      );

      expect(
        debugService.bannerAdUnitId,
        'ca-app-pub-3940256099942544/6300978111',
      );
      expect(
        releaseService.bannerAdUnitId,
        'ca-app-pub-3432071939645868/7074619663',
      );
      expect(debugService.isMobileAdsSupported, isTrue);
      expect(releaseService.isMobileAdsSupported, isTrue);
    });

    test('disables ads cleanly on desktop platforms', () async {
      var consentCalled = false;
      var sdkInitCalled = false;
      final desktopService = AdService(
        initializationDelay: Duration.zero,
        isAndroid: false,
        isIOS: false,
        isReleaseMode: true,
        gatherConsent: () async {
          consentCalled = true;
          return true;
        },
        checkPrivacyOptionsRequired: () async => true,
        initializeMobileAds: () async {
          sdkInitCalled = true;
          return InitializationStatus({});
        },
      );

      await desktopService.initialization;

      expect(desktopService.isMobileAdsSupported, isFalse);
      expect(desktopService.bannerAdUnitId, isEmpty);
      expect(desktopService.canRequestAds, isFalse);
      expect(desktopService.privacyOptionsRequired, isFalse);
      expect(await desktopService.showPrivacyOptionsForm(), isFalse);
      expect(consentCalled, isFalse);
      expect(sdkInitCalled, isFalse);
    });

    test(
      'initializes MobileAds only once after UMP consent grants permission',
      () async {
        final events = <String>[];
        var initCalls = 0;
        final service = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async {
            events.add('consent');
            return true;
          },
          checkPrivacyOptionsRequired: () async => true,
          queryCanRequestAds: () async => true,
          initializeMobileAds: () async {
            initCalls++;
            events.add('init');
            return InitializationStatus({});
          },
        );

        await service.initialization;
        await service.refreshConsentStatus();

        expect(events, ['consent', 'init']);
        expect(initCalls, 1);
        expect(service.canRequestAds, isTrue);
        expect(service.privacyOptionsRequired, isTrue);
      },
    );

    test('skips MobileAds init when UMP consent denies ad requests', () async {
      var sdkInitCalled = false;
      final service = AdService(
        initializationDelay: Duration.zero,
        isAndroid: true,
        isIOS: false,
        isReleaseMode: false,
        gatherConsent: () async => false,
        checkPrivacyOptionsRequired: () async => true,
        initializeMobileAds: () async {
          sdkInitCalled = true;
          return InitializationStatus({});
        },
      );

      await service.initialization;

      expect(sdkInitCalled, isFalse);
      expect(service.canRequestAds, isFalse);
      expect(service.privacyOptionsRequired, isTrue);
    });

    test(
      'restoring consent via privacy options initializes MobileAds once and enables ads',
      () async {
        var allowed = false;
        var sdkInitCalls = 0;
        final service = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async => allowed,
          checkPrivacyOptionsRequired: () async => true,
          queryCanRequestAds: () async => allowed,
          presentPrivacyOptionsForm: () async {
            allowed = true;
            return true;
          },
          initializeMobileAds: () async {
            sdkInitCalls++;
            return InitializationStatus({});
          },
        );

        await service.initialization;
        expect(service.canRequestAds, isFalse);
        expect(sdkInitCalls, 0);

        final presented = await service.showPrivacyOptionsForm();
        expect(presented, isTrue);
        expect(service.canRequestAds, isTrue);
        expect(sdkInitCalls, 1);

        // Subsequent consent revocation disables ad requests without re-initializing SDK.
        allowed = false;
        await service.refreshConsentStatus();
        expect(service.canRequestAds, isFalse);
        expect(sdkInitCalls, 1);
      },
    );

    test(
      'coalesces concurrent showPrivacyOptionsForm taps into one presentation',
      () async {
        final gate = Completer<bool>();
        var presentCalls = 0;
        final service = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async => true,
          checkPrivacyOptionsRequired: () async => true,
          queryCanRequestAds: () async => true,
          presentPrivacyOptionsForm: () {
            presentCalls++;
            return gate.future;
          },
          initializeMobileAds: () async => InitializationStatus({}),
        );

        await service.initialization;

        final first = service.showPrivacyOptionsForm();
        final second = service.showPrivacyOptionsForm();
        expect(presentCalls, 1);

        gate.complete(true);
        expect(await first, isTrue);
        expect(await second, isTrue);
      },
    );

    test(
      'fails closed without throwing when consent or SDK init errors',
      () async {
        final consentErrorService = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async => throw StateError('offline'),
          checkPrivacyOptionsRequired: () async => false,
          initializeMobileAds: () async => InitializationStatus({}),
        );
        final initErrorService = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async => true,
          checkPrivacyOptionsRequired: () async => false,
          initializeMobileAds: () async => throw StateError('sdk failed'),
        );

        await consentErrorService.initialization;
        await initErrorService.initialization;

        expect(consentErrorService.canRequestAds, isFalse);
        expect(initErrorService.canRequestAds, isFalse);
      },
    );
  });

  group('BannerAdWidget', () {
    testWidgets(
      'does not double-dispose BannerAd when onAdFailedToLoad fires before unmount',
      (tester) async {
        final createdAds = <_FakeBannerAd>[];
        final adService = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async => true,
          checkPrivacyOptionsRequired: () async => false,
          initializeMobileAds: () async => InitializationStatus({}),
          bannerAdBuilder:
              ({
                required adUnitId,
                required size,
                required request,
                required listener,
              }) {
                final ad = _FakeBannerAd(
                  adUnitId: adUnitId,
                  size: size,
                  listener: listener,
                  onLoadCalled: (self) async {
                    self.listener.onAdFailedToLoad?.call(
                      self,
                      LoadAdError(3, 'admob', 'no fill', null),
                    );
                  },
                );
                createdAds.add(ad);
                return ad;
              },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [adServiceProvider.overrideWithValue(adService)],
            child: const MaterialApp(home: Scaffold(body: BannerAdWidget())),
          ),
        );
        await tester.pumpAndSettle();

        expect(createdAds, hasLength(1));
        expect(createdAds.single.loadCount, 1);
        expect(createdAds.single.disposeCount, 1);

        // Unmount widget and verify dispose() does NOT dispose the failed ad a second time.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(createdAds.single.disposeCount, 1);
      },
    );

    testWidgets(
      'disposes ad cleanly when widget unmounts while load is still in flight',
      (tester) async {
        final createdAds = <_FakeBannerAd>[];
        final loadCompleter = Completer<void>();
        final adService = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async => true,
          checkPrivacyOptionsRequired: () async => false,
          initializeMobileAds: () async => InitializationStatus({}),
          bannerAdBuilder:
              ({
                required adUnitId,
                required size,
                required request,
                required listener,
              }) {
                final ad = _FakeBannerAd(
                  adUnitId: adUnitId,
                  size: size,
                  listener: listener,
                  onLoadCalled: (self) async {
                    await loadCompleter.future;
                    self.listener.onAdLoaded?.call(self);
                  },
                );
                createdAds.add(ad);
                return ad;
              },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [adServiceProvider.overrideWithValue(adService)],
            child: const MaterialApp(home: Scaffold(body: BannerAdWidget())),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(createdAds, hasLength(1));

        // Unmount before onAdLoaded fires.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(createdAds.single.disposeCount, 1);

        // Late onAdLoaded fires after unmount: must not throw setState-after-dispose.
        loadCompleter.complete();
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'disposes active banner when consent is revoked and reloads when restored',
      (tester) async {
        var allowed = true;
        final createdAds = <_FakeBannerAd>[];
        final adService = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async => allowed,
          checkPrivacyOptionsRequired: () async => true,
          queryCanRequestAds: () async => allowed,
          initializeMobileAds: () async => InitializationStatus({}),
          bannerAdBuilder:
              ({
                required adUnitId,
                required size,
                required request,
                required listener,
              }) {
                final ad = _FakeBannerAd(
                  adUnitId: adUnitId,
                  size: size,
                  listener: listener,
                );
                createdAds.add(ad);
                return ad;
              },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [adServiceProvider.overrideWithValue(adService)],
            child: const MaterialApp(home: Scaffold(body: BannerAdWidget())),
          ),
        );
        await tester.pumpAndSettle();
        expect(createdAds, hasLength(1));
        expect(createdAds.first.disposeCount, 0);

        // Revoke consent: existing banner must be disposed immediately.
        allowed = false;
        await adService.refreshConsentStatus();
        await tester.pump();
        expect(createdAds.first.disposeCount, 1);

        // Restore consent: banner reloads cleanly.
        allowed = true;
        await adService.refreshConsentStatus();
        await tester.pumpAndSettle();
        expect(createdAds, hasLength(2));
      },
    );

    testWidgets('creates zero ads when consent is denied or on desktop', (
      tester,
    ) async {
      var buildCount = 0;
      final adService = AdService(
        initializationDelay: Duration.zero,
        isAndroid: true,
        isIOS: false,
        isReleaseMode: false,
        gatherConsent: () async => false,
        checkPrivacyOptionsRequired: () async => false,
        initializeMobileAds: () async => InitializationStatus({}),
        bannerAdBuilder:
            ({
              required adUnitId,
              required size,
              required request,
              required listener,
            }) {
              buildCount++;
              return _FakeBannerAd(
                adUnitId: adUnitId,
                size: size,
                listener: listener,
              );
            },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [adServiceProvider.overrideWithValue(adService)],
          child: const MaterialApp(home: Scaffold(body: BannerAdWidget())),
        ),
      );
      await tester.pumpAndSettle();

      expect(buildCount, 0);
    });
  });

  group('SettingsScreen ad privacy options entry point', () {
    Widget buildSettingsApp(AdService adService) {
      return ProviderScope(
        overrides: [
          adServiceProvider.overrideWithValue(adService),
          settingsProvider.overrideWith(_StaticSettingsNotifier.new),
          appVersionProvider.overrideWith((ref) async => '4.0.2+14'),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SettingsScreen(),
        ),
      );
    }

    testWidgets(
      'hides Ad privacy options when UMP reports privacy options not required',
      (tester) async {
        final adService = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async => true,
          checkPrivacyOptionsRequired: () async => false,
          initializeMobileAds: () async => InitializationStatus({}),
        );

        await tester.pumpWidget(buildSettingsApp(adService));
        await tester.pump(const Duration(seconds: 1));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pump(const Duration(seconds: 2));

        expect(find.text('Ad privacy options'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets(
      'shows Ad privacy options when required, coalesces repeated taps, and surfaces error notice on failure',
      (tester) async {
        final formGate = Completer<bool>();
        var presentCalls = 0;
        final adService = AdService(
          initializationDelay: Duration.zero,
          isAndroid: true,
          isIOS: false,
          isReleaseMode: false,
          gatherConsent: () async => true,
          checkPrivacyOptionsRequired: () async => true,
          queryCanRequestAds: () async => true,
          presentPrivacyOptionsForm: () {
            presentCalls++;
            return formGate.future;
          },
          initializeMobileAds: () async => InitializationStatus({}),
        );

        await tester.pumpWidget(buildSettingsApp(adService));
        await tester.pump(const Duration(seconds: 1));

        final tileFinder = find.text('Ad privacy options');
        await tester.scrollUntilVisible(
          tileFinder,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tileFinder, findsOneWidget);

        // Tap twice while form is open: second tap must be ignored while loading.
        await tester.tap(tileFinder);
        await tester.pump();
        await tester.tap(tileFinder);
        await tester.pump();
        expect(presentCalls, 1);

        // Simulate UMP form failure -> user receives localized error SnackBar.
        formGate.complete(false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text(
            'Unable to open privacy options right now. Please try again later.',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });
}
