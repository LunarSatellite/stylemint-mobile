import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_action_feedback.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Hop offers, with the time left on each.
///
/// Offers are a Dutch auction: each round raises the payout, so one left to
/// expire can come back worth more. That makes the deadline the most important
/// thing on the card — a static "expires at 14:32" is useless to someone on a
/// bike, so this ticks.
class CourierOffersScreen extends ConsumerStatefulWidget {
  const CourierOffersScreen({super.key});

  @override
  ConsumerState<CourierOffersScreen> createState() =>
      _CourierOffersScreenState();
}

class _CourierOffersScreenState extends ConsumerState<CourierOffersScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // One timer for the screen, not one per card: a dozen offers would
    // otherwise mean a dozen timers all redrawing the same second.
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _accept(HopOffer offer) async {
    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .acceptOffer(offer.id);
    if (!mounted) return;

    if (result is CourierActionOk) {
      // Both lists move: the offer leaves, and a hop appears. Refreshing only
      // the offers would leave the courier wondering where the parcel went.
      ref
        ..invalidate(courierOffersProvider)
        ..invalidate(courierHopsProvider);
      SmSnackbar.success(context, 'Accepted. It is in your parcels now.');
      return;
    }
    showCourierActionFeedback(context, result);
  }

  Future<void> _decline(HopOffer offer) async {
    final reason = await showModalBottomSheet<DeclineReason>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Text(
                // Said plainly, because it is true and it changes behaviour:
                // the router feeds these reasons back into matching.
                'Why are you passing? This changes what you get offered next.',
                style: DesignTokens.smallRegular,
                textAlign: TextAlign.center,
              ),
            ),
            ...DeclineReason.values.map(
              (reason) => ListTile(
                title: Text(reason.label),
                onTap: () => Navigator.of(sheetContext).pop(reason),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .declineOffer(offerId: offer.id, reason: reason);
    if (!mounted) return;

    if (result is CourierActionOk) {
      ref.invalidate(courierOffersProvider);
      return;
    }
    showCourierActionFeedback(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(courierOffersProvider);
    final busy = ref.watch(courierActionsNotifierProvider);
    final now = DateTime.now().toUtc();

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Offers'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(courierOffersProvider),
          child: offers.when(
            loading: () => const Center(child: SmBrandLoader()),
            error: (_, _) => ListView(
              padding: const EdgeInsets.all(DesignTokens.s20),
              children: [
                Text(
                  "Couldn't load offers. Pull to refresh.",
                  style: DesignTokens.smallRegular,
                ),
              ],
            ),
            data: (list) {
              final live = list
                  .where((o) => o.isPending && !o.hasExpiredAt(now))
                  .toList(growable: false);
              if (live.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(DesignTokens.s20),
                  children: [
                    Text('Nothing waiting on you', style: DesignTokens.h3),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      'Offers arrive when a parcel near you needs carrying. '
                      'If none are coming, check your deposit and that your '
                      'account is live.',
                      style: DesignTokens.smallRegular,
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(DesignTokens.s20),
                itemCount: live.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DesignTokens.s12),
                itemBuilder: (_, index) => _OfferCard(
                  offer: live[index],
                  now: now,
                  busy: busy,
                  onAccept: () => _accept(live[index]),
                  onDecline: () => _decline(live[index]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.now,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final HopOffer offer;
  final DateTime now;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final left = offer.remainingAt(now);
    final urgent = left.inSeconds <= 30;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: urgent
              ? DesignTokens.colorError.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatMoney(
                    Money(
                      amount: offer.proposedPayoutAmount,
                      currency: offer.proposedPayoutCurrency,
                    ),
                  ),
                  style: DesignTokens.h2,
                ),
              ),
              Text(
                _countdown(left),
                style: DesignTokens.mediumSemibold.copyWith(
                  color: urgent
                      ? DesignTokens.colorError
                      : DesignTokens.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            '${offer.fromGeohash} → ${offer.toGeohash} · ${offer.tier.label}',
            style: DesignTokens.tiny,
          ),
          // Worth surfacing rather than hiding: a high round number means
          // earlier couriers passed on this one, which usually means it is
          // awkward rather than generous.
          if (offer.roundNumber > 1)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s4),
              child: Text(
                'Offered round ${offer.roundNumber} — others passed on it',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDecline,
                  child: const Text('Pass'),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _countdown(Duration left) {
    if (left == Duration.zero) return 'expired';
    final minutes = left.inMinutes;
    final seconds = left.inSeconds % 60;
    return minutes > 0
        ? '${minutes}m ${seconds.toString().padLeft(2, '0')}s'
        : '${seconds}s';
  }
}
