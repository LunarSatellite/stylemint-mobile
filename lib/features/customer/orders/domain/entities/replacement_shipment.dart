enum ReplacementShipmentStatus {
  readyToShip,
  shipped,
  delivered,
  cancelled;

  static ReplacementShipmentStatus fromCode(int value) => switch (value) {
    2 => ReplacementShipmentStatus.shipped,
    3 => ReplacementShipmentStatus.delivered,
    4 => ReplacementShipmentStatus.cancelled,
    _ => ReplacementShipmentStatus.readyToShip,
  };

  String get label => switch (this) {
    ReplacementShipmentStatus.readyToShip => 'Ready to ship',
    ReplacementShipmentStatus.shipped => 'Replacement on the way',
    ReplacementShipmentStatus.delivered => 'Replacement delivered',
    ReplacementShipmentStatus.cancelled => 'Replacement cancelled',
  };
}

class ReplacementShipment {
  const ReplacementShipment({
    required this.id,
    required this.returnRequestId,
    required this.replacementVariantId,
    required this.trackingNumber,
    required this.status,
    required this.quantity,
    required this.originAddressLine,
    required this.destinationAddressLine,
    required this.readyUtc,
    this.shippedUtc,
    this.deliveredUtc,
  });

  factory ReplacementShipment.fromJson(Map<String, dynamic> json) =>
      ReplacementShipment(
        id: json['id'] as String? ?? '',
        returnRequestId: json['returnRequestId'] as String? ?? '',
        replacementVariantId: json['replacementVariantId'] as String? ?? '',
        trackingNumber: json['trackingNumber'] as String? ?? '',
        status: ReplacementShipmentStatus.fromCode(json['state'] as int? ?? 1),
        quantity: json['quantity'] as int? ?? 1,
        originAddressLine: json['originAddressLine'] as String? ?? '',
        destinationAddressLine: json['destinationAddressLine'] as String? ?? '',
        readyUtc:
            DateTime.tryParse(json['readyUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        shippedUtc: DateTime.tryParse(json['shippedUtc'] as String? ?? ''),
        deliveredUtc: DateTime.tryParse(json['deliveredUtc'] as String? ?? ''),
      );

  final String id;
  final String returnRequestId;
  final String replacementVariantId;
  final String trackingNumber;
  final ReplacementShipmentStatus status;
  final int quantity;
  final String originAddressLine;
  final String destinationAddressLine;
  final DateTime readyUtc;
  final DateTime? shippedUtc;
  final DateTime? deliveredUtc;
}
