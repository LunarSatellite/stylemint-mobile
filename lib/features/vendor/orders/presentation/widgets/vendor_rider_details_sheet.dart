import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/presentation/rider_rating_messages.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/presentation/widgets/rider_rating_views.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/delivery_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/rider_profile_for_vendor.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/delivery_partner_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/live_refresh.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Opens [rider]'s details over the partner sheet. Resolves to the rider to
/// choose when the vendor taps "Choose this rider" — the partner sheet then
/// runs its usual confirm-and-select — or null for Back.
Future<InterestedRider?> showVendorRiderDetailsSheet(
  BuildContext context, {
  required String subOrderId,
  required InterestedRider rider,
}) => showModalBottomSheet<InterestedRider>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: DesignTokens.bgAppBody,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(DesignTokens.radiusLarge),
    ),
  ),
  builder: (_) => VendorRiderDetailsSheet(subOrderId: subOrderId, rider: rider),
);

/// Can this rider still be chosen?
enum RiderAvailability {
  /// Interested, and the request is open.
  open,

  /// The vendor already chose them.
  chosen,

  /// Withdrew, was not selected, or the request closed or went to someone
  /// else.
  gone,
}

/// Who the vendor is about to hand a parcel to: rating, track record,
/// vehicle and what other people said — then "Choose this rider" or Back.
///
/// Reads `GET …/delivery-requests/current/riders/{courierId}`. Until the
/// backend serves it (a plain 404), or while it loads, the sheet shows what
/// the interested row already said, so it is never empty. Kept current by
/// the partner sheet's own poll (the request underneath decides whether the
/// rider can still be chosen) and by live signals, which re-read the
/// details too.
class VendorRiderDetailsSheet extends ConsumerWidget {
  const VendorRiderDetailsSheet({
    required this.subOrderId,
    required this.rider,
    super.key,
  });

  final String subOrderId;

  /// The row that was tapped.
  final InterestedRider rider;

  static const Key chooseKey = ValueKey<String>('rider-details-choose');
  static const Key backKey = ValueKey<String>('rider-details-back');
  static const Key retryKey = ValueKey<String>('rider-details-retry');
  static const Key goneKey = ValueKey<String>('rider-details-gone');

  /// Whether [rider] can still be chosen, from the request as last read and
  /// what the details endpoint said.
  static RiderAvailability availabilityOf({
    required InterestedRider rider,
    required DeliveryPartnerState partner,
    RiderProfileForVendor? profile,
    bool notAvailable = false,
  }) {
    if (notAvailable || (profile?.state?.isGone ?? false)) {
      return RiderAvailability.gone;
    }
    if (partner is DeliveryPartnerLive) {
      final request = partner.request;
      switch (request.state) {
        case DeliveryRequestState.assigned:
          return request.assigned?.courierId == rider.courierId
              ? RiderAvailability.chosen
              : RiderAvailability.gone;
        case DeliveryRequestState.expired:
        case DeliveryRequestState.noRiders:
          return RiderAvailability.gone;
        case DeliveryRequestState.searching:
        case DeliveryRequestState.ridersInterested:
          return _listed(request, rider) == null
              ? RiderAvailability.gone
              : RiderAvailability.open;
      }
    }
    return profile?.state == RiderOfferState.assigned
        ? RiderAvailability.chosen
        : RiderAvailability.open;
  }

  static InterestedRider? _listed(DeliveryRequest request, InterestedRider r) {
    for (final candidate in request.interested) {
      if (candidate.offerId == r.offerId ||
          (r.courierId.isNotEmpty && candidate.courierId == r.courierId)) {
        return candidate;
      }
    }
    return null;
  }

  ({String subOrderId, String courierId}) get _key =>
      (subOrderId: subOrderId, courierId: rider.courierId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(deliveryPartnerNotifierProvider(subOrderId));
    final details = ref.watch(vendorRiderProfileProvider(_key));

    // The freshest copy of the row: the poll may have moved the distance.
    final live = partner is DeliveryPartnerLive
        ? _listed(partner.request, rider) ?? rider
        : rider;
    final fallback = RiderProfileForVendor.fromInterested(live);

    // Kept on screen while a live signal re-reads it.
    final result = details.value;
    final failure = result?.fold<NetworkExceptions?>((f) => f, (_) => null);
    final loaded = result?.fold<RiderProfileForVendor?>((_) => null, (p) => p);
    final notAvailable = failure != null && isRiderNotAvailable(failure);
    final profile = loaded ?? fallback;

    final availability = availabilityOf(
      rider: rider,
      partner: partner,
      profile: loaded,
      notAvailable: notAvailable,
    );
    final choosing =
        partner is DeliveryPartnerLive &&
        partner.choosingOfferId == live.offerId;
    final busyElsewhere = partner is DeliveryPartnerLive && partner.choosing;

    return LiveRefresh(
      scopes: const {LiveScope.vendorOrders},
      accepts: (signal) =>
          signal.subOrderId == null || signal.subOrderId == subOrderId,
      onRefresh: () async {
        ref.invalidate(vendorRiderProfileProvider(_key));
        await ref
            .read(deliveryPartnerNotifierProvider(subOrderId).notifier)
            .refresh();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s20,
                DesignTokens.s12,
                DesignTokens.s20,
                DesignTokens.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DesignTokens.borderDefault,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _Header(profile: profile),
                  if (details.isLoading && result == null) ...[
                    const SizedBox(height: DesignTokens.s12),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (availability != RiderAvailability.open) ...[
                    const SizedBox(height: DesignTokens.s12),
                    _AvailabilityBanner(availability: availability),
                  ],
                  const SizedBox(height: DesignTokens.s16),
                  _Facts(profile: profile),
                  const SizedBox(height: DesignTokens.s16),
                  _Section(
                    title: 'Ratings',
                    child: _Ratings(profile: profile),
                  ),
                  if (profile.recentReviews.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.s16),
                    _Section(
                      title: 'Recent reviews',
                      child: Column(
                        children: [
                          for (final (i, review)
                              in profile.recentReviews.indexed) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                color: DesignTokens.borderDefault,
                              ),
                            RiderReviewTile(review: review),
                          ],
                        ],
                      ),
                    ),
                  ],
                  // A real failure (not "not available", not "no such
                  // route"): the basics stay, and the rest can be retried.
                  if (failure != null && !notAvailable) ...[
                    const SizedBox(height: DesignTokens.s12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            riderRatingErrorMessage(failure),
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                        ),
                        TextButton(
                          key: retryKey,
                          onPressed: () =>
                              ref.invalidate(vendorRiderProfileProvider(_key)),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s20,
              DesignTokens.s8,
              DesignTokens.s20,
              DesignTokens.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: chooseKey,
                  onPressed:
                      availability == RiderAvailability.open && !busyElsewhere
                      ? () => Navigator.of(context).pop(live)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.primaryGreen,
                    foregroundColor: DesignTokens.buttonPrimaryText,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  child: choosing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          availability == RiderAvailability.chosen
                              ? 'Already chosen'
                              : 'Choose this rider',
                        ),
                ),
                TextButton(
                  key: backKey,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final RiderProfileForVendor profile;

  @override
  Widget build(BuildContext context) {
    final since = profile.memberSinceUtc;
    return Row(
      children: [
        RiderAvatar(
          name: profile.displayName,
          url: profile.avatarUrl,
          radius: 32,
        ),
        const SizedBox(width: DesignTokens.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(profile.displayName, style: DesignTokens.h3),
                    ),
                  ),
                  if (profile.verified == true) ...[
                    const SizedBox(width: DesignTokens.s6),
                    const RiderVerifiedTick(),
                  ],
                ],
              ),
              const SizedBox(height: DesignTokens.s4),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RiderTierBadge(profile.tier),
                  if (since != null)
                    Text(
                      'Member since ${DateFormat('MMM yyyy').format(since)}',
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  const _AvailabilityBanner({required this.availability});

  final RiderAvailability availability;

  @override
  Widget build(BuildContext context) {
    final chosen = availability == RiderAvailability.chosen;
    final color = chosen ? DesignTokens.primaryGreen : DesignTokens.colorError;
    return Container(
      key: chosen ? null : VendorRiderDetailsSheet.goneKey,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            chosen ? Icons.check_circle_rounded : Icons.person_off_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              chosen
                  ? 'You chose this rider.'
                  : 'This rider is no longer available for this parcel. '
                        'Choose someone else from the list.',
              style: DesignTokens.smallRegular,
            ),
          ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.profile});

  final RiderProfileForVendor profile;

  @override
  Widget build(BuildContext context) {
    final vehicle = profile.vehicle;
    final plate = profile.plateLast4;
    final distance = profile.distanceKm;
    final onTime = profile.onTimeRate;
    final cancelled = profile.cancellationRate;
    final delivered = profile.completedDeliveries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: DesignTokens.s24,
          runSpacing: DesignTokens.s12,
          children: [
            if (delivered != null)
              _Stat(
                value: '$delivered',
                label: delivered == 1 ? 'delivery' : 'deliveries',
              ),
            if (onTime != null)
              _Stat(value: '${(onTime * 100).round()}%', label: 'on time'),
            if (cancelled != null)
              _Stat(
                value: '${(cancelled * 100).round()}%',
                label: 'cancelled',
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        if (vehicle != null)
          _Fact(
            icon: Icons.two_wheeler,
            label: 'Vehicle',
            value: plate == null ? vehicle : '$vehicle · plate ••$plate',
          ),
        if (profile.homeArea != null)
          _Fact(
            icon: Icons.home_work_outlined,
            label: 'Home area',
            value: profile.homeArea!,
          ),
        if (distance != null && distance > 0)
          _Fact(
            icon: Icons.near_me_outlined,
            label: 'Distance',
            value: '${distance.toStringAsFixed(1)} km away',
          ),
      ],
    );
  }
}

class _Ratings extends StatelessWidget {
  const _Ratings({required this.profile});

  final RiderProfileForVendor profile;

  @override
  Widget build(BuildContext context) {
    final summary = profile.rating;
    if (summary != null) return RiderRatingSummaryView(summary: summary);
    // From the interested row only: the average and count, nothing more.
    final average = profile.averageFromList;
    final count = profile.ratingCountFromList;
    return Text(
      average == null
          ? 'New rider'
          : '★ ${average.toStringAsFixed(1)}'
                '${count == null ? '' : ' · $count ${count == 1 ? 'rating' : 'ratings'}'}',
      style: DesignTokens.mediumSemibold,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s8),
        child,
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: DesignTokens.h3),
      Text(
        label,
        style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
      ),
    ],
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s8),
        Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: DesignTokens.smallRegular,
          ),
        ),
      ],
    ),
  );
}

/// Initials over the photo, so a missing or failed avatar still names the
/// rider rather than leaving a grey circle.
class RiderAvatar extends StatelessWidget {
  const RiderAvatar({
    required this.name,
    required this.url,
    this.radius = 22,
    super.key,
  });

  final String name;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    final image = url;
    return CircleAvatar(
      radius: radius,
      backgroundColor: DesignTokens.bgAppBodyLight,
      foregroundImage: image == null ? null : NetworkImage(image),
      onForegroundImageError: image == null ? null : (_, _) {},
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: DesignTokens.mediumSemibold,
      ),
    );
  }
}

/// Neighbour / Traveller / Pro.
class RiderTierBadge extends StatelessWidget {
  const RiderTierBadge(this.tier, {super.key});

  final String tier;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s8,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreenLight,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
    ),
    child: Text(
      tier,
      style: DesignTokens.tiny.copyWith(color: DesignTokens.primaryGreen),
    ),
  );
}

/// "Identity verified" (KYC approved), as a tick.
class RiderVerifiedTick extends StatelessWidget {
  const RiderVerifiedTick({super.key});

  @override
  Widget build(BuildContext context) => const Tooltip(
    message: 'Identity verified',
    child: Icon(
      Icons.verified_rounded,
      size: 16,
      color: DesignTokens.colorSuccess,
      semanticLabel: 'Verified',
    ),
  );
}
