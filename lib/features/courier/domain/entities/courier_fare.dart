import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// "Pro" | "Traveler" | "Neighbor" (the server's spelling) in the app's
/// British spelling; null when absent.
String? fareTierLabel(String? tier) => switch (tier?.trim().toLowerCase()) {
  null || '' => null,
  'neighbor' || 'neighbour' => 'Neighbour',
  'traveler' || 'traveller' => 'Traveller',
  'pro' => 'Pro',
  _ => tier!.trim(),
};

/// What kind of surcharge a fare line is (rider-fare contract v1 extra
/// `code`). Unknown codes keep their server label and amount, so an extra
/// the backend adds later is still shown and still adds up to the total.
enum FareExtraKind {
  heavy,
  cashCollection,
  night,
  other;

  static FareExtraKind fromWire(Object? value) {
    final raw = value
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');
    return switch (raw) {
      'heavyparcel' || 'heavy' => heavy,
      'cashcollection' || 'cash' || 'cod' => cashCollection,
      'night' => night,
      _ => other,
    };
  }

  /// What to call the line when the server sent no label of its own.
  String get fallbackLabel => switch (this) {
    FareExtraKind.heavy => 'Heavy parcel',
    FareExtraKind.cashCollection => 'Cash collection',
    FareExtraKind.night => 'Night pick-up',
    FareExtraKind.other => 'Extra',
  };
}

/// One surcharge on top of the trip fare.
class FareExtra {
  const FareExtra({
    required this.kind,
    required this.label,
    required this.amount,
  });

  final FareExtraKind kind;
  final String label;
  final double amount;
}

/// How a rider's fare for one hop is made up — the `RiderFareBreakdown`
/// object of the rider-fare contract (v1):
///
/// ```
/// trip  = (baseFare + km × perKm) × tierMultiplier, at least minimumFare
/// total = trip + extras, rounded to the nearest Rs 5
/// ```
///
/// The fare is fixed when the offer is issued and [total] equals the offer's
/// proposed payout and the hop's courier payout. Older offers and hops have
/// no breakdown at all (null on the DTO), and the screens then show only
/// the single payout figure they always did.
class FareBreakdown {
  const FareBreakdown({
    required this.total,
    required this.currency,
    this.roadPriced = false,
    this.km,
    this.straightLineKm,
    this.detourFactor,
    this.baseFare,
    this.perKm,
    this.distanceAmount,
    this.tier,
    this.tierMultiplier,
    this.tripAmount,
    this.minimumFare,
    this.minimumApplied = false,
    this.extras = const [],
    this.rounding,
  });

  final double total;
  final String currency;

  /// `method == "road"`. Otherwise the km are a straight line × a detour
  /// factor, and the screens say "estimated".
  final bool roadPriced;

  /// Kilometres priced (`roadKm`): road km, or the estimate.
  final double? km;
  final double? straightLineKm;
  final double? detourFactor;
  final double? baseFare;
  final double? perKm;
  final double? distanceAmount;

  /// "Pro" | "Traveler" | "Neighbor" as the server spells it; see
  /// [tierLabel] for display.
  final String? tier;
  final double? tierMultiplier;

  /// The trip part after the tier and the minimum, before extras.
  final double? tripAmount;
  final double? minimumFare;
  final bool minimumApplied;
  final List<FareExtra> extras;

  /// total − (trip + extras): what rounding to Rs 5 added or took away.
  final double? rounding;

  Money money(double amount) => Money(amount: amount, currency: currency);

  Money get totalMoney => money(total);

  /// British spelling, as the rest of the app labels tiers.
  String? get tierLabel => fareTierLabel(tier);

  /// What the tier multiplier added (positive) or took off (negative) the
  /// base + distance. Null when there is nothing to work it out from, or when
  /// the minimum fare replaced the result anyway.
  double? get tierAdjustment {
    final trip = tripAmount;
    final base = baseFare;
    final distance = distanceAmount;
    if (trip == null || base == null || distance == null || minimumApplied) {
      return null;
    }
    final delta = trip - (base + distance);
    return delta.abs() < 0.005 ? 0 : delta;
  }

  /// Whether there is anything to itemise beyond the total.
  bool get isItemised =>
      baseFare != null ||
      distanceAmount != null ||
      km != null ||
      tierMultiplier != null ||
      extras.isNotEmpty;
}
