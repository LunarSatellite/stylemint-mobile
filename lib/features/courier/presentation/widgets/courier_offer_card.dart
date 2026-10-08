import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One offer on the rider's offers screen.
///
/// Two kinds of offer share the card. An auction offer is taken by the first
/// rider to accept, so it is Pass / Accept against a ticking deadline, as it
/// always was. A vendor-select offer is a vendor asking who can take it: the
/// rider says "I'm interested", waits while the vendor chooses, and then
/// either gets it or is told someone else did — so the card walks through
/// those states rather than disappearing on a tap.
class CourierOfferCard extends StatelessWidget {
  const CourierOfferCard({
    required this.offer,
    required this.now,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onWithdraw,
    required this.onOpenMap,
    this.interestState,
    super.key,
  });

  final HopOffer offer;
  final DateTime now;
  final bool busy;

  /// Accept an auction offer, or say "I'm interested" in a vendor-select one
  /// — the same call server-side.
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onWithdraw;
  final VoidCallback onOpenMap;

  /// Overrides [HopOffer.interestState] — the screen's optimistic value
  /// between a tap and the re-read that confirms it.
  final OfferInterestState? interestState;

  static const Key acceptKey = ValueKey<String>('courier-offer-accept');
  static const Key passKey = ValueKey<String>('courier-offer-pass');
  static const Key interestedKey = ValueKey<String>('courier-offer-interested');
  static const Key withdrawKey = ValueKey<String>('courier-offer-withdraw');
  static const Key openMapKey = ValueKey<String>('courier-offer-open-map');

  static const waitingText = 'Waiting for the vendor to choose…';
  static const selectedText = "You've got it!";
  static const notSelectedText = 'Another rider was chosen';
  static const expiredText = 'Expired';

  /// Where this offer stands, folding the clock in: an offer the rider never
  /// got an answer on is expired once its time is up, whatever the last read
  /// said.
  static OfferInterestState effectiveState(
    HopOffer offer,
    DateTime now, {
    OfferInterestState? override,
  }) {
    final state = override ?? offer.interestState;
    final open =
        state == OfferInterestState.none ||
        state == OfferInterestState.interested;
    if (open && offer.hasExpiredAt(now)) return OfferInterestState.expired;
    return state;
  }

  @override
  Widget build(BuildContext context) {
    final state = effectiveState(offer, now, override: interestState);
    final left = offer.remainingAt(now);
    final vendorSelect = offer.isVendorSelect;
    final live =
        !vendorSelect ||
        state == OfferInterestState.none ||
        state == OfferInterestState.interested;
    final urgent = live && left.inSeconds <= 30;
    final greyed =
        vendorSelect &&
        (state == OfferInterestState.expired ||
            state == OfferInterestState.notSelected);

    final card = Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: state == OfferInterestState.selected && vendorSelect
              ? DesignTokens.primaryGreen
              : urgent
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
              if (live)
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
          _Route(offer: offer),
          if (offer.distanceToPickupKm case final km?)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s4),
              child: Text(
                '${km.toStringAsFixed(1)} km to the pick-up',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ),
          // Worth surfacing rather than hiding: a high round number means
          // earlier couriers passed on this one, which usually means it is
          // awkward rather than generous. Auctions only — a vendor-select
          // offer has no rounds.
          if (!vendorSelect && offer.roundNumber > 1)
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
          if (vendorSelect) _vendorSelectFooter(state) else _auctionFooter(),
        ],
      ),
    );

    return greyed ? Opacity(opacity: 0.5, child: card) : card;
  }

  Widget _auctionFooter() => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          key: passKey,
          onPressed: busy ? null : onDecline,
          child: const Text('Pass'),
        ),
      ),
      const SizedBox(width: DesignTokens.s12),
      Expanded(
        child: FilledButton(
          key: acceptKey,
          onPressed: busy ? null : onAccept,
          child: const Text('Accept'),
        ),
      ),
    ],
  );

  Widget _vendorSelectFooter(OfferInterestState state) {
    switch (state) {
      case OfferInterestState.none:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The vendor chooses from the riders who say yes.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: passKey,
                    onPressed: busy ? null : onDecline,
                    child: const Text('Pass'),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: FilledButton(
                    key: interestedKey,
                    onPressed: busy ? null : onAccept,
                    child: const Text("I'm interested"),
                  ),
                ),
              ],
            ),
          ],
        );

      case OfferInterestState.interested:
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text(waitingText, style: DesignTokens.smallRegular),
            ),
            TextButton(
              key: withdrawKey,
              onPressed: busy ? null : onWithdraw,
              child: const Text('Withdraw'),
            ),
          ],
        );

      case OfferInterestState.selected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              selectedText,
              style: DesignTokens.h3.copyWith(color: DesignTokens.primaryGreen),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'The vendor chose you. The pick-up and drop-off are on your map.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textLight),
            ),
            const SizedBox(height: DesignTokens.s8),
            FilledButton(
              key: openMapKey,
              onPressed: onOpenMap,
              child: const Text('Open the map'),
            ),
          ],
        );

      case OfferInterestState.notSelected:
        return Text(
          notSelectedText,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        );

      case OfferInterestState.expired:
        return Text(
          expiredText,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        );
    }
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

/// "Pick up: Thamel → Drop off: Baluwatar · Neighbour". Falls back to the
/// geohash cells when the server sent no labels.
class _Route extends StatelessWidget {
  const _Route({required this.offer});

  final HopOffer offer;

  @override
  Widget build(BuildContext context) {
    final from = offer.pickup?.label;
    final to = offer.dropoff?.label;
    if (from == null && to == null) {
      return Text(
        '${offer.fromGeohash} → ${offer.toGeohash} · ${offer.tier.label}',
        style: DesignTokens.tiny,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _place(
          Icons.store_mall_directory_rounded,
          'Pick up',
          from ?? offer.fromGeohash,
        ),
        const SizedBox(height: 2),
        _place(Icons.location_on_rounded, 'Drop off', to ?? offer.toGeohash),
        const SizedBox(height: 2),
        Text(
          offer.tier.label,
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
      ],
    );
  }

  Widget _place(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: DesignTokens.textLight),
      const SizedBox(width: DesignTokens.s4),
      Expanded(
        child: Text(
          '$label: $value',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DesignTokens.tiny,
        ),
      ),
    ],
  );
}
