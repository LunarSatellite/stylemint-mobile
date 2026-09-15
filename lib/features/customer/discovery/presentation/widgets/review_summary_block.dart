import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_review_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/product_page_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The review summary above the product page's review tabs, from
/// `GET /v1/public/products/{id}/reviews/summary`. Hidden while loading or
/// when it can't be read.
class ReviewSummaryBlock extends ConsumerWidget {
  const ReviewSummaryBlock({
    required this.productId,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final String productId;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref
        .watch(productReviewSummaryProvider(productId))
        .asData
        ?.value;
    if (summary == null) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: ReviewSummaryView(
        summary: summary,
        onWithPhotosTap: () => unawaited(
          context.push(
            RouteNames.productReviews.replaceFirst(':productId', productId),
          ),
        ),
      ),
    );
  }
}

/// Big average, review count, 5 → 1 distribution bars and a "With photos"
/// chip; "No reviews yet" when nothing is reviewed.
class ReviewSummaryView extends StatelessWidget {
  const ReviewSummaryView({
    required this.summary,
    super.key,
    this.onWithPhotosTap,
  });

  static const String noReviewsLabel = 'No reviews yet';

  static String withPhotosLabel(int count) => 'With photos ($count)';

  /// Key of the filled part of the [stars] bar.
  static Key barKey(int stars) => ValueKey('review-summary-bar-$stars');

  final ProductReviewSummary summary;
  final VoidCallback? onWithPhotosTap;

  static const TextStyle _mutedStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: DesignTokens.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    if (summary.reviewCount <= 0) {
      return const Text(noReviewsLabel, style: _mutedStyle);
    }
    final hasRatings = summary.ratingCount > 0;
    final average = summary.averageRating.toStringAsFixed(1);
    final reviews = summary.reviewCount == 1
        ? '1 review'
        : '${summary.reviewCount} reviews';
    final photos = summary.withPhotosCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          excludeSemantics: true,
          label: hasRatings
              ? 'Rated $average out of 5, $reviews'
              : 'No star ratings, $reviews',
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        hasRatings ? average : '–',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    _Stars(rating: summary.averageRating),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      reviews,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _mutedStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s16),
              Expanded(
                child: Column(
                  children: [
                    for (var stars = 5; stars >= 1; stars--)
                      _DistributionRow(
                        stars: stars,
                        count: summary.countFor(stars),
                        share: summary.shareFor(stars),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (photos > 0) ...[
          const SizedBox(height: DesignTokens.s12),
          _WithPhotosChip(
            label: withPhotosLabel(photos),
            onTap: onWithPhotosTap,
          ),
        ],
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          rating >= i - 0.25
              ? Icons.star_rounded
              : rating >= i - 0.75
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: 14,
          color: DesignTokens.secondaryYellow,
        ),
    ],
  );
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.stars,
    required this.count,
    required this.share,
  });

  final int stars;
  final int count;
  final double share;

  static String _compact(int count) => count < 1000
      ? '$count'
      : '${(count / 1000).toStringAsFixed(count < 10000 ? 1 : 0)}k';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text('$stars', style: ReviewSummaryView._mutedStyle),
        const SizedBox(width: 2),
        const Icon(Icons.star_rounded, size: 12, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: ColoredBox(
                color: DesignTokens.borderDefault,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    key: ReviewSummaryView.barKey(stars),
                    widthFactor: share.clamp(0, 1).toDouble(),
                    heightFactor: 1,
                    child: const ColoredBox(
                      color: DesignTokens.secondaryYellow,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s6),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 22),
          child: Text(
            _compact(count),
            textAlign: TextAlign.end,
            style: ReviewSummaryView._mutedStyle,
          ),
        ),
      ],
    ),
  );
}

class _WithPhotosChip extends StatelessWidget {
  const _WithPhotosChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s12,
            vertical: DesignTokens.s6,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: DesignTokens.borderDefault),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                size: 14,
                color: DesignTokens.textLight,
              ),
              const SizedBox(width: DesignTokens.s6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: DesignTokens.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
