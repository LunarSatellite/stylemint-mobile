class ShippingAddress {
  const ShippingAddress({
    required this.id,
    required this.label,
    required this.receiverName,
    required this.receiverPhone,
    required this.addressLine1,
    this.landmark,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.isDefault,
    this.rowVersion = '',
  });

  final String id;
  final String label;
  final String receiverName;
  final String receiverPhone;
  final String addressLine1;
  final String? landmark;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;
  final String rowVersion;

  ShippingAddress copyWith({
    String? id,
    String? label,
    String? receiverName,
    String? receiverPhone,
    String? addressLine1,
    String? landmark,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool? isDefault,
    String? rowVersion,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      addressLine1: addressLine1 ?? this.addressLine1,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      rowVersion: rowVersion ?? this.rowVersion,
    );
  }
}
