# Aniimoplay Flutter App (iOS & Android) with AdMob SDK

This Flutter project wraps **`https://aniimoplay.com`** in a native iOS/Android shell with full **Google AdMob** monetization and **AdSense/AdMob policy compliance**.

## Key Features Built In
1. **Dedicated Bottom AdMob Banner Ad (`BannerAd`)**
   - Placed in a dedicated safe-area container below the `WebView` with a visual divider so it never overlaps web UI or causes accidental clicks.
2. **Interstitial Ad After Every 3 User Clicks (`InterstitialAd`)**
   - Tracks user link navigations inside the WebView and bottom tab switches, displaying an `InterstitialAd` every **3 clicks** (`AdConfig.clicksPerInterstitial = 3`), with a 45-second policy cooldown so AdMob never flags rapid repeat impressions.
3. **AdMob Policy-Compliant Rewarded Ad (`RewardedAd`)**
   - **Triggers automatically when:**
     - The user spends **40 seconds** in the app (`AdConfig.rewardedTimerSeconds = 40`), **OR**
     - The user **clicks on any Aniimo character** (`/aniidex/<character-slug>`).
   - **How it respects AdMob Policy:** Google AdMob strictly requires Rewarded Ads to be **opt-in** with a clear reward description before video playback. When triggered at 40 seconds or on a character click, the app displays the **Unlock Aniimoplay Pro Mode** dialog (`RewardOfferDialog`). When the user taps **"Watch Video & Unlock (30m Free)"**, the `RewardedAd` plays and grants **30 minutes of Ad-Free Pro Mode** (hiding Banner & Interstitial ads and showing a `PRO 30m` badge in the top bar).
4. **Rate App Pop-Up (`RateAppDialog` + `in_app_review`)**
   - Automatically prompts the user to rate the app on their 2nd session (and every 5th session if they tap *Maybe Later*), and can also be opened anytime via the gold **Star** icon in the top bar.
5. **Automatic Web AdSense Guard Integration**
   - Sends `User-Agent: AniimoplayApp/1.0 (Flutter; Mobile)` and `?app=ios`, which triggers the WebView guard on `aniimoplay.com` so web AdSense stays disabled inside the native app while AdMob serves the ads.

---

## How to Run & Build
1. Install the Flutter SDK if not yet installed (`brew install --cask flutter`), then initialize platform folders if needed:
   ```bash
   cd "/Users/macbookpro/Documents/Aniimo Website/aniimoplay_flutter_app"
   flutter create . --project-name aniimoplay_app
   flutter pub get
   ```
2. Run on iOS Simulator or connected iPhone:
   ```bash
   flutter run
   ```
3. **Before Submitting to the App Store / Google Play:**
   - Open `lib/config/ad_config.dart`, set `useTestAds = false`, and paste your real AdMob Banner, Interstitial, and Rewarded Ad Unit IDs (`ca-app-pub-6687779687898901/...`).
   - Replace the test `GADApplicationIdentifier` in `ios/Runner/Info.plist` and `com.google.android.gms.ads.APPLICATION_ID` in `android/app/src/main/AndroidManifest.xml` with your real AdMob App ID.
