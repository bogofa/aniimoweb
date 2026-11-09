import 'package:flutter/material.dart';

/// Google AdMob Policy requires that Rewarded Ads MUST be explicitly opted into
/// by the user before the video plays, clearly stating the reward they will earn.
class RewardOfferDialog extends StatelessWidget {
  final String triggerReason;
  final String? characterName;
  final int rewardMinutes;

  const RewardOfferDialog({
    super.key,
    required this.triggerReason,
    this.characterName,
    this.rewardMinutes = 30,
  });

  @override
  Widget build(BuildContext context) {
    final title = characterName != null && characterName!.isNotEmpty
        ? 'Unlock $characterName Pro Build Mode'
        : 'Unlock Aniimoplay Pro Mode';

    return Dialog(
      backgroundColor: const Color(0xFF141A17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2EE6A8), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2EE6A8).withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF2EE6A8),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Watch a short sponsored video to unlock $rewardMinutes minutes of Ad-Free browsing across all Aniidex characters, builds, and interactive maps!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFA2ABA6),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                label: Text(
                  'Watch Video & Unlock ($rewardMinutesm Free)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2EE6A8),
                  foregroundColor: const Color(0xFF0E1210),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'No thanks, continue with standard mode',
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
