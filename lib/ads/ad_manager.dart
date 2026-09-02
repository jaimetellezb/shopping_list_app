import 'dart:async';
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
  bool _adsInitialized = false;
  int _bannerWidth = 0;

  final ValueNotifier<bool> isBannerReady = ValueNotifier(false);

  BannerAd? get bannerAd => _bannerAd;
  Future<void> initialize() async {
    await _requestConsentIfRequired();
    if (!await _canRequestAds()) {
      return;
    }
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      return;
    }
    _adsInitialized = true;
    _loadInterstitialAd();
  }

  /// Flujo UMP (incluido en google_mobile_ads): pide estado de
  /// consentimiento y muestra el formulario solo si está disponible.
  /// Nunca bloquea los anuncios: cualquier fallo cae al flujo anterior.
  Future<void> _requestConsentIfRequired() async {
    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            if (await ConsentInformation.instance.isConsentFormAvailable()) {
              await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
            }
          } catch (_) {
            // Sin formulario: se continúa sin consentimiento explícito.
          }
          if (!done.isCompleted) done.complete();
        },
        (_) {
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
    } catch (_) {
      // Sin UMP disponible (tests, plataforma no soportada).
    }
  }

  Future<bool> _canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return true;
    }
  }

  /// Carga un banner adaptativo anclado para el ancho dado.
  /// Se ignora si los ads no están inicializados o el ancho no cambió.
  Future<void> loadAnchoredAdaptiveBanner(int width) async {
    if (!_adsInitialized || width <= 0 || width == _bannerWidth) return;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null) return;
    _bannerWidth = width;
    _bannerAd?.dispose();
    _bannerAd = null;
    isBannerReady.value = false;
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isBannerReady.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          _bannerWidth = 0;
          isBannerReady.value = false;
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
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

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
