import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// How far one delivery option travels, on the checkout tile that offers it —
/// backend `DeliveryDistanceSummary` on each `DeliveryChoice`.
///
/// ## The state is the answer; the number is a detail of one state
///
/// [DeliveryDistanceSummary.state] is read before
/// [DeliveryDistanceSummary.straightLineKm], never the other way round. Only
/// [DeliveryDistanceState.measured] produces a figure. Every other state
/// renders the server's own [DeliveryDistanceSummary.withheldReason] and no
/// distance at all — not "0 km", not "unknown km", not a dash where a number
/// would go. A withheld distance is unknown, and unknown must not appear
/// anywhere near a number line.
///
/// A partial sum is never shown either, and that rule lives on the server: if
/// one journey of three could not be measured the whole figure is withheld,
/// because a sum missing a leg reads as complete *and shorter than the truth*.
/// This widget's job is to not undo that by inventing a stand-in.
///
/// ## Straight line is not road distance
///
/// [DeliveryDistanceSummary.method] is rendered verbatim beside the figure, in
/// every state, because it is the sentence that says a vehicle travels further
/// than this. It is never summarised, never collapsed behind a tap and never
/// omitted when space is short: a great-circle number shown without it is a
/// travelled distance the platform did not measure.
///
/// ## Collection is zero journeys, not zero distance
///
/// [DeliveryDistanceState.noDeliveryJourney] renders "No delivery journey" —
/// the count, in words — and then the server's reason, which says plainly that
/// this is a count the platform records rather than a distance it measured.
/// The shopper still travels to collect; nobody here knows how far.
///
/// ## Emissions
///
/// [emissions] is null on every deployment that holds no reviewed factor,
/// which is all of them, and null means "we are not entitled to state a
/// figure", never "this emits nothing". When one does arrive, the mass is
/// never rendered without its factor version, its source and its method — see
/// [DeliveryEmissionsEstimate.isRenderable].
class DeliveryDistanceNote extends StatelessWidget {
  const DeliveryDistanceNote({
    required this.distance,
    this.emissions,
    super.key,
  });

  final DeliveryDistanceSummary distance;
  final DeliveryEmissionsEstimate? emissions;

  @override
  Widget build(BuildContext context) {
    final showEmissions = emissions != null && emissions!.isRenderable;
    return Semantics(
      container: true,
      label: _semanticSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                distance.hasFigure
                    ? Icons.straighten_rounded
                    : Icons.help_outline_rounded,
                size: 14,
                color: DesignTokens.textMuted,
              ),
              const SizedBox(width: DesignTokens.s4),
              // The headline wraps rather than ellipsising: a distance cut off
              // mid-figure, or a withheld-state phrase cut to its first word,
              // is worse than a taller tile.
              Expanded(
                child: Text(
                  _headline,
                  style: const TextStyle(
                    color: DesignTokens.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (_journeysLine case final journeys?) ...[
            const SizedBox(height: 2),
            Text(
              journeys,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          // The server's sentence, verbatim. It is the whole feature when
          // there is no number.
          if (distance.withheldReason case final reason?) ...[
            const SizedBox(height: 2),
            Text(
              reason,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            distance.method,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          if (showEmissions) ...[
            const SizedBox(height: DesignTokens.s4),
            _EmissionsNote(emissions: emissions!),
          ],
        ],
      ),
    );
  }

  /// One line, chosen by state. Only the measured state names a distance.
  String get _headline => switch (distance.state) {
    DeliveryDistanceState.measured =>
      distance.straightLineKm == null
          // Measured with no figure should not happen; the data layer drops
          // the figure, never the state. If it ever does, the honest reading
          // is the same as any other missing figure.
          ? 'Distance not shown'
          : '${_kmLabel(distance.straightLineKm!)} in a straight line',
    DeliveryDistanceState.noDeliveryJourney => 'No delivery journey',
    _ => 'Distance not shown',
  };

  /// The journey count, where saying it adds something the other lines do not.
  ///
  /// Withheld-for-unknown states get nothing here: the server's reason already
  /// states how many journeys there are and how many it could not measure, and
  /// repeating a count beside a withheld distance is how a count starts
  /// reading as the distance.
  String? get _journeysLine => switch (distance.state) {
    DeliveryDistanceState.measured =>
      distance.journeys == 1
          ? 'One delivery journey.'
          : '${distance.journeys} delivery journeys, added together.',
    DeliveryDistanceState.noDeliveryJourney => null,
    _ => null,
  };

  String get _semanticSummary => switch (distance.state) {
    DeliveryDistanceState.measured when distance.straightLineKm != null =>
      '${_kmLabel(distance.straightLineKm!)} in a straight line. '
          '${distance.method}',
    DeliveryDistanceState.noDeliveryJourney =>
      'No delivery journey. ${distance.withheldReason ?? distance.method}',
    _ =>
      'Distance not shown. ${distance.withheldReason ?? distance.method}',
  };

  /// The server rounds to one decimal place and this repeats that exactly. No
  /// re-rounding, no "about", no stripping of a trailing zero — `12.0 km` is
  /// the figure that was measured and `12 km` is a different claim.
  static String _kmLabel(double km) => '${km.toStringAsFixed(1)} km';
}

/// Transport emissions, when a reviewed factor exists. Never the mass alone.
class _EmissionsNote extends StatelessWidget {
  const _EmissionsNote({required this.emissions});

  final DeliveryEmissionsEstimate emissions;

  @override
  Widget build(BuildContext context) {
    final effective = emissions.factorEffectiveUtc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${emissions.kgCo2e.toStringAsFixed(3)} kg CO₂e',
          style: const TextStyle(
            color: DesignTokens.textWhite,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Factor ${emissions.factorVersion}'
          '${effective == null ? '' : ', in effect from '
              '${DateFormat('MMM d, y').format(effective.toLocal())}'}'
          '\n${emissions.factorSourceUri}',
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 11,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          emissions.method,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
