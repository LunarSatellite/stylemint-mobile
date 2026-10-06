import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_device_key_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_hop_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_offers_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_hop_map.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_signing_enrolment.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The courier's home screen: whether they can work, what work they have, and
/// the two things that most often stop offers arriving.
class CourierDashboardScreen extends ConsumerWidget {
  const CourierDashboardScreen({required this.profile, super.key});

  final CourierProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hops = ref.watch(courierHopsProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(courierHopsProvider)
              ..invalidate(courierOffersProvider)
              ..invalidate(courierCanSignProvider(profile.id))
              ..invalidate(courierEscrowBalanceProvider(profile.id))
              ..invalidate(courierReliabilityProvider(profile.id));
          },
          child: ListView(
            padding: const EdgeInsets.all(DesignTokens.s20),
            children: [
              // Three blockers, each stated as a cause rather than left for
              // the courier to infer from an empty offers list. "No offers"
              // looks identical whether there is no work, the account is not
              // Active yet, or escrow is short — and only the first is
              // nobody's fault.
              if (!profile.state.canCarry)
                const _Blocker(
                  icon: Icons.hourglass_bottom_rounded,
                  message:
                      'Your checks have cleared but your account is not live '
                      'yet, so no parcels will be offered. Nothing more is '
                      'needed from you.',
                ),
              // The handover-signing blocker used to live here. It is gone
              // from the rider's view on purpose: enrolling this phone's key
              // is not a decision a courier should be asked to make, it is
              // setup, and CourierSigningEnrolment now does it silently on
              // first open.
              //
              // The key itself is NOT gone, and could not be. Every custody
              // entry — pickup included — is rejected server-side without a
              // valid signature from a registered key
              // (ChainOfCustodyService.AppendAsync), so a courier with no key
              // cannot collect a parcel at all. Removing the requirement
              // rather than the friction would have taken the feature away.
              CourierSigningEnrolment(courierProfileId: profile.id),
              if (profile.escrowShortfall)
                _Blocker(
                  icon: Icons.account_balance_wallet_outlined,
                  message:
                      'Your deposit is short by '
                      '${formatMoney(Money(amount: profile.escrowOutstanding, currency: profile.escrowCurrency))}. '
                      'Parcels above your tier are not offered until it is '
                      'topped up.',
                ),

              // Always on screen, with or without a parcel. It used to appear
              // only when a hop was assigned, so a rider with no work saw no
              // map and no way to tell the feature existed — which is exactly
              // how it was reported. The job is drawn on top of the rider's
              // own position when it arrives.
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s16),
                child: CourierHopMap(
                  hop: hops.maybeWhen(
                    data: (list) => list
                        .where((hop) => !hop.state.isFinished)
                        .firstOrNull,
                    orElse: () => null,
                  ),
                ),
              ),

              _TierCard(profile: profile),
              const SizedBox(height: DesignTokens.s16),


              _OffersEntry(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CourierOffersScreen(),
                  ),
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
                                '${hop.fromGeohash} → ${hop.toGeohash}'
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
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CourierHopScreen(
                                    hop: hop,
                                    courierProfileId: profile.id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
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
