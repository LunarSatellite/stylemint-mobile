import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ImportableReelCard extends StatelessWidget {
  const ImportableReelCard({
    super.key,
    required this.reel,
    required this.onTap,
    this.isSelected = false,
    this.isSelectMode = false,
  });

  final ImportableReel reel;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectMode;

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
                  // Selection overlay
                  if (isSelectMode)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DesignTokens.primaryGreen
                                  .withValues(alpha: 0.35)
                              : Colors.transparent,
                          border: isSelected
                              ? Border.all(
                                  color: DesignTokens.primaryGreen,
                                  width: 2,
                                )
                              : null,
                        ),
                      ),
                    ),
                  if (isSelectMode)
                    Positioned(
                      top: DesignTokens.s6,
                      right: DesignTokens.s6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? DesignTokens.primaryGreen
                              : DesignTokens.baseBlack.withValues(alpha: 0.5),
                          border: Border.all(
                            color: isSelected
                                ? DesignTokens.primaryGreen
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.black)
                            : null,
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
