import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';

/// Mirrors `HopOfferState`.
enum HopOfferState {
  pending(1),
  accepted(2),
  declined(3),
  expired(4),
  superseded(5);

  const HopOfferState(this.wire);

  final int wire;

  static HopOfferState fromWire(int? value) =>
      HopOfferState.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => HopOfferState.pending,
      );
}

/// Mirrors `DeclineReasonCode`. The router feeds these back into matching, so
/// picking the honest one makes later offers better rather than being a
/// formality.
enum DeclineReason {
  tooFar(1),
  wrongTiming(2),
  vehicleUnsuitable(3),
  payoutTooLow(4),
  packageTooHeavy(5),
  other(6);

  const DeclineReason(this.wire);

  final int wire;

  String get label => switch (this) {
    DeclineReason.tooFar => 'Too far away',
    DeclineReason.wrongTiming => 'Wrong time for me',
    DeclineReason.vehicleUnsuitable => 'My vehicle does not suit it',
    DeclineReason.payoutTooLow => 'Payout too low',
    DeclineReason.packageTooHeavy => 'Package too heavy',
    DeclineReason.other => 'Something else',
  };
}

/// How an offer is decided. Mirrors the delivery-selection contract's `mode`.
enum OfferMode {
  /// The first courier to accept gets it — the original Dutch auction.
  auction,

  /// The vendor chooses: accepting only says "I'm interested", and nothing
  /// is the rider's until the vendor picks them.
  vendorSelect;

  /// Unknown or absent reads as [auction], which is what every offer was
  /// before the field existed — so an older backend keeps working unchanged.
  static OfferMode fromWire(Object? value) {
    final raw = value?.toString().trim().toLowerCase().replaceAll('_', '');
    return raw == 'vendorselect' || raw == '2'
        ? OfferMode.vendorSelect
        : OfferMode.auction;
  }
}

/// Where a rider stands on a [OfferMode.vendorSelect] offer.
enum OfferInterestState {
  none,
  interested,
  selected,
  notSelected,
  expired;

  /// Strings per the contract; a 0-based number is read too. Unknown is
  /// [none], which shows the "I'm interested" button — the server refuses it
  /// if that is wrong, which is better than hiding an offer that is live.
  static OfferInterestState fromWire(Object? value) {
    if (value is num) {
      final index = value.toInt();
      return index >= 0 && index < values.length
          ? values[index]
          : OfferInterestState.none;
    }
    final raw = value?.toString().trim().toLowerCase().replaceAll('_', '');
    for (final state in values) {
      if (state.name.toLowerCase() == raw) return state;
    }
    return OfferInterestState.none;
  }
}

/// A named point — the pick-up or drop-off of an offer or hop.
///
/// Exact coordinates, unlike the geohash cells the routing engine works in,
/// so the map can put a pin on the shop rather than in the middle of a
/// neighbourhood.
class DeliveryPlace {
  const DeliveryPlace({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final double latitude;
  final double longitude;

  /// "Thamel, Kathmandu" or similar; null when the server sent none.
  final String? label;
}

/// A hop the router is offering, in a Dutch auction: each round raises the
/// payout, so an offer left to expire may come back worth more. It also means
/// an offer has a hard deadline, which is why [expiresUtc] is shown as a
/// countdown rather than a timestamp.
///
/// A [OfferMode.vendorSelect] offer is not an auction: the payout is fixed,
/// accepting records interest, and [interestState] says where that stands.
class HopOffer {
  const HopOffer({
    required this.id,
    required this.packageId,
    required this.tier,
    required this.hopIndex,
    required this.roundNumber,
    required this.proposedPayoutAmount,
    required this.proposedPayoutCurrency,
    required this.fromGeohash,
    required this.toGeohash,
    required this.state,
    required this.offeredUtc,
    required this.expiresUtc,
    this.mode = OfferMode.auction,
    this.interestState = OfferInterestState.none,
    this.pickup,
    this.dropoff,
    this.distanceToPickupKm,
  });

  final String id;
  final String packageId;
  final DeliveryTier tier;
  final int hopIndex;
  final OfferMode mode;
  final OfferInterestState interestState;
  final DeliveryPlace? pickup;
  final DeliveryPlace? dropoff;

  /// From the rider's live location when the request went out; null when the
  /// server could not tell.
  final double? distanceToPickupKm;

  bool get isVendorSelect => mode == OfferMode.vendorSelect;

  /// Which auction round this is. A high number means earlier couriers passed,
  /// which is worth surfacing: it usually means the hop is awkward, not that
  /// it is generous.
  final int roundNumber;

  final double proposedPayoutAmount;
  final String proposedPayoutCurrency;
  final String fromGeohash;
  final String toGeohash;
  final HopOfferState state;
  final DateTime offeredUtc;
  final DateTime expiresUtc;

  bool get isPending => state == HopOfferState.pending;

  Duration remainingAt(DateTime now) {
    final left = expiresUtc.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool hasExpiredAt(DateTime now) =>
      !expiresUtc.isAfter(now) || state == HopOfferState.expired;
}

/// Mirrors the backend's `HopState`. Drives which action the hop screen
/// offers, so the numbers matter more than the labels — a wrong value here
/// shows the courier the wrong button and sends a transition the aggregate
/// refuses.
///
/// Note there is no `delivered`: a final delivery to the buyer is a handoff
/// like any other, and the hop ends at [handedOff]. The package, not the hop,
/// is what becomes delivered.
enum HopState {
  pending(1),
  offered(2),
  accepted(3),
  enRoutePickup(4),
  pickedUp(5),
  enRouteHandoff(6),
  handedOff(7),
  cancelled(8),
  failed(9);

  const HopState(this.wire);

  final int wire;

  static HopState fromWire(int? value) => HopState.values.firstWhere(
    (s) => s.wire == value,
    orElse: () => HopState.pending,
  );

  String get label => switch (this) {
    HopState.pending => 'Waiting to be offered',
    HopState.offered => 'Offered to you',
    HopState.accepted => 'Ready to collect',
    HopState.enRoutePickup => 'On the way to collect',
    HopState.pickedUp => 'With you',
    HopState.enRouteHandoff => 'On the way to drop off',
    HopState.handedOff => 'Handed on',
    HopState.cancelled => 'Cancelled',
    HopState.failed => 'Failed',
  };

  /// Collect is the action until the parcel is in hand. EnRoutePickup counts:
  /// a courier already travelling to the pickup still has to record it.
  bool get awaitingPickup =>
      this == HopState.accepted || this == HopState.enRoutePickup;

  /// Hand on or deliver — both are a handoff to the backend; what differs is
  /// whether the next holder is a courier or the buyer.
  bool get awaitingHandoff =>
      this == HopState.pickedUp || this == HopState.enRouteHandoff;

  bool get isFinished =>
      this == HopState.handedOff ||
      this == HopState.cancelled ||
      this == HopState.failed;
}

/// Mirrors `DeliveryExceptionCode`.
enum DeliveryExceptionCode {
  packageDamaged(1),
  packageLost(2),
  buyerUnreachable(3),
  addressIncorrect(4),
  weatherDelay(5),
  courierAccident(6),
  sealBroken(7),
  noMatchingCourier(8);

  const DeliveryExceptionCode(this.wire);

  final int wire;

  String get label => switch (this) {
    DeliveryExceptionCode.packageDamaged => 'Package damaged',
    DeliveryExceptionCode.packageLost => 'Package lost',
    DeliveryExceptionCode.buyerUnreachable => 'Buyer unreachable',
    DeliveryExceptionCode.addressIncorrect => 'Address is wrong',
    DeliveryExceptionCode.weatherDelay => 'Weather delay',
    DeliveryExceptionCode.courierAccident => 'I had an accident',
    DeliveryExceptionCode.sealBroken => 'Seal is broken',
    DeliveryExceptionCode.noMatchingCourier => 'No onward courier',
  };

  /// Whether reporting this should also end the courier's leg. Offered as the
  /// default in the UI, not enforced: a damaged parcel might still be
  /// deliverable and only the courier at the door can judge that.
  ///
  /// A broken seal is the exception — the backend moves the package to
  /// Returning on it, so carrying on is not a choice the courier has.
  bool get failsHopByDefault => switch (this) {
    DeliveryExceptionCode.weatherDelay => false,
    DeliveryExceptionCode.addressIncorrect => false,
    DeliveryExceptionCode.buyerUnreachable => false,
    _ => true,
  };

  bool get isCritical => this == DeliveryExceptionCode.sealBroken;
}

/// One leg of a parcel's journey, assigned to this courier.
class DeliveryHop {
  const DeliveryHop({
    required this.id,
    required this.packageId,
    required this.hopIndex,
    required this.tier,
    required this.courierProfileId,
    required this.state,
    required this.fromGeohash,
    required this.toGeohash,
    required this.payoutAmount,
    required this.payoutCurrency,
    this.acceptedUtc,
    this.pickedUpUtc,
    this.handedOffUtc,
    this.etaUtc,
    this.failureCode,
    this.failureNote,
    this.pickup,
    this.dropoff,
  });

  final String id;
  final String packageId;
  final int hopIndex;
  final DeliveryTier tier;
  final String courierProfileId;
  final HopState state;

  /// Exact ends of the hop, when the server sends them. The map falls back to
  /// the centre of [fromGeohash] / [toGeohash] without them.
  final DeliveryPlace? pickup;
  final DeliveryPlace? dropoff;
  final String fromGeohash;
  final String toGeohash;
  final double payoutAmount;
  final String payoutCurrency;
  final DateTime? acceptedUtc;
  final DateTime? pickedUpUtc;
  final DateTime? handedOffUtc;
  final DateTime? etaUtc;
  final DeliveryExceptionCode? failureCode;
  final String? failureNote;

  bool get isLate {
    final eta = etaUtc;
    if (eta == null || state.isFinished) return false;
    return DateTime.now().toUtc().isAfter(eta);
  }
}

/// What a courier has earned, from the hops they completed.
///
/// Deliberately separate from escrow. Escrow is the rider's own security
/// deposit — money they paid in and can withdraw again — and the two were the
/// only numbers the dashboard could show, so a courier had no way to see what
/// the work had actually paid. Showing a deposit under the word "earned"
/// would have been worse than showing nothing.
///
/// Not a withdrawable wallet either: nothing in the platform pays a courier
/// out yet, so this is the total earned and must be labelled as that.
class CourierEarnings {
  const CourierEarnings({
    required this.totalEarned,
    required this.last7Days,
    required this.last30Days,
    required this.completedHops,
    required this.currency,
    this.lastEarnedUtc,
  });

  /// What a courier with no completed hops has. Not null, because "nothing
  /// yet" is a number the screen can render, and a null would make every
  /// caller branch on a case that is normal on day one.
  const CourierEarnings.none()
    : totalEarned = 0,
      last7Days = 0,
      last30Days = 0,
      completedHops = 0,
      currency = '',
      lastEarnedUtc = null;

  final double totalEarned;
  final double last7Days;
  final double last30Days;
  final int completedHops;

  /// Empty until the first hop is completed — the server does not guess a
  /// currency for a rider who has not been paid in one yet.
  final String currency;
  final DateTime? lastEarnedUtc;

  bool get hasEarned => completedHops > 0;
}

/// One completed hop on the earnings history.
class CourierEarningRow {
  const CourierEarningRow({
    required this.hopId,
    required this.packageId,
    required this.hopIndex,
    required this.amount,
    required this.currency,
    required this.fromGeohash,
    required this.toGeohash,
    this.handedOffUtc,
  });

  final String hopId;
  final String packageId;
  final int hopIndex;
  final double amount;
  final String currency;
  final String fromGeohash;
  final String toGeohash;
  final DateTime? handedOffUtc;
}
