enum PaymentType { card, eSewa, cod }

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.lastFour,
    this.expiryDate,
    required this.isDefault,
  });

  final String id;
  final PaymentType type;
  final String label;
  final String? lastFour;
  final String? expiryDate;
  final bool isDefault;

  PaymentMethod copyWith({
    String? id,
    PaymentType? type,
    String? label,
    String? lastFour,
    String? expiryDate,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      lastFour: lastFour ?? this.lastFour,
      expiryDate: expiryDate ?? this.expiryDate,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
