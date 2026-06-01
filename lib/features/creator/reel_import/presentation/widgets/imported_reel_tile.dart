import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ImportedReelTile extends StatelessWidget {
  const ImportedReelTile({super.key, required this.reel});

  final ImportedReel reel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: Image.network(
              reel.thumbnailUrl,
              width: 60,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 80,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(Icons.image, color: DesignTokens.textMuted),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reel.caption.isNotEmpty ? reel.caption : 'Untitled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.oneLinerSemibold,
                ),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  children: [
                    _StatusBadge(status: reel.status),
                    const SizedBox(width: DesignTokens.s8),
                    Text(
                      _formatDate(reel.importedAt),
                      style: DesignTokens.tiny,
                    ),
                  ],
                ),
                if (reel.tags.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '${reel.tags.length} products tagged',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(reel.platform.icon, color: reel.platform.color, size: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ImportStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      ImportStatus.pending => (
        DesignTokens.warning300.withValues(alpha: 0.2),
        DesignTokens.warning500,
        'Pending',
      ),
      ImportStatus.processing => (
        DesignTokens.statusOngoingBg,
        DesignTokens.statusOngoingIcon,
        'Processing',
      ),
      ImportStatus.live => (
        DesignTokens.statusCompletedBg,
        DesignTokens.statusCompletedIcon,
        'Live',
      ),
      ImportStatus.flagged => (
        DesignTokens.colorError.withValues(alpha: 0.15),
        DesignTokens.colorError,
        'Flagged',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Text(
        label,
        style: DesignTokens.tiny.copyWith(color: fg),
      ),
    );
  }
}
