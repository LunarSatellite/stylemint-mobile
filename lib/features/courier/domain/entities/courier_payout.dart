import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_fare.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// What a rider is owed and owes — `CourierBalanceDto`, rider-payout
/// contract v1 §2–3.
///
/// Four numbers, and the screen has to keep them apart:
///
/// * [pendingEarnings] — fares inside the settle window, or on hold.
/// * [availableEarnings] — settled fares, what a payout draws on.
/// * [cashToRemit] — COD / EMI cash the rider took at the door and has not
///   handed in. A debt, not pay.
/// * [netPayable] — available minus cash to remit: what a payout pays.
///   Negative means the rider owes the platform.
///
/// None of it is the courier's escrow deposit, which is their own money and
/// lives on a different endpoint.
class CourierBalance {
  const CourierBalance({
    required this.pendingEarnings,
    required this.onHoldEarnings,
    required this.availableEarnings,
    required this.cashToRemit,
    required this.netPayable,
    required this.lifetimeEarnings,
    required this.currency,
    this.settleAfterHours,
    this.onDemandMinAmount,
    this.onDemandMaxAmount,
    this.onDemandFeePercent,
    this.hasDefaultDestination = false,
    this.inFlightPayout,
  });

  final double pendingEarnings;
  final double onHoldEarnings;
  final double availableEarnings;
  final double cashToRemit;
  final double netPayable;
  final double lifetimeEarnings;
  final String currency;
  final int? settleAfterHours;
  final double? onDemandMinAmount;
  final double? onDemandMaxAmount;
  final double? onDemandFeePercent;
  final bool hasDefaultDestination;

  /// A payout already on its way. While there is one the server refuses a
  /// new request, so the screen says so instead of offering the button.
  final CourierPayout? inFlightPayout;

  Money money(double amount) => Money(amount: amount, currency: currency);

  bool get owesCash => netPayable < 0;

  /// Whether a rider could ask for a payout now, before the server's own
  /// checks: something to pay, nothing in flight.
  bool get canRequest => netPayable > 0 && inFlightPayout == null;

  /// The fee the server would take from [amount] on demand, rounded up to
  /// the cent as the contract says. Null when the server sent no rate.
  double? feeFor(double amount) {
    final percent = onDemandFeePercent;
    if (percent == null) return null;
    return (amount * percent).ceilToDouble() / 100;
  }
}

/// `CourierEarningStatus` — where one delivery's fare stands.
enum CourierEarningStatus {
  pending(1),
  onHold(2),
  available(3),
  reversed(4),
  unknown(0);

  const CourierEarningStatus(this.wire);

  final int wire;

  static CourierEarningStatus fromWire(Object? value) {
    final number = switch (value) {
      final num v => v.toInt(),
      final String v => int.tryParse(v.trim()),
      _ => null,
    };
    if (number != null) {
      return values.firstWhere(
        (s) => s.wire == number,
        orElse: () => CourierEarningStatus.unknown,
      );
    }
    final raw = value?.toString().trim().toLowerCase().replaceAll('_', '');
    for (final status in values) {
      if (status.name.toLowerCase() == raw) return status;
    }
    return CourierEarningStatus.unknown;
  }

  String get label => switch (this) {
    CourierEarningStatus.pending => 'Pending',
    CourierEarningStatus.onHold => 'On hold',
    CourierEarningStatus.available => 'Available',
    CourierEarningStatus.reversed => 'Reversed',
    CourierEarningStatus.unknown => 'Recorded',
  };
}

/// One line of an earning's `fareBreakdown.lines` (rider-payout contract
/// v1): free codes, render label + amount.
class FareLine {
  const FareLine({required this.code, required this.label, required this.amount});

  final String code;
  final String label;
  final double amount;
}

/// One completed delivery leg on the payout ledger — `CourierEarningRowDto`.
class CourierPayoutEarning {
  const CourierPayoutEarning({
    required this.entryId,
    required this.hopId,
    required this.amount,
    required this.currency,
    required this.status,
    this.packageId,
    this.trackingNumber,
    this.holdReason,
    this.completedUtc,
    this.settleAfterUtc,
    this.settledUtc,
    this.reversedUtc,
    this.cashCollected,
    this.fare,
    this.lines = const [],
    this.fareMethodRoad,
    this.fareDistanceKm,
    this.fareTier,
  });

  final String entryId;
  final String hopId;
  final String? packageId;
  final String? trackingNumber;
  final double amount;
  final String currency;
  final CourierEarningStatus status;
  final String? holdReason;
  final DateTime? completedUtc;
  final DateTime? settleAfterUtc;
  final DateTime? settledUtc;
  final DateTime? reversedUtc;

  /// Cash the rider took at the door on this leg; null when none.
  final double? cashCollected;

  /// The full rider-fare breakdown, when the row carries one.
  final FareBreakdown? fare;

  /// The ledger's own `{code, label, amount}` lines, when that is what the
  /// row carries instead.
  final List<FareLine> lines;

  /// With [lines] (rider-payout contract v2): true = road km, false =
  /// estimated, null = a fare from before the road-distance fare.
  final bool? fareMethodRoad;
  final double? fareDistanceKm;

  /// "Pro" | "Traveler" | "Neighbor" as the server spells it.
  final String? fareTier;

  /// Whether there is more to show than the amount: several lines, or how
  /// the distance was priced.
  bool get hasFareDetail =>
      (fare?.isItemised ?? false) || lines.length > 1 || fareMethodRoad != null;

  Money get money => Money(amount: amount, currency: currency);
}

/// `PayoutState`, as a rider should read it.
enum CourierPayoutState {
  requested(1),
  processing(2),
  paid(3),
  failed(4),
  held(5),
  awaitingTransfer(6),
  unknown(0);

  const CourierPayoutState(this.wire);

  final int wire;

  static CourierPayoutState fromWire(Object? value) {
    final number = switch (value) {
      final num v => v.toInt(),
      final String v => int.tryParse(v.trim()),
      _ => null,
    };
    if (number != null) {
      return values.firstWhere(
        (s) => s.wire == number,
        orElse: () => CourierPayoutState.unknown,
      );
    }
    final raw = value?.toString().trim().toLowerCase().replaceAll('_', '');
    if (raw == 'awaitingmanualtransfer') return awaitingTransfer;
    for (final state in values) {
      if (state.name.toLowerCase() == raw) return state;
    }
    return CourierPayoutState.unknown;
  }

  String get label => switch (this) {
    CourierPayoutState.requested => 'Requested',
    CourierPayoutState.processing => 'Processing',
    CourierPayoutState.paid => 'Paid',
    CourierPayoutState.failed => 'Failed',
    CourierPayoutState.held => 'On hold',
    CourierPayoutState.awaitingTransfer => 'Awaiting transfer',
    CourierPayoutState.unknown => 'In progress',
  };

  bool get isFinished =>
      this == CourierPayoutState.paid || this == CourierPayoutState.failed;
}

/// A payout to the rider — `PayoutDto`.
class CourierPayout {
  const CourierPayout({
    required this.id,
    required this.state,
    required this.requestedAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.currency,
    this.automatic = false,
    this.destinationKind,
    this.destinationRef,
    this.requestedUtc,
    this.pendingUntilUtc,
    this.paidUtc,
    this.reference,
    this.failureCode,
    this.failureMessage,
  });

  final String id;
  final CourierPayoutState state;
  final double requestedAmount;
  final double feeAmount;
  final double netAmount;
  final String currency;

  /// The Friday batch rather than a request the rider made.
  final bool automatic;

  /// `PayoutDestinationKind` wire value (1 NIMB, 2 Laxmi, 3 PayPal, 4 eSewa).
  final int? destinationKind;

  /// Already masked by the server.
  final String? destinationRef;
  final DateTime? requestedUtc;
  final DateTime? pendingUntilUtc;
  final DateTime? paidUtc;

  /// The bank / wallet transfer reference finance recorded when paying.
  final String? reference;
  final String? failureCode;
  final String? failureMessage;

  Money money(double amount) => Money(amount: amount, currency: currency);

  /// Why it failed, in words the rider can act on.
  String? get failureReason => failureMessage ?? failureCode;
}

/// A cursor page from the payout endpoints (`PagedResult<T>`).
class CourierPage<T> {
  const CourierPage({required this.items, this.nextCursor, this.hasMore = false});

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}
