import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'config/ad_config.dart';
import 'services/ad_manager.dart';
import 'widgets/rate_app_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final adManager = AdManager();
  await adManager.initialize();
  runApp(AniimoplayApp(adManager: adManager));
}

class AniimoplayApp extends StatelessWidget {
  final AdManager adManager;

  const AniimoplayApp({super.key, required this.adManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aniimo Builder For Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E1210),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2EE6A8),
          secondary: Color(0xFF2EE6A8),
          surface: Color(0xFF141A17),
        ),
      ),
      home: AniimoplayHomeScreen(adManager: adManager),
    );
  }
}

class AniimoplayHomeScreen extends StatefulWidget {
  final AdManager adManager;

  const AniimoplayHomeScreen({super.key, required this.adManager});

  @override
  State<AniimoplayHomeScreen> createState() => _AniimoplayHomeScreenState();
}

class _AniimoplayHomeScreenState extends State<AniimoplayHomeScreen> {
  late final WebViewController _webController;
  Timer? _fortySecondRewardTimer;
  int _selectedTabIndex = 0;
  double _loadingProgress = 0.0;
  bool _isInitialLoad = true;

  static const List<_NavTab> _tabs = [
    _NavTab(label: 'Home', icon: Icons.home_rounded, path: '/'),
    _NavTab(label: 'Aniidex', icon: Icons.catching_pokemon_rounded, path: '/aniidex'),
    _NavTab(label: 'Tier List', icon: Icons.leaderboard_rounded, path: '/tier-list'),
    _NavTab(label: 'Map', icon: Icons.map_rounded, path: '/interactive-map'),
    _NavTab(label: 'Builder', icon: Icons.groups_rounded, path: '/team-builder'),
    _NavTab(label: 'Codes', icon: Icons.card_giftcard_rounded, path: '/codes'),
  ];

  @override
  void initState() {
    super.initState();
    widget.adManager.addListener(_onAdStateChanged);
    _initWebView();
    _startFortySecondRewardTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      RateAppDialog.checkAndShowIfAppropriate(context);
    });
  }

  void _onAdStateChanged() {
    if (mounted) setState(() {});
  }

  /// Starts the 40-second engagement timer to show the AdMob policy-compliant
  /// Rewarded Ad offer if the user hasn't already triggered it by clicking a character.
  void _startFortySecondRewardTimer() {
    _fortySecondRewardTimer = Timer(
      const Duration(seconds: AdConfig.rewardedTimerSeconds),
      () {
        if (!mounted) return;
        widget.adManager.triggerRewardOfferIfEligible(
          context,
          triggerReason: '40s_timer',
        );
      },
    );
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0E1210))
      ..setUserAgent(AdConfig.customUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress / 100.0);
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 1.0;
                _isInitialLoad = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            // Open external links (Discord, Lootbar, X, YouTube) in external browser
            if (!uri.host.contains('aniimoplay.com') &&
                !uri.host.contains('localhost')) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }

            // Ignore initial page load for click counting
            if (!_isInitialLoad && request.isMainFrame) {
              // 1. Check if user clicked on an Aniimo character page: /aniidex/<slug>
              final characterSlug = _extractAniimoCharacterSlug(uri.path);
              if (characterSlug != null) {
                final formattedName = characterSlug
                    .split('-')
                    .map((w) => w.isEmpty
                        ? ''
                        : '${w[0].toUpperCase()}${w.substring(1)}')
                    .join(' ');
                // Trigger Rewarded Ad opt-in prompt when user clicks a character!
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    widget.adManager.triggerRewardOfferIfEligible(
                      context,
                      triggerReason: 'character_click',
                      characterName: formattedName,
                    );
                  }
                });
              } else {
                // 2. Count user navigation click toward the 3-click Interstitial Ad rule
                widget.adManager.registerUserClick(context);
              }

              _syncBottomTabFromPath(uri.path);
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('${AdConfig.siteBaseUrl}/?app=ios'));
  }

  /// Returns the creature slug if [path] is an individual character page
  /// e.g. `/aniidex/ignitis` or `/aniidex/ignitis/build`
  String? _extractAniimoCharacterSlug(String path) {
    final clean = path.replaceAll(RegExp(r'^/(fr|de|es|pt)(/|$)'), '/');
    final segments =
        clean.split('/').where((s) => s.trim().isNotEmpty).toList();
    if (segments.length >= 2 &&
        segments[0] == 'aniidex' &&
        segments[1] != 'compare') {
      return segments[1];
    }
    return null;
  }

  void _syncBottomTabFromPath(String path) {
    for (int i = 0; i < _tabs.length; i++) {
      final tPath = _tabs[i].path;
      if (tPath == '/' && (path == '/' || path.isEmpty)) {
        setState(() => _selectedTabIndex = 0);
        return;
      } else if (tPath != '/' && path.startsWith(tPath)) {
        setState(() => _selectedTabIndex = i);
        return;
      }
    }
  }

  void _onBottomTabTapped(int index) {
    setState(() => _selectedTabIndex = index);
    widget.adManager.registerUserClick(context);
    final targetUrl = '${AdConfig.siteBaseUrl}${_tabs[index].path}';
    _webController.loadRequest(Uri.parse(targetUrl));
  }

  @override
  void dispose() {
    _fortySecondRewardTimer?.cancel();
    widget.adManager.removeListener(_onAdStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF141A17),
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            const Text(
              'ANIIMO',
              style: TextStyle(
                color: Color(0xFF2EE6A8),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                fontSize: 18,
              ),
            ),
            const Text(
              'PLAY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.adManager.isAdFreeActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EE6A8).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF2EE6A8).withOpacity(0.5)),
                ),
                child: Text(
                  'PRO ${widget.adManager.remainingAdFreeMinutes}m',
                  style: const TextStyle(
                    color: Color(0xFF2EE6A8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () async {
              if (await _webController.canGoBack()) {
                await _webController.goBack();
              }
            },
          ),
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => _webController.reload(),
          ),
          if (!widget.adManager.isAdFreeActive)
            IconButton(
              tooltip: 'Unlock Ad-Free Pro Mode',
              icon: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF2EE6A8),
                size: 22,
              ),
              onPressed: () {
                widget.adManager.triggerRewardOfferIfEligible(
                  context,
                  triggerReason: 'manual_button',
                  forceShow: true,
                );
              },
            ),
          IconButton(
            tooltip: 'Rate Aniimoplay',
            icon: const Icon(
              Icons.star_rounded,
              color: Color(0xFFFCCC06),
              size: 22,
            ),
            onPressed: () => RateAppDialog.show(context),
          ),
        ],
        bottom: _loadingProgress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2.5),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF2EE6A8)),
                ),
              )
            : null,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Main WebView Content
            Expanded(
              child: WebViewWidget(controller: _webController),
            ),

            // AdMob Policy-Compliant Dedicated Banner Container
            // Separated by a clear border and never overlapping interactive content
            if (widget.adManager.isBannerLoaded &&
                widget.adManager.bannerAd != null)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF0E1210),
                  border: Border(
                    top: BorderSide(color: Color(0xFF232C27), width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                child: SizedBox(
                  width: widget.adManager.bannerAd!.size.width.toDouble(),
                  height: widget.adManager.bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: widget.adManager.bannerAd!),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onBottomTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF141A17),
        selectedItemColor: const Color(0xFF2EE6A8),
        unselectedItemColor: const Color(0xFF8C9690),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: _tabs
            .map(
              (t) => BottomNavigationBarItem(
                icon: Icon(t.icon, size: 21),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final String path;

  const _NavTab({
    required this.label,
    required this.icon,
    required this.path,
  });
}
