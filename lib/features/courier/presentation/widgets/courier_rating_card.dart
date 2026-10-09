import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/presentation/widgets/rider_rating_views.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Your rating": what buyers and sellers said about this rider — the
/// average (or "New rider"), how many ratings, the breakdown, the tags
/// given most and the latest comments, without who gave them.
///
/// From `GET /v1/courier/me/rating`. Renders nothing while it loads, on a
/// 404 (a backend without ratings) or on any failure: it is a record, not
/// something the rider has to act on.
class CourierRatingCard extends ConsumerWidget {
  const CourierRatingCard({
    this.recentShown = 3,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  /// How many recent reviews to list; the endpoint sends up to ten.
  final int recentShown;

  /// Around the card only when it is drawn, so an absent card leaves no gap.
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(courierMyRatingProvider).value;
    if (overview == null) return const SizedBox.shrink();
    return Padding(
      padding: margin,
      child: CourierRatingSummary(
        overview: overview,
        recentShown: recentShown,
      ),
    );
  }
}

/// The card's body, separate so it can be drawn from a value.
class CourierRatingSummary extends StatelessWidget {
  const CourierRatingSummary({
    required this.overview,
    this.recentShown = 3,
    super.key,
  });

  final CourierRatingOverview overview;
  final int recentShown;

  @override
  Widget build(BuildContext context) {
    final summary = overview.summary;
    final recent = overview.recent.take(recentShown).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Your rating', style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.s12),
          if (summary.count == 0)
            // Nobody has rated yet: say so, rather than draw five empty bars.
            Text(
              'No ratings yet. Buyers and sellers can rate you after a '
              'delivery or a pickup.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            )
          else
            RiderRatingSummaryView(summary: summary),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            const Text('Latest', style: DesignTokens.mediumSemibold),
            for (final review in recent) RiderReviewTile(review: review),
          ],
        ],
      ),
    );
  }
}
