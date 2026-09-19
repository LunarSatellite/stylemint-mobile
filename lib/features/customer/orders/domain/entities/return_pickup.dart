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
  });

  factory ReturnPickup.fromJson(Map<String, dynamic> json) => ReturnPickup(
    id: json['id'] as String? ?? '',
    returnRequestId: json['returnRequestId'] as String? ?? '',
    trackingNumber: json['trackingNumber'] as String? ?? '',
    status: ReturnPickupStatus.fromCode(json['state'] as int? ?? 1),
    originAddressLine: json['originAddressLine'] as String? ?? '',
    destinationAddressLine: json['destinationAddressLine'] as String? ?? '',
    requestedUtc:
        DateTime.tryParse(json['requestedUtc'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    pickedUpUtc: DateTime.tryParse(json['pickedUpUtc'] as String? ?? ''),
    receivedUtc: DateTime.tryParse(json['receivedUtc'] as String? ?? ''),
  );

  final String id;
  final String returnRequestId;
  final String trackingNumber;
  final ReturnPickupStatus status;
  final String originAddressLine;
  final String destinationAddressLine;
  final DateTime requestedUtc;
  final DateTime? pickedUpUtc;
  final DateTime? receivedUtc;
}
