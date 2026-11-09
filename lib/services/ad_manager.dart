import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';
import '../widgets/reward_offer_dialog.dart';

class AdManager extends ChangeNotifier {
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShownAt;
  int _userClickCount = 0;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;
  bool _hasShownRewardPromptThisSession = false;
  DateTime? _adFreeUntil;

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerLoaded => _isBannerLoaded && !isAdFreeActive;
  bool get isRewardedReady => _rewardedAd != null;
  int get userClickCount => _userClickCount;

  bool get isAdFreeActive {
    if (_adFreeUntil == null) return false;
    return DateTime.now().isBefore(_adFreeUntil!);
  }

  int get remainingAdFreeMinutes {
    if (!isAdFreeActive) return 0;
    return _adFreeUntil!.difference(DateTime.now()).inMinutes + 1;
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadBannerAd();
    loadInterstitialAd();
    loadRewardedAd();
  }

  // ---------------------------------------------------------------------------
  // 1. BANNER AD
  // ---------------------------------------------------------------------------
  void loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
          _bannerAd = null;
          notifyListeners();
        },
      ),
    )..load();
  }

  // ---------------------------------------------------------------------------
  // 2. INTERSTITIAL AD (Every 3 User Clicks + Policy Cooldown)
  // ---------------------------------------------------------------------------
  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Records a natural user navigation click and shows an Interstitial Ad
  /// on every 3rd click (respecting AdMob cooldown & Ad-Free reward state).
  void registerUserClick(BuildContext context) {
    if (isAdFreeActive) return;

    _userClickCount++;
    notifyListeners();

    if (_userClickCount >= AdConfig.clicksPerInterstitial) {
      final now = DateTime.now();
      final cooldownPassed = _lastInterstitialShownAt == null ||
          now.difference(_lastInterstitialShownAt!).inSeconds >=
              AdConfig.interstitialCooldownSeconds;

      if (_interstitialAd != null && cooldownPassed) {
        _userClickCount = 0;
        _lastInterstitialShownAt = now;
        final ad = _interstitialAd!;
        _interstitialAd = null;

        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            loadInterstitialAd();
          },
        );
        ad.show();
      } else {
        // Keep preloading if not ready yet
        loadInterstitialAd();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 3. REWARDED AD (40s Timer OR Character Click — Policy-Compliant Opt-In)
  // ---------------------------------------------------------------------------
  void loadRewardedAd() {
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoading = false;
          notifyListeners();
        },
      ),
    );
  }

  /// Triggers the AdMob policy-compliant opt-in Rewarded Ad dialog
  /// either after 40 seconds in the app OR when clicking an Aniimo character.
  Future<void> triggerRewardOfferIfEligible(
    BuildContext context, {
    required String triggerReason,
    String? characterName,
    bool forceShow = false,
  }) async {
    if (!forceShow) {
      if (_hasShownRewardPromptThisSession || isAdFreeActive) return;
    }
    if (_rewardedAd == null) {
      loadRewardedAd();
      return;
    }

    _hasShownRewardPromptThisSession = true;

    if (!context.mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RewardOfferDialog(
        triggerReason: triggerReason,
        characterName: characterName,
        rewardMinutes: AdConfig.rewardAdFreeMinutes,
      ),
    );

    if (accepted == true && _rewardedAd != null) {
      showRewardedAd(
        onRewardEarned: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF15241D),
                content: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF2EE6A8)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pro Mode Unlocked! Enjoy 30 minutes of Ad-Free browsing & builds.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    }
  }

  void showRewardedAd({required VoidCallback onRewardEarned}) {
    if (_rewardedAd == null) {
      loadRewardedAd();
      return;
    }
    final ad = _rewardedAd!;
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _adFreeUntil = DateTime.now().add(
          const Duration(minutes: AdConfig.rewardAdFreeMinutes),
        );
        notifyListeners();
        onRewardEarned();
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}
