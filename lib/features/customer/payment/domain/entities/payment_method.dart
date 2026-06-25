enum PaymentType { card, eSewa, cod }

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.lastFour,
    this.expiryDate,
    this.cardholderName,
    required this.isDefault,
  });

  final String id;
  final PaymentType type;
  final String label;
  final String? lastFour;
  final String? expiryDate;
  final String? cardholderName;
  final bool isDefault;

  PaymentMethod copyWith({
    String? id,
    PaymentType? type,
    String? label,
    String? lastFour,
    String? expiryDate,
    String? cardholderName,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      lastFour: lastFour ?? this.lastFour,
      expiryDate: expiryDate ?? this.expiryDate,
      cardholderName: cardholderName ?? this.cardholderName,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
