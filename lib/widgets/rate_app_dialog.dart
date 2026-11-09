import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ad_config.dart';

class RateAppDialog extends StatefulWidget {
  const RateAppDialog({super.key});

  static const String _prefKeyRated = 'aniimoplay_has_rated';
  static const String _prefKeyLaunchCount = 'aniimoplay_launch_count';

  /// Automatically checks on app session start if we should show the Rate popup
  static Future<void> checkAndShowIfAppropriate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRated = prefs.getBool(_prefKeyRated) ?? false;
    if (alreadyRated) return;

    final launches = (prefs.getInt(_prefKeyLaunchCount) ?? 0) + 1;
    await prefs.setInt(_prefKeyLaunchCount, launches);

    // Show on 2nd launch (or every 5 launches if dismissed with "Later")
    if (launches == 2 || (launches > 2 && launches % 5 == 0)) {
      if (!context.mounted) return;
      await show(context);
    }
  }

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const RateAppDialog(),
    );
  }

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog> {
  int _selectedStars = 5;
  bool _submitting = false;

  Future<void> _submitRating() async {
    setState(() => _submitting = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(RateAppDialog._prefKeyRated, true);

    final inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing(appStoreId: AdConfig.iosAppStoreId);
      }
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF15241D),
          content: Text(
            'Thank you for supporting Aniimoplay!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141A17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFCCC06).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFFCCC06),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Enjoying Aniimoplay?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your 5-star rating helps other Pathfinders discover our Aniidex, Tier List, and Interactive Map!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA2ABA6),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                final isSelected = starNumber <= _selectedStars;
                return IconButton(
                  onPressed: () => setState(() => _selectedStars = starNumber),
                  iconSize: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected
                        ? const Color(0xFFFCCC06)
                        : const Color(0xFF5A635E),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2EE6A8),
                  foregroundColor: const Color(0xFF0E1210),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Rate Aniimoplay Now',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  color: Color(0xFF7B8580),
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
