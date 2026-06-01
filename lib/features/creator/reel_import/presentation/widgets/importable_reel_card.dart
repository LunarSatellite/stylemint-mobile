import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ImportableReelCard extends StatelessWidget {
  const ImportableReelCard({super.key, required this.reel, required this.onTap});

  final ImportableReel reel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          color: DesignTokens.bgAppBody,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: DesignTokens.bgAppBodyLight),
                  if (reel.thumbnailUrl.isNotEmpty)
                    Image.network(
                      reel.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: DesignTokens.bgAppBodyLight,
                        child: const Icon(Icons.play_circle_outline,
                            color: DesignTokens.textMuted),
                      ),
                    ),
                  Positioned(
                    right: DesignTokens.s4,
                    bottom: DesignTokens.s4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s6,
                        vertical: DesignTokens.s4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.baseBlack.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(DesignTokens.s4),
                      ),
                      child: Text(
                        _formatDuration(reel.videoDuration),
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s8),
              child: Text(
                reel.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.smallRegular,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }
}
