import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_fare.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "7.4 km by road" or "7.4 km, estimated" — the second when the fare was
/// priced on a straight line × a detour factor because the road distance
/// was not available. The rider should know the ride may be longer.
String fareDistanceText(FareBreakdown fare) {
  final km = fare.km;
  if (km == null) {
    return fare.roadPriced ? 'by road' : 'estimated';
  }
  final value = km.toStringAsFixed(1);
  return fare.roadPriced ? '$value km by road' : '$value km, estimated';
}

/// "×0.85", "×1.2", "×1".
String fareMultiplierText(double multiplier) {
  var text = multiplier.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return '×$text';
}

String _signed(FareBreakdown fare, double amount) {
  final text = formatMoney(fare.money(amount.abs()));
  return amount < 0 ? '− $text' : '+ $text';
}

/// How a hop's fare is made up: base, distance, tier, each extra, total.
///
/// On the offer card before the rider accepts, on the job and parcel
/// screens, and under each delivery in the earnings history. Lines the
/// server did not itemise are left out rather than drawn as Rs 0.
class CourierFareBreakdown extends StatelessWidget {
  const CourierFareBreakdown({
    required this.fare,
    this.showTotal = true,
    this.dense = false,
    super.key,
  });

  final FareBreakdown fare;
  final bool showTotal;

  /// Smaller type and no footnote, for the offer card and history rows.
  final bool dense;

  static const Key viewKey = ValueKey<String>('courier-fare-breakdown');
  static const Key estimatedKey = ValueKey<String>('courier-fare-estimated');
  static const Key totalKey = ValueKey<String>('courier-fare-total');

  static const estimateNote =
      'Distance is estimated from a straight line; the road may be longer.';

  @override
  Widget build(BuildContext context) {
    final style = dense ? DesignTokens.tiny : DesignTokens.smallRegular;
    final muted = style.copyWith(color: DesignTokens.textLight);
    final rows = <Widget>[];

    void line(String label, String value, {Key? key}) {
      rows.add(
        Padding(
          key: key,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: muted)),
              const SizedBox(width: DesignTokens.s8),
              Text(value, style: style),
            ],
          ),
        ),
      );
    }

    if (fare.baseFare case final base?) {
      line('Base fare', formatMoney(fare.money(base)));
    }

    if (fare.distanceAmount != null || fare.km != null) {
      final rate = fare.perKm;
      final label = rate == null
          ? 'Distance · ${fareDistanceText(fare)}'
          : 'Distance · ${fareDistanceText(fare)} × '
                '${formatMoney(fare.money(rate), decimalDigits: 0)}/km';
      line(
        label,
        fare.distanceAmount == null
            ? ''
            : formatMoney(fare.money(fare.distanceAmount!)),
        key: fare.roadPriced ? null : estimatedKey,
      );
    }

    final tierLabel = fare.tierLabel;
    final multiplier = fare.tierMultiplier;
    if (tierLabel != null || multiplier != null) {
      final label = [
        tierLabel == null ? 'Tier' : '$tierLabel tier',
        if (multiplier != null) fareMultiplierText(multiplier),
      ].join(' ');
      final adjustment = fare.tierAdjustment;
      line(
        label,
        adjustment == null || adjustment == 0 ? '' : _signed(fare, adjustment),
      );
    }

    if (fare.minimumApplied) {
      final minimum = fare.minimumFare ?? fare.tripAmount;
      line(
        'Minimum fare applied',
        minimum == null ? '' : formatMoney(fare.money(minimum)),
      );
    }

    for (final extra in fare.extras) {
      line(extra.label, _signed(fare, extra.amount));
    }

    final rounding = fare.rounding;
    if (rounding != null && rounding.abs() >= 0.005 && fare.isItemised) {
      line('Rounded to the nearest Rs 5', _signed(fare, rounding));
    }

    if (showTotal) {
      if (rows.isNotEmpty) {
        rows.add(
          const Divider(
            height: DesignTokens.s12,
            color: DesignTokens.borderDefault,
          ),
        );
      }
      rows.add(
        Row(
          key: totalKey,
          children: [
            Expanded(
              child: Text(
                'Total',
                style: style.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              formatMoney(Money(amount: fare.total, currency: fare.currency)),
              style: style.copyWith(
                fontWeight: FontWeight.w600,
                color: DesignTokens.primaryGreen,
              ),
            ),
          ],
        ),
      );
    }

    if (!fare.roadPriced && !dense && fare.isItemised) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: DesignTokens.s4),
          child: Text(
            estimateNote,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ),
      );
    }

    return Column(
      key: viewKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

/// The breakdown in a card, with a heading — for the job and parcel screens.
class CourierFareCard extends StatelessWidget {
  const CourierFareCard({required this.fare, super.key});

  final FareBreakdown fare;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How your fare is worked out', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s8),
        CourierFareBreakdown(fare: fare),
      ],
    ),
  );
}
