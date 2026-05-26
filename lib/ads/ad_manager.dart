import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../secrets.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static String get _bannerAdUnitId =>
      kReleaseMode ? bannerAdUnitId : _testBannerAdUnitId;

  static String get _interstitialAdUnitId =>
      kReleaseMode ? interstitialAdUnitId : _testInterstitialAdUnitId;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;

  final ValueNotifier<bool> isBannerReady = ValueNotifier(false);

  BannerAd? get bannerAd => _bannerAd;

  Future<void> initialize() async {
    debugPrint('📢 AdManager.initialize(): calling MobileAds.instance.initialize()...');
    await MobileAds.instance.initialize();
    debugPrint('📢 AdManager.initialize(): MobileAds ready, loading ads...');
    _loadBannerAd();
    _loadInterstitialAd();
    debugPrint('📢 AdManager.initialize(): done');
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isBannerReady.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          isBannerReady.value = false;
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _isInterstitialReady = false;
    }
  }
}
