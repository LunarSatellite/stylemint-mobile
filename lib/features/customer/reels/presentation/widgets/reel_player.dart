import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

/// Reel player widget - displays reel background image and opens external app on tap
/// Never embeds video player. Tapping opens the reel in IG/TikTok/YouTube/FB native apps
class ReelPlayer extends StatelessWidget {
  final Reel reel;

  const ReelPlayer({
    Key? key,
    required this.reel,
  }) : super(key: key);

  Future<void> _openReelExternal() async {
    final url = reel.sourceUrl; // Deep link to IG/TikTok/YouTube/FB
    if (url.isNotEmpty) {
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint('Failed to open reel: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openReelExternal,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video background (placeholder image from reel)
            if (reel.thumbnailUrl.isNotEmpty)
              Image.network(
                reel.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),

            // Play indicator overlay
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.8),
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.play_arrow,
                  size: 40,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
