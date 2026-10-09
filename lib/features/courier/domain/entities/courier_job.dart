import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Where a rider's job stands. Mirrors the delivery-complete contract's
/// `CourierJobDto.status` (strings).
///
/// Drives the job screen's one primary action, so an unknown value reads as
/// [assigned] — the earliest state, whose action ("Picked up") the server
/// refuses if it is wrong — rather than skipping a step the rider still owes.
enum CourierJobStatus {
  assigned,
  pickedUp,
  awaitingConfirmation,
  delivered,
  cancelled;

  static CourierJobStatus fromWire(Object? value) {
    final raw = value?.toString().trim().toLowerCase().replaceAll('_', '');
    for (final status in values) {
      if (status.name.toLowerCase() == raw) return status;
    }
    return CourierJobStatus.assigned;
  }

  String get label => switch (this) {
    CourierJobStatus.assigned => 'Go to the pick-up',
    CourierJobStatus.pickedUp => 'On the way to drop-off',
    CourierJobStatus.awaitingConfirmation => 'Waiting for the recipient',
    CourierJobStatus.delivered => 'Delivered',
    CourierJobStatus.cancelled => 'Cancelled',
  };

  /// Nothing left for the rider to do.
  bool get isFinished =>
      this == CourierJobStatus.delivered || this == CourierJobStatus.cancelled;

  /// The parcel is with the rider, so the drop-off is where they are going.
  bool get headingToDropoff =>
      this == CourierJobStatus.pickedUp ||
      this == CourierJobStatus.awaitingConfirmation;
}

/// A latitude/longitude pair. Pure Dart, so the domain does not depend on the
/// map package's own type.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// One end of a job: the shop, or the recipient's door.
class CourierJobStop {
  const CourierJobStop({
    required this.point,
    this.label,
    this.addressLine,
    this.contactName,
    this.contactPhone,
  });

  /// Null when the server sent no usable coordinates — the card still shows
  /// the address, the map just has no pin for it.
  final GeoPoint? point;

  /// Shop name for the pick-up, recipient name for the drop-off.
  final String? label;
  final String? addressLine;
  final String? contactName;

  /// Only ever sent to the assigned rider.
  final String? contactPhone;
}

class CourierJobItem {
  const CourierJobItem({
    required this.name,
    required this.quantity,
    this.imageUrl,
  });

  final String name;
  final int quantity;
  final String? imageUrl;
}

/// A delivery the rider has been given: what it is, where it goes, and what
/// it pays. `GET /v1/courier/jobs/{hopId}`.
class CourierJob {
  const CourierJob({
    required this.hopId,
    required this.packageId,
    required this.packageNumber,
    required this.status,
    required this.items,
    required this.itemCount,
    required this.pickup,
    required this.dropoff,
    this.assignedUtc,
    this.pickedUpUtc,
    this.deliveredUtc,
    this.payout,
    this.cashToCollect,
    this.declaredValue,
    this.notes,
    this.distanceKm,
  });

  final String hopId;
  final String packageId;

  /// `SM-D-00000013` — what the rider reads out at the shop and the door.
  final String packageNumber;
  final CourierJobStatus status;
  final DateTime? assignedUtc;
  final DateTime? pickedUpUtc;
  final DateTime? deliveredUtc;
  final Money? payout;

  /// Cash on delivery: what the rider must collect at the door. Null when the
  /// order is prepaid.
  final Money? cashToCollect;
  final List<CourierJobItem> items;
  final int itemCount;
  final Money? declaredValue;
  final String? notes;
  final CourierJobStop pickup;
  final CourierJobStop dropoff;
  final double? distanceKm;
}

/// Mirrors `DeliveryProofDto.status`. Unknown reads as [pending]: the screen
/// keeps polling, which is the safe thing to do with an answer it cannot read.
enum DeliveryProofStatus {
  pending,
  confirmed,
  expired;

  static DeliveryProofStatus fromWire(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    for (final status in values) {
      if (status.name == raw) return status;
    }
    return DeliveryProofStatus.pending;
  }
}

/// The proof-of-delivery code the rider shows at the door: a QR the recipient
/// scans, and a 6-digit fallback they can type.
class DeliveryProof {
  const DeliveryProof({
    required this.hopId,
    required this.packageNumber,
    required this.status,
    required this.qrPayload,
    required this.code,
    this.expiresUtc,
    this.confirmedUtc,
  });

  final String hopId;
  final String packageNumber;
  final DeliveryProofStatus status;

  /// `https://stylemint.voyageritnepal.com/dc/<token>`.
  final String qrPayload;
  final String code;
  final DateTime? expiresUtc;
  final DateTime? confirmedUtc;

  /// Expired by the server's word or by the clock. The clock matters: the
  /// screen should stop presenting a dead code the moment it dies, not at
  /// the next poll.
  bool isExpiredAt(DateTime now) =>
      status == DeliveryProofStatus.expired ||
      (status == DeliveryProofStatus.pending &&
          expiresUtc != null &&
          !expiresUtc!.isAfter(now));

  Duration remainingAt(DateTime now) {
    final expires = expiresUtc;
    if (expires == null) return Duration.zero;
    final left = expires.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// A drawable route between the rider, the pick-up and the drop-off.
class CourierRoute {
  const CourierRoute({
    required this.path,
    this.distanceMetres,
    this.durationSeconds,
  });

  final List<GeoPoint> path;
  final double? distanceMetres;
  final double? durationSeconds;
}

/// Plans a road route through [CourierRoute] stops. Null on any failure — the
/// map then draws straight lines, so routing is never what stops a rider.
abstract interface class CourierRoutePlanner {
  Future<CourierRoute?> plan(List<GeoPoint> stops);
}
