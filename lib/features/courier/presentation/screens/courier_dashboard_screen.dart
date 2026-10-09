import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_device_key_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_job_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_offers_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_delivery_push_listener.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_hop_map.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_location_beacon.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_shift_slider.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_signing_enrolment.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/live_refresh.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The courier's home screen: the map they work from, whether work can reach
/// them, and the parcels they are carrying.
///
/// Laid out map-first. It used to be a list of cards with a 220px map wedged
/// between two of them, which read as a dashboard about deliveries rather than
/// a tool for doing one — and the map was reported as missing entirely more
/// than once, because at that size, below the fold, it was easy to miss. The
/// map now fills the screen, the shift control floats over it, and everything
/// that is reference rather than live sits in a sheet the rider pulls up.
class CourierDashboardScreen extends ConsumerWidget {
  const CourierDashboardScreen({required this.profile, super.key});

  final CourierProfile profile;

  /// How much of the screen the detail sheet covers at rest.
  ///
  /// Shared with the map so the job card can sit directly above the sheet
  /// rather than at a guessed offset.
  static const double _sheetRest = 0.24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hops = ref.watch(courierHopsProvider);

    final activeHop = hops.maybeWhen(
      data: (list) => list.where((hop) => !hop.state.isFinished).firstOrNull,
      orElse: () => null,
    );

    // A new offer, a selection, a pickup or a delivery elsewhere shows here
    // at once (push, live event, reconnect) — no pull-to-refresh.
    return LiveRefresh(
      scopes: const {LiveScope.courierJobs, LiveScope.courierOffers},
      onRefresh: () async {
        ref
          ..invalidate(courierHopsProvider)
          ..invalidate(courierJobsProvider)
          ..invalidate(courierOffersProvider);
      },
      child: Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Transparent so the map runs under it: the status bar area is map,
        // not a band of chrome above one.
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'Signing',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CourierDeviceKeyScreen(courierProfileId: profile.id),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sheetRestHeight = constraints.maxHeight * _sheetRest;

          return Stack(
            children: [
              // Always on screen, with or without a parcel. It used to appear
              // only when a hop was assigned, so a rider with no work saw no
              // map and no way to tell the feature existed — which is exactly
              // how it was reported. The job is drawn on top of the rider's
              // own position when it arrives.
              Positioned.fill(
                child: CourierHopMap(
                  hop: activeHop,
                  fill: true,
                  bottomInset: sheetRestHeight,
                  onOpenJob: activeHop == null
                      ? null
                      : () => openCourierJob(
                          context,
                          activeHop,
                          courierProfileId: profile.id,
                        ),
                ),
              ),

              // Over the map, under the app bar. Whether work can arrive at
              // all matters more than anything else on this screen, and the
              // rider has to be able to reach it without pulling the sheet
              // up first.
              Positioned(
                top: MediaQuery.paddingOf(context).top + kToolbarHeight,
                left: DesignTokens.s16,
                right: DesignTokens.s16,
                child: CourierShiftSlider(profile: profile),
              ),

              // Enrolling this phone's signing key is not a decision a
              // courier should be asked to make, it is setup, so it happens
              // silently on first open and renders nothing.
              //
              // The key itself is NOT gone, and could not be. Every custody
              // entry — pickup included — is rejected server-side without a
              // valid signature from a registered key
              // (ChainOfCustodyService.AppendAsync), so a courier with no key
              // cannot collect a parcel at all. Removing the requirement
              // rather than the friction would have taken the feature away.
              CourierSigningEnrolment(courierProfileId: profile.id),

              // Also render nothing. The beacon reports the rider's position
              // while on shift and in the foreground, which is what puts them
              // inside a vendor's 5 km; the listener re-reads offers and
              // parcels when a delivery push lands, so a vendor choosing this
              // rider puts the job on the map at once.
              CourierLocationBeacon(profile: profile),
              const CourierDeliveryPushListener(),

              DraggableScrollableSheet(
                initialChildSize: _sheetRest,
                minChildSize: 0.12,
                maxChildSize: 0.88,
                builder: (context, controller) => _DetailSheet(
                  controller: controller,
                  profile: profile,
                  hops: hops,
                  onRefresh: () async {
                    ref
                      ..invalidate(courierHopsProvider)
                      ..invalidate(courierJobsProvider)
                      ..invalidate(courierOffersProvider)
                      ..invalidate(courierCanSignProvider(profile.id))
                      ..invalidate(courierEscrowBalanceProvider(profile.id))
                      ..invalidate(courierReliabilityProvider(profile.id));
                  },
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

/// Everything that is reference rather than live: standing, offers, parcels.
///
/// Scrollable, and the sheet's own controller drives it, which is what keeps
/// the map's pan gesture and the list's scroll gesture from fighting — a
/// drag that starts on the sheet moves the sheet, a drag that starts on the
/// map moves the map.
class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.controller,
    required this.profile,
    required this.hops,
    required this.onRefresh,
  });

  final ScrollController controller;
  final CourierProfile profile;
  final AsyncValue<List<DeliveryHop>> hops;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Color(0x66000000), blurRadius: 18),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s20,
            DesignTokens.s8,
            DesignTokens.s20,
            DesignTokens.s24,
          ),
          children: [
            // Says "there is more down here" without a line of copy.
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: DesignTokens.s12),
                decoration: BoxDecoration(
                  color: DesignTokens.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Blockers state a cause rather than leaving the courier to infer
            // one from an empty offers list: "no offers" looks identical
            // whether there is no work, they are off shift, or escrow is
            // short, and only the first is nobody's fault.
            if (profile.escrowShortfall)
              _Blocker(
                icon: Icons.account_balance_wallet_outlined,
                message:
                    'Your deposit is short by '
                    '${formatMoney(Money(amount: profile.escrowOutstanding, currency: profile.escrowCurrency))}. '
                    'Parcels above your tier are not offered until it is '
                    'topped up.',
              ),

            _TierCard(profile: profile),
            const SizedBox(height: DesignTokens.s16),

            _OffersEntry(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CourierOffersScreen()),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),

            Text('Your parcels', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s8),
            hops.when(
              loading: () => const Center(child: SmBrandLoader()),
              error: (_, _) => Text(
                "Couldn't load your parcels. Pull to refresh.",
                style: DesignTokens.smallRegular,
              ),
              data: (list) {
                final open = list
                    .where((hop) => !hop.state.isFinished)
                    .toList(growable: false);
                if (open.isEmpty) {
                  return Text(
                    'Nothing to carry right now. Accepted parcels appear '
                    'here with what to do next.',
                    style: DesignTokens.smallRegular,
                  );
                }
                return Column(
                  children: open
                      .map(
                        (hop) => Card(
                          color: DesignTokens.bgAppBody,
                          margin: const EdgeInsets.only(
                            bottom: DesignTokens.s12,
                          ),
                          child: ListTile(
                            title: Text(
                              hop.state.label,
                              style: DesignTokens.mediumSemibold,
                            ),
                            subtitle: Text(
                              '${hop.pickup?.label ?? hop.fromGeohash} → '
                              '${hop.dropoff?.label ?? hop.toGeohash}'
                              '${hop.isLate ? ' · running late' : ''}',
                              style: DesignTokens.tiny,
                            ),
                            trailing: Text(
                              formatMoney(
                                Money(
                                  amount: hop.payoutAmount,
                                  currency: hop.payoutCurrency,
                                ),
                              ),
                              style: DesignTokens.mediumSemibold,
                            ),
                            // The job screen: map, parcel details and the
                            // next step. The signed-handover screen this used
                            // to open is in its menu.
                            onTap: () => openCourierJob(
                              context,
                              hop,
                              courierProfileId: profile.id,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            const _DeliveredToday(),
          ],
        ),
      ),
    );
  }
}

/// The last day's finished runs, from `GET /v1/courier/jobs`: proof that a
/// confirmation landed, and a way back to a job's details (package, payout)
/// after it left the map. Renders nothing until there is one — or when the
/// list cannot be read, since it is a record, not something to act on.
class _DeliveredToday extends ConsumerWidget {
  const _DeliveredToday();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delivered =
        ref
            .watch(courierJobsProvider)
            .maybeWhen(data: (jobs) => jobs, orElse: () => const <CourierJob>[])
            .where((job) => job.status == CourierJobStatus.delivered)
            .toList(growable: false);
    if (delivered.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delivered today', style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.s8),
          for (final job in delivered)
            Card(
              color: DesignTokens.bgAppBody,
              margin: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle_rounded,
                  color: DesignTokens.primaryGreen,
                ),
                title: Text(
                  job.packageNumber.isEmpty ? 'Parcel' : job.packageNumber,
                  style: DesignTokens.mediumSemibold,
                ),
                subtitle: Text(
                  job.dropoff.label ?? job.dropoff.addressLine ?? 'Delivered',
                  style: DesignTokens.tiny,
                ),
                trailing: job.payout == null
                    ? null
                    : Text(
                        formatMoney(job.payout!),
                        style: DesignTokens.mediumSemibold,
                      ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CourierJobScreen(hopId: job.hopId),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pushes the job screen for [hop] over the dashboard, so back returns here.
void openCourierJob(
  BuildContext context,
  DeliveryHop hop, {
  required String courierProfileId,
}) {
  unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CourierJobScreen(
          hopId: hop.id,
          hop: hop,
          courierProfileId: courierProfileId,
        ),
      ),
    ),
  );
}

class _TierCard extends ConsumerWidget {
  const _TierCard({required this.profile});

  final CourierProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reliability = ref.watch(courierReliabilityProvider(profile.id));

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.tier.label} partner',
                  style: DesignTokens.h3,
                ),
              ),
              if (profile.failureStreak > 0)
                Text(
                  '${profile.failureStreak} failed in a row',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          reliability.when(
            loading: () => const SizedBox(
              height: 18,
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (_, _) => const SizedBox.shrink(),
            // Null is not zero: a courier who has carried nothing has no
            // score, and showing 0% would read as a bad one.
            data: (snapshot) => snapshot == null
                ? Text(
                    'No deliveries yet, so there is nothing to score.',
                    style: DesignTokens.tiny,
                  )
                : Wrap(
                    spacing: DesignTokens.s16,
                    runSpacing: DesignTokens.s8,
                    children: [
                      _Stat(
                        label: 'On time',
                        value: '${(snapshot.onTimeRate * 100).round()}%',
                      ),
                      _Stat(
                        label: 'Accepted',
                        value: '${(snapshot.acceptanceRate * 100).round()}%',
                      ),
                      _Stat(
                        label: 'Delivered',
                        value: '${snapshot.hopsCompleted}',
                      ),
                      if (snapshot.averageCustomerRating > 0)
                        _Stat(
                          label: 'Rating',
                          value: snapshot.averageCustomerRating
                              .toStringAsFixed(1),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: DesignTokens.mediumSemibold),
      Text(label, style: DesignTokens.tiny),
    ],
  );
}

class _OffersEntry extends ConsumerWidget {
  const _OffersEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(courierOffersProvider);
    final pending = offers.maybeWhen(
      data: (list) => list.where((o) => o.isPending).length,
      orElse: () => 0,
    );

    return Card(
      color: DesignTokens.bgAppBody,
      child: ListTile(
        leading: const Icon(
          Icons.local_offer_outlined,
          color: DesignTokens.primaryGreen,
        ),
        title: Text('Offers', style: DesignTokens.mediumSemibold),
        subtitle: Text(
          pending == 0
              ? 'Nothing waiting on you'
              : '$pending waiting — they expire',
          style: DesignTokens.tiny,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _Blocker extends StatelessWidget {
  const _Blocker({
    required this.icon,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: DesignTokens.colorError.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.colorError, size: 20),
          const SizedBox(width: DesignTokens.s12),
          Expanded(child: Text(message, style: DesignTokens.tiny)),
          if (action != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
