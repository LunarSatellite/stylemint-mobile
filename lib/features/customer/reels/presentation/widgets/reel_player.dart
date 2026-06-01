import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders the reel thumbnail and, on tap, opens the source in the external
/// app (Instagram / TikTok / YouTube / Facebook). The app never embeds a
/// player — reels are pointer records only.
class ReelPlayer extends StatelessWidget {
  const ReelPlayer({required this.reel, super.key});

  final Reel reel;

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(reel.sourceUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openExternal,
      child: ColoredBox(
        color: DesignTokens.baseBlack,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (reel.thumbnailUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: reel.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder:
                    (_, _) => const ColoredBox(
                      color: DesignTokens.bgAppBodyLight,
                    ),
                errorWidget:
                    (_, _, _) => const ColoredBox(
                      color: DesignTokens.bgAppBodyLight,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: DesignTokens.iconLight,
                      ),
                    ),
              ),
            // Play affordance — taps open the external app.
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.baseBlack.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.all(DesignTokens.s16),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: DesignTokens.iconLarge,
                  color: DesignTokens.iconWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
