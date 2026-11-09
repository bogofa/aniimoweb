import 'dart:io';

/// Centralized AdMob & App Configuration for Aniimo Builder For Companion.
class AdConfig {
  /// Set to false for production release builds with real AdMob ads
  static const bool useTestAds = false;

  static const String siteBaseUrl = 'https://aniimoplay.com';
  static const String customUserAgent = 'AniimoBuilderCompanion/1.0 (iOS; Mobile)';

  // Apple App Store ID for App Store Connect & Rate App Pop-up
  static const String iosAppStoreId = '6832640485';

  // --- PRODUCTION ADMOB AD UNIT IDs (iOS) ---
  // Publisher ID: pub-6687779687898901
  static const String _prodIosBannerId = 'ca-app-pub-6687779687898901/1451496583';
  static const String _prodIosInterstitialId = 'ca-app-pub-6687779687898901/4572483941';
  static const String _prodIosRewardedId = 'ca-app-pub-6687779687898901/9516854718';

  // Fallback Android IDs
  static const String _prodAndroidBannerId = 'ca-app-pub-6687779687898901/1451496583';
  static const String _prodAndroidInterstitialId = 'ca-app-pub-6687779687898901/4572483941';
  static const String _prodAndroidRewardedId = 'ca-app-pub-6687779687898901/9516854718';

  // --- GOOGLE OFFICIAL TEST AD UNIT IDs (Used if useTestAds == true) ---
  static String get bannerAdUnitId {
    if (useTestAds) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    return Platform.isIOS ? _prodIosBannerId : _prodAndroidBannerId;
  }

  static String get interstitialAdUnitId {
    if (useTestAds) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-3940256099942544/1033173712';
    }
    return Platform.isIOS ? _prodIosInterstitialId : _prodAndroidInterstitialId;
  }

  static String get rewardedAdUnitId {
    if (useTestAds) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    return Platform.isIOS ? _prodIosRewardedId : _prodAndroidRewardedId;
  }

  // --- TRIGGER & FREQUENCY CAP RULES (ADMOB POLICY COMPLIANT) ---
  /// Show Interstitial Ad after every 3 user navigation clicks
  static const int clicksPerInterstitial = 3;

  /// Minimum cooldown between interstitial ads to comply with AdMob policy
  static const int interstitialCooldownSeconds = 45;

  /// Trigger Rewarded Ad opt-in prompt after 40 seconds in the app
  static const int rewardedTimerSeconds = 40;

  /// Duration of Ad-Free Pro Mode granted when user completes a Rewarded Ad
  static const int rewardAdFreeMinutes = 30;
}
