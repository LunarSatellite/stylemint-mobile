import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// Read-only pieces of a rider's ratings, shared by the vendor's rider
// details, the rider's own summary and a submitted rating.

/// Five stars, [stars] of them filled.
class RiderStarRow extends StatelessWidget {
  const RiderStarRow({required this.stars, this.size = 16, super.key});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars out of 5 stars',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= stars
                ? DesignTokens.secondaryYellow
                : DesignTokens.textMuted,
          ),
      ],
    ),
  );
}

/// Small read-only chips, optionally with how often each was given.
class RiderTagChipsView extends StatelessWidget {
  const RiderTagChipsView({required this.labels, super.key});

  RiderTagChipsView.tags(List<RiderRatingTag> tags, {super.key})
    : labels = [for (final tag in tags) tag.label];

  RiderTagChipsView.counts(List<RiderTagCount> counts, {super.key})
    : labels = [
        for (final c in counts)
          c.count > 0 ? '${c.tag.label} · ${c.count}' : c.tag.label,
      ];

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: DesignTokens.s6,
      runSpacing: DesignTokens.s6,
      children: [
        for (final label in labels)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.chipsSelectedFill,
              borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
            ),
            child: Text(
              label,
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ),
      ],
    );
  }
}

/// The average (or "New rider"), how many ratings, a bar per star count and
/// the most-given tags.
class RiderRatingSummaryView extends StatelessWidget {
  const RiderRatingSummaryView({required this.summary, super.key});

  final RiderRatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final average = summary.average;
    final count = summary.count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  average == null ? 'New rider' : average.toStringAsFixed(1),
                  style: average == null
                      ? DesignTokens.h3
                      : DesignTokens.h1.copyWith(height: 1.1),
                ),
                if (average != null)
                  RiderStarRow(stars: average.round(), size: 14),
                Text(
                  count == 1 ? '1 rating' : '$count ratings',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: DesignTokens.s16),
            if (summary.breakdown.isNotEmpty)
              Expanded(child: RiderRatingBreakdown(summary: summary)),
          ],
        ),
        if (average == null && count > 0) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            'An average shows from 3 ratings.',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ],
        if (summary.topTags.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s12),
          RiderTagChipsView.counts(summary.topTags),
        ],
      ],
    );
  }
}

/// One bar per star count, 5 down to 1, scaled to the largest.
class RiderRatingBreakdown extends StatelessWidget {
  const RiderRatingBreakdown({required this.summary, super.key});

  final RiderRatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final largest = summary.largestBucket;
    return Column(
      children: [
        for (var stars = 5; stars >= 1; stars--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  child: Text('$stars', style: DesignTokens.tiny),
                ),
                const Icon(
                  Icons.star_rounded,
                  size: 11,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(width: DesignTokens.s4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: largest == 0
                          ? 0
                          : (summary.breakdown[stars] ?? 0) / largest,
                      minHeight: 6,
                      backgroundColor: DesignTokens.bgAppBodyLight,
                      color: DesignTokens.secondaryYellow,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s6),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${summary.breakdown[stars] ?? 0}',
                    textAlign: TextAlign.end,
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A review without its author: stars, tags, the comment and how long ago.
class RiderReviewTile extends StatelessWidget {
  const RiderReviewTile({required this.review, super.key});

  final RiderReview review;

  @override
  Widget build(BuildContext context) {
    final age = review.ageLabel;
    final from = switch (review.raterRole) {
      RiderRaterRole.buyer => 'Buyer',
      RiderRaterRole.vendor => 'Seller',
      null => null,
    };
    final meta = [?from, ?age].join(' · ');
    final comment = review.comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RiderStarRow(stars: review.stars, size: 14),
              const SizedBox(width: DesignTokens.s8),
              if (meta.isNotEmpty)
                Expanded(
                  child: Text(
                    meta,
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            RiderTagChipsView.tags(review.tags),
          ],
          if (comment != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(comment, style: DesignTokens.smallRegular),
          ],
        ],
      ),
    );
  }
}
