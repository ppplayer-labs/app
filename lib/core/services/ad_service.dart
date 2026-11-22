import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Advertising service temporarily disabled for the ads-free v4.0.2 release
/// while AdMob app verification is pending.
///
/// The full Google Mobile Ads + UMP consent implementation is preserved in Git
/// history (commit `9a211e86f6abf8ade1609edee8d2004cfc8bfc34`) and can be
/// restored in a subsequent validated release once verification and GDPR/UMP
/// consent configuration are complete.
class AdService {
  AdService();

  static final Future<void> _completedInitialization = Future<void>.value();
  final ValueNotifier<bool> _canRequestAdsNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _privacyOptionsRequiredNotifier =
      ValueNotifier<bool>(false);

  /// Whether advertising is enabled in this build.
  bool get isAdsEnabled => false;

  /// Always completes immediately without scheduling timers or SDK calls.
  Future<void> get initialization => _completedInitialization;

  /// Always false in the temporary ads-free release.
  bool get isMobileAdsSupported => false;

  /// Always false in the temporary ads-free release.
  bool get canRequestAds => false;

  /// Reactive ad-request eligibility (always false in this release).
  ValueListenable<bool> get canRequestAdsListenable => _canRequestAdsNotifier;

  /// Always false in the temporary ads-free release.
  bool get privacyOptionsRequired => false;

  /// Reactive privacy-options visibility (always false in this release).
  ValueListenable<bool> get privacyOptionsRequiredListenable =>
      _privacyOptionsRequiredNotifier;

  /// Always empty in the temporary ads-free release.
  String get bannerAdUnitId => '';

  Future<bool> isPrivacyOptionsRequired() => Future<bool>.value(false);

  Future<bool> refreshConsentStatus() => Future<bool>.value(false);

  Future<bool> showPrivacyOptionsForm() => Future<bool>.value(false);

  List<Map<String, String>> getPromoData() => const [];
}

final adServiceProvider = Provider<AdService>((ref) => AdService());
