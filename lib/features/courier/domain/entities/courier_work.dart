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

/// A hop the router is offering, in a Dutch auction: each round raises the
/// payout, so an offer left to expire may come back worth more. It also means
/// an offer has a hard deadline, which is why [expiresUtc] is shown as a
/// countdown rather than a timestamp.
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
  });

  final String id;
  final String packageId;
  final DeliveryTier tier;
  final int hopIndex;

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
  });

  final String id;
  final String packageId;
  final int hopIndex;
  final DeliveryTier tier;
  final String courierProfileId;
  final HopState state;
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
