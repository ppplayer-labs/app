import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ConsentGatherer = Future<bool> Function();
typedef MobileAdsInitializer = Future<InitializationStatus> Function();
typedef PrivacyOptionsStatusChecker = Future<bool> Function();
typedef PrivacyOptionsPresenter = Future<bool> Function();
typedef CanRequestAdsChecker = Future<bool> Function();
typedef BannerAdBuilder =
    BannerAd Function({
      required String adUnitId,
      required AdSize size,
      required AdRequest request,
      required BannerAdListener listener,
    });

/// Service to manage Google Mobile Ads consent and SDK lifecycle.
class AdService {
  AdService({
    @visibleForTesting
    Duration initializationDelay = const Duration(seconds: 15),
    @visibleForTesting bool? isAndroid,
    @visibleForTesting bool? isIOS,
    @visibleForTesting bool? isReleaseMode,
    @visibleForTesting ConsentGatherer? gatherConsent,
    @visibleForTesting MobileAdsInitializer? initializeMobileAds,
    @visibleForTesting PrivacyOptionsStatusChecker? checkPrivacyOptionsRequired,
    @visibleForTesting PrivacyOptionsPresenter? presentPrivacyOptionsForm,
    @visibleForTesting CanRequestAdsChecker? queryCanRequestAds,
    @visibleForTesting BannerAdBuilder? bannerAdBuilder,
  }) : _isAndroid = isAndroid ?? (!kIsWeb && Platform.isAndroid),
       _isIOS = isIOS ?? (!kIsWeb && Platform.isIOS),
       _isReleaseMode = isReleaseMode ?? kReleaseMode,
       _gatherConsent = gatherConsent ?? _defaultGatherConsent,
       _initializeMobileAds =
           initializeMobileAds ?? (() => MobileAds.instance.initialize()),
       _checkPrivacyOptionsRequired =
           checkPrivacyOptionsRequired ?? _defaultCheckPrivacyOptionsRequired,
       _presentPrivacyOptionsForm =
           presentPrivacyOptionsForm ?? _defaultPresentPrivacyOptionsForm,
       _queryCanRequestAds =
           queryCanRequestAds ??
           (() => ConsentInformation.instance.canRequestAds()),
       _bannerAdBuilder = bannerAdBuilder ?? _defaultBannerAdBuilder {
    // Defer Ad consent & SDK initialization to reduce startup pressure on mobile.
    _initializationFuture = _initialize(initializationDelay);
  }

  final bool _isAndroid;
  final bool _isIOS;
  final bool _isReleaseMode;
  final ConsentGatherer _gatherConsent;
  final MobileAdsInitializer _initializeMobileAds;
  final PrivacyOptionsStatusChecker _checkPrivacyOptionsRequired;
  final PrivacyOptionsPresenter _presentPrivacyOptionsForm;
  final CanRequestAdsChecker _queryCanRequestAds;
  final BannerAdBuilder _bannerAdBuilder;

  late final Future<InitializationStatus> _initializationFuture;
  final ValueNotifier<bool> _canRequestAdsNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _privacyOptionsRequiredNotifier =
      ValueNotifier<bool>(false);
  Future<InitializationStatus>? _sdkInitializationFuture;
  Future<bool>? _activePrivacyOptionsFuture;

  Future<InitializationStatus> get initialization => _initializationFuture;

  /// Whether Google Mobile Ads is supported on the current platform.
  bool get isMobileAdsSupported => !kIsWeb && (_isAndroid || _isIOS);

  /// Whether UMP consent allows requesting ads and SDK initialization succeeded.
  bool get canRequestAds => _canRequestAdsNotifier.value;

  /// Reactive consent/ad eligibility state for banner widgets and settings UI.
  ValueListenable<bool> get canRequestAdsListenable => _canRequestAdsNotifier;

  /// Whether UMP currently reports that a privacy options entry point is required.
  bool get privacyOptionsRequired => _privacyOptionsRequiredNotifier.value;

  /// Reactive privacy-options visibility state for the Settings screen.
  ValueListenable<bool> get privacyOptionsRequiredListenable =>
      _privacyOptionsRequiredNotifier;

  static const String _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidReleaseBannerAdUnitId =
      'ca-app-pub-3432071939645868/7074619663';
  static const String _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  Future<InitializationStatus> _ensureSdkInitialized() {
    final existing = _sdkInitializationFuture;
    if (existing != null) return existing;
    final future = _initializeMobileAds().catchError((Object e) {
      _sdkInitializationFuture = null;
      throw e;
    });
    _sdkInitializationFuture = future;
    return future;
  }

  Future<InitializationStatus> _initialize(Duration delay) async {
    if (!isMobileAdsSupported) {
      _canRequestAdsNotifier.value = false;
      _privacyOptionsRequiredNotifier.value = false;
      return InitializationStatus({});
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    try {
      final allowed = await _gatherConsent();
      _privacyOptionsRequiredNotifier.value = await isPrivacyOptionsRequired();
      if (!allowed) {
        _canRequestAdsNotifier.value = false;
        return InitializationStatus({});
      }
      final status = await _ensureSdkInitialized();
      _canRequestAdsNotifier.value = true;
      return status;
    } catch (e) {
      // Fail closed on offline / UMP / platform errors without throwing unhandled async errors.
      debugPrint('AdService: initialization failed: $e');
      _canRequestAdsNotifier.value = false;
      return InitializationStatus({});
    }
  }

  static Future<bool> _defaultGatherConsent() async {
    final updateCompleter = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!updateCompleter.isCompleted) updateCompleter.complete();
      },
      (FormError error) {
        debugPrint(
          'AdService: UMP consent info update failed (${error.errorCode}): ${error.message}',
        );
        if (!updateCompleter.isCompleted) updateCompleter.complete();
      },
    );
    await updateCompleter.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {},
    );

    final formCompleter = Completer<void>();
    await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (error != null) {
        debugPrint(
          'AdService: UMP consent form error (${error.errorCode}): ${error.message}',
        );
      }
      if (!formCompleter.isCompleted) formCompleter.complete();
    });
    await formCompleter.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {},
    );

    return ConsentInformation.instance.canRequestAds();
  }

  static Future<bool> _defaultCheckPrivacyOptionsRequired() async {
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  static Future<bool> _defaultPresentPrivacyOptionsForm() async {
    FormError? formError;
    final completer = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((FormError? error) {
      formError = error;
      if (error != null) {
        debugPrint(
          'AdService: privacy options form error (${error.errorCode}): ${error.message}',
        );
      }
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );
    return formError == null;
  }

  /// Whether a privacy options entry point is required by UMP (e.g. EEA/UK/US states).
  Future<bool> isPrivacyOptionsRequired() async {
    if (!isMobileAdsSupported) return false;
    try {
      final required = await _checkPrivacyOptionsRequired();
      _privacyOptionsRequiredNotifier.value = required;
      return required;
    } catch (e) {
      debugPrint('AdService: failed to check privacy options status: $e');
      return false;
    }
  }

  /// Refreshes ad request eligibility and privacy-options requirement status.
  Future<bool> refreshConsentStatus() async {
    if (!isMobileAdsSupported) {
      _canRequestAdsNotifier.value = false;
      _privacyOptionsRequiredNotifier.value = false;
      return false;
    }
    try {
      _privacyOptionsRequiredNotifier.value = await isPrivacyOptionsRequired();
      final allowed = await _queryCanRequestAds();
      if (allowed) {
        await _ensureSdkInitialized();
      }
      _canRequestAdsNotifier.value = allowed;
      return allowed;
    } catch (e) {
      debugPrint('AdService: failed to refresh consent status: $e');
      _canRequestAdsNotifier.value = false;
      return false;
    }
  }

  /// Displays the UMP privacy options form so users can update consent choices.
  ///
  /// Concurrent invocations coalesce onto the active request. Returns `true` if
  /// the form completed without a UMP error, or `false` if unavailable/failed.
  Future<bool> showPrivacyOptionsForm() {
    if (!isMobileAdsSupported) return Future<bool>.value(false);
    final active = _activePrivacyOptionsFuture;
    if (active != null) return active;

    final future = () async {
      try {
        final ok = await _presentPrivacyOptionsForm();
        await refreshConsentStatus();
        return ok;
      } catch (e) {
        debugPrint('AdService: failed to show privacy options form: $e');
        await refreshConsentStatus();
        return false;
      } finally {
        _activePrivacyOptionsFuture = null;
      }
    }();
    _activePrivacyOptionsFuture = future;
    return future;
  }

  static BannerAd _defaultBannerAdBuilder({
    required String adUnitId,
    required AdSize size,
    required AdRequest request,
    required BannerAdListener listener,
  }) {
    return BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: request,
      listener: listener,
    );
  }

  /// Get the banner ad unit ID based on the platform and build mode.
  /// Uses Google's test ad unit in debug/profile builds to comply with AdMob
  /// policies and the production Android ad unit in release builds.
  String get bannerAdUnitId {
    if (_isAndroid) {
      return _isReleaseMode
          ? _androidReleaseBannerAdUnitId
          : _androidTestBannerAdUnitId;
    } else if (_isIOS) {
      return _iosTestBannerAdUnitId;
    }
    return '';
  }

  /// Create a new banner ad.
  BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return _bannerAdBuilder(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  /// Returns a list of mock promotions for UI testing.
  List<Map<String, String>> getPromoData() {
    return [
      {
        'title': 'Premium Headphones',
        'subtitle': 'Experience pure sound with NoiseCancelling 3.0',
        'cta': 'Shop now',
        'image':
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200',
      },
      {
        'title': 'Artist Spotlight: Wavey',
        'subtitle': 'Check out the new album "Ocean Drift"',
        'cta': 'Listen',
        'image':
            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200',
      },
      {
        'title': 'Coffee & Lo-fi',
        'subtitle': 'Relax with our curated workstation playlist.',
        'cta': 'Explore',
        'image':
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=200',
      },
    ];
  }
}

final adServiceProvider = Provider<AdService>((ref) => AdService());
