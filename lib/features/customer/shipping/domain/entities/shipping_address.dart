class ShippingAddress {
  const ShippingAddress({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    this.stateProvince,
    this.postalCode,
    required this.countryCode,
    required this.isDefault,
    this.rowVersion = '',
  });

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String? stateProvince;
  final String? postalCode;
  final String countryCode;
  final bool isDefault;
  final String rowVersion;

  ShippingAddress copyWith({
    String? id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? stateProvince,
    String? postalCode,
    String? countryCode,
    bool? isDefault,
    String? rowVersion,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      stateProvince: stateProvince ?? this.stateProvince,
      postalCode: postalCode ?? this.postalCode,
      countryCode: countryCode ?? this.countryCode,
      isDefault: isDefault ?? this.isDefault,
      rowVersion: rowVersion ?? this.rowVersion,
    );
  }
}
