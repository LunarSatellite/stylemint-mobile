import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, super.key});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(review.userAvatarUrl),
                onBackgroundImageError: (_, __) {},
                backgroundColor: DesignTokens.bgAppBodyLight,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: DesignTokens.mediumSemibold,
                    ),
                    const SizedBox(height: 2),
                    _StarRating(rating: review.rating, size: 14),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            Text(
              review.comment,
              style: DesignTokens.mediumRegular,
            ),
          ],
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.s8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                  child: Image.network(
                    review.images[i],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: DesignTokens.bgAppBodyLight,
                      child: const Icon(Icons.broken_image, color: DesignTokens.textMuted),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (review.helpfulCount > 0) ...[
            const SizedBox(height: DesignTokens.s8),
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, size: 14, color: DesignTokens.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${review.helpfulCount} found helpful',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, this.size = 16});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating) {
          return Icon(Icons.star, size: size, color: const Color(0xFFF1C40F));
        }
        return Icon(Icons.star_border, size: size, color: DesignTokens.textMuted);
      }),
    );
  }
}
