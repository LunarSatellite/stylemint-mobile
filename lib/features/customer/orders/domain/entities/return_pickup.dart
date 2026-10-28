import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum ReturnPickupStatus {
  requested,
  awaitingPickup,
  pickedUp,
  receivedByVendor,
  exception,
  cancelled;

  static ReturnPickupStatus fromCode(int value) => switch (value) {
    2 => ReturnPickupStatus.awaitingPickup,
    3 => ReturnPickupStatus.pickedUp,
    4 => ReturnPickupStatus.receivedByVendor,
    5 => ReturnPickupStatus.exception,
    6 => ReturnPickupStatus.cancelled,
    _ => ReturnPickupStatus.requested,
  };

  String get label => switch (this) {
    ReturnPickupStatus.requested => 'Pickup requested',
    ReturnPickupStatus.awaitingPickup => 'Courier pickup pending',
    ReturnPickupStatus.pickedUp => 'On the way to seller',
    ReturnPickupStatus.receivedByVendor => 'Received by seller',
    ReturnPickupStatus.exception => 'Pickup needs attention',
    ReturnPickupStatus.cancelled => 'Pickup cancelled',
  };
}

/// Return pickup contract §3 `stage` (strings). [unknown] is a value this
/// app does not know yet — the screens then show only the numeric state's
/// label, as they did before stages existed.
enum ReturnPickupStage {
  searchingRider('SearchingRider'),
  ridersInterested('RidersInterested'),
  noRiders('NoRiders'),
  riderAssigned('RiderAssigned'),
  awaitingBuyerConfirmation('AwaitingBuyerConfirmation'),
  collected('Collected'),
  awaitingSellerConfirmation('AwaitingSellerConfirmation'),
  receivedBySeller('ReceivedBySeller'),
  attemptFailed('AttemptFailed'),
  cancelled('Cancelled'),
  needsSupport('NeedsSupport'),
  unknown('');

  const ReturnPickupStage(this.wire);

  final String wire;

  /// Null when absent (an older backend); [unknown] when sent but not known.
  static ReturnPickupStage? fromWire(Object? value) {
    final raw = value?.toString().trim().toLowerCase().replaceAll('_', '');
    if (raw == null || raw.isEmpty) return null;
    for (final stage in values) {
      if (stage != unknown && stage.wire.toLowerCase() == raw) return stage;
    }
    return unknown;
  }

  /// Still looking for a rider.
  bool get isSearching =>
      this == searchingRider || this == ridersInterested || this == noRiders;

  /// A rider is on the job (going to the buyer, or bringing it back).
  bool get riderOnJob =>
      this == riderAssigned ||
      this == awaitingBuyerConfirmation ||
      this == collected ||
      this == awaitingSellerConfirmation;

  /// Nothing more will move without someone acting.
  bool get isSettled =>
      this == receivedBySeller ||
      this == cancelled ||
      this == needsSupport ||
      this == unknown;
}

/// `mode`: a rider return, or one approved before riders were asked
/// automatically (contract D6). [unknown] for an older backend that sends no
/// mode at all — the app then offers no rider actions.
enum ReturnPickupMode {
  rider,
  legacy,
  unknown;

  static ReturnPickupMode fromWire(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'rider' || '1' => ReturnPickupMode.rider,
        'legacy' || '2' => ReturnPickupMode.legacy,
        _ => ReturnPickupMode.unknown,
      };
}

/// Who pays the pickup fare (contract §1).
enum ReturnFarePayer {
  seller,
  buyer,
  unknown;

  static ReturnFarePayer fromWire(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'seller' || 'vendor' => ReturnFarePayer.seller,
        'buyer' || 'customer' => ReturnFarePayer.buyer,
        _ => ReturnFarePayer.unknown,
      };
}

class ReturnPickupRider {
  const ReturnPickupRider({
    required this.displayName,
    this.avatarUrl,
    this.rating,
    this.vehicle,
  });

  final String displayName;
  final String? avatarUrl;
  final double? rating;
  final String? vehicle;
}

class ReturnPickupFare {
  const ReturnPickupFare({
    required this.payer,
    this.amount,
    this.upTo,
    this.isFinal = false,
  });

  final ReturnFarePayer payer;

  /// The fare, once a rider's offer fixed it; null before.
  final Money? amount;

  /// The most the buyer can be charged (contract D2).
  final Money? upTo;
  final bool isFinal;
}

/// Reverse logistics for one return: `GET /v1/deliveries/returns/{id}` for
/// the buyer, `GET /v1/vendor/returns/{id}/pickup` for the seller.
///
/// Every field added by the return pickup contract is optional, so an older
/// payload still parses into the card it always drew.
class ReturnPickup {
  const ReturnPickup({
    required this.id,
    required this.returnRequestId,
    required this.trackingNumber,
    required this.status,
    required this.originAddressLine,
    required this.destinationAddressLine,
    required this.requestedUtc,
    this.pickedUpUtc,
    this.receivedUtc,
    this.stage,
    this.mode = ReturnPickupMode.unknown,
    this.packageId,
    this.requestExpiresUtc,
    this.rider,
    this.failedAttempts = 0,
    this.maxAttempts = 3,
    this.lastFailureCode,
    this.collectionPhotoUrls = const [],
    this.fare,
    this.canCancel = false,
    this.canRetry = false,
  });

  factory ReturnPickup.fromJson(Map<String, dynamic> json) {
    final rider = json['rider'];
    final attempts = json['attempts'];
    final fare = json['fare'];
    return ReturnPickup(
      id: json['id'] as String? ?? '',
      returnRequestId: json['returnRequestId'] as String? ?? '',
      trackingNumber: json['trackingNumber'] as String? ?? '',
      status: ReturnPickupStatus.fromCode(_int(json['state']) ?? 1),
      originAddressLine: json['originAddressLine'] as String? ?? '',
      destinationAddressLine: json['destinationAddressLine'] as String? ?? '',
      requestedUtc:
          _date(json['requestedUtc']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      pickedUpUtc: _date(json['pickedUpUtc']),
      receivedUtc: _date(json['receivedUtc']),
      stage: ReturnPickupStage.fromWire(json['stage']),
      mode: ReturnPickupMode.fromWire(json['mode']),
      packageId: _text(json['packageId']),
      requestExpiresUtc: _date(json['requestExpiresUtc']),
      rider: rider is Map
          ? ReturnPickupRider(
              displayName: _text(rider['displayName']) ?? 'Your rider',
              avatarUrl: _text(rider['avatarUrl']),
              rating: _double(rider['rating']),
              vehicle: _text(rider['vehicle']),
            )
          : null,
      failedAttempts: attempts is Map ? _int(attempts['failed']) ?? 0 : 0,
      maxAttempts: attempts is Map ? _int(attempts['max']) ?? 3 : 3,
      lastFailureCode: attempts is Map
          ? _text(attempts['lastFailureCode'])
          : null,
      collectionPhotoUrls: (json['collectionPhotoUrls'] is List
              ? json['collectionPhotoUrls'] as List<dynamic>
              : const <dynamic>[])
          .map(_text)
          .whereType<String>()
          .toList(growable: false),
      fare: fare is Map
          ? ReturnPickupFare(
              payer: ReturnFarePayer.fromWire(fare['payer']),
              amount: moneyFromJson(fare['amount']),
              upTo: moneyFromJson(fare['upTo']),
              isFinal: fare['isFinal'] == true,
            )
          : null,
      canCancel: json['canCancel'] == true,
      canRetry: json['canRetry'] == true,
    );
  }

  final String id;
  final String returnRequestId;
  final String trackingNumber;
  final ReturnPickupStatus status;
  final String originAddressLine;
  final String destinationAddressLine;
  final DateTime requestedUtc;
  final DateTime? pickedUpUtc;
  final DateTime? receivedUtc;

  /// Null from a backend before the return pickup contract.
  final ReturnPickupStage? stage;
  final ReturnPickupMode mode;
  final String? packageId;
  final DateTime? requestExpiresUtc;
  final ReturnPickupRider? rider;
  final int failedAttempts;
  final int maxAttempts;

  /// `BuyerUnreachable`, `AddressIncorrect`, … — shown as sent.
  final String? lastFailureCode;
  final List<String> collectionPhotoUrls;
  final ReturnPickupFare? fare;
  final bool canCancel;
  final bool canRetry;

  bool get isRider => mode == ReturnPickupMode.rider;
  bool get isLegacy => mode == ReturnPickupMode.legacy;

  /// The seller may only mark a rider return received once the rider handed
  /// it over (contract §3, `return.pickup_not_received`). Legacy and older
  /// returns are never held back here; the server still has the last word.
  bool get blocksSellerCompletion =>
      isRider &&
      receivedUtc == null &&
      stage != null &&
      stage != ReturnPickupStage.receivedBySeller &&
      stage != ReturnPickupStage.unknown;

  static String? _text(Object? value) {
    final raw = value?.toString().trim();
    return raw == null || raw.isEmpty ? null : raw;
  }

  static int? _int(Object? value) => switch (value) {
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };

  static double? _double(Object? value) => switch (value) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v),
    _ => null,
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}

/// `{ amount, currency }` → [Money]; a bare number is read as NPR. Null when
/// absent.
Money? moneyFromJson(Object? value) {
  if (value is num) return Money(amount: value.toDouble(), currency: 'NPR');
  if (value is! Map) return null;
  final amount = switch (value['amount']) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v),
    _ => null,
  };
  if (amount == null) return null;
  final currency = value['currency']?.toString().trim();
  return Money(
    amount: amount,
    currency: currency == null || currency.isEmpty ? 'NPR' : currency,
  );
}
