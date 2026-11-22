import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ad_service.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  late final AdService _adService;
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _adService = ref.read(adServiceProvider);
    if (_adService.isMobileAdsSupported) {
      _adService.canRequestAdsListenable.addListener(_onConsentChanged);
      unawaited(_loadAd());
    }
  }

  void _onConsentChanged() {
    if (!mounted) return;
    if (!_adService.canRequestAds) {
      final ad = _bannerAd;
      _bannerAd = null;
      if (_isLoaded) {
        setState(() {
          _isLoaded = false;
        });
      }
      ad?.dispose();
    } else if (_bannerAd == null) {
      unawaited(_loadAd());
    }
  }

  Future<void> _loadAd() async {
    if (!_adService.isMobileAdsSupported) return;

    // Wait for deferred UMP consent + SDK initialization to complete.
    try {
      await _adService.initialization;
    } catch (e) {
      debugPrint('BannerAdWidget: Ad initialization failed: $e');
      return;
    }

    if (!mounted ||
        _bannerAd != null ||
        !_adService.canRequestAds ||
        _adService.bannerAdUnitId.isEmpty) {
      return;
    }

    late final BannerAd ad;
    ad = _adService.createBannerAd(
      onAdLoaded: (loadedAd) {
        if (!mounted ||
            !identical(_bannerAd, ad) ||
            !_adService.canRequestAds) {
          loadedAd.dispose();
          if (identical(_bannerAd, ad)) {
            _bannerAd = null;
          }
          return;
        }
        setState(() {
          _isLoaded = true;
        });
      },
      onAdFailedToLoad: (failedAd, error) {
        if (identical(_bannerAd, ad)) {
          _bannerAd = null;
          if (mounted && _isLoaded) {
            setState(() {
              _isLoaded = false;
            });
          } else {
            _isLoaded = false;
          }
        }
        failedAd.dispose();
      },
    );
    _bannerAd = ad;
    try {
      await ad.load();
    } catch (e) {
      debugPrint('BannerAdWidget: Banner load failed: $e');
      if (identical(_bannerAd, ad)) {
        _bannerAd = null;
      }
      await ad.dispose();
    }
  }

  @override
  void dispose() {
    _adService.canRequestAdsListenable.removeListener(_onConsentChanged);
    final ad = _bannerAd;
    _bannerAd = null;
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
