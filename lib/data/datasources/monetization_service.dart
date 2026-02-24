import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class MonetizationService {
  static final MonetizationService _instance = MonetizationService._internal();
  factory MonetizationService() => _instance;
  MonetizationService._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Real Ad Units would go here. For dev, we use test IDs.
  String get bannerAdUnitId => kDebugMode 
    ? (Platform.isAndroid ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/2934735716')
    : 'YOUR_REAL_BANNER_ID';

  String get interstitialAdUnitId => kDebugMode
    ? (Platform.isAndroid ? 'ca-app-pub-3940256099942544/1033173712' : 'ca-app-pub-3940256099942544/4411468910')
    : 'YOUR_REAL_INTERSTITIAL_ID';

  String get rewardedAdUnitId => kDebugMode
    ? (Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712485313')
    : 'YOUR_REAL_REWARDED_ID';

  // --- Banner Ads ---
  Future<BannerAd> createBannerAd() async {
    final ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint("Ad Loaded: ${ad.adUnitId}"),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("Ad Failed to Load: $error");
        },
      ),
    );
    await ad.load();
    return ad;
  }

  // --- Interstitial Ads ---
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd(); // Premature reload
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) => debugPrint("Interstitial failed: $err"),
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      loadInterstitialAd();
    }
  }

  // --- Rewarded Ads ---
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (err) => debugPrint("Rewarded failed: $err"),
      ),
    );
  }

  void showRewardedAd({required Function(RewardItem) onRewardEarned}) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewardedAd();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onRewardEarned(reward));
      _rewardedAd = null;
    } else {
      loadRewardedAd();
    }
  }
}
