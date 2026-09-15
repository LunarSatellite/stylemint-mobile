/// A vendor's physical store or branch (backend `VendorStoreVm`).
class VendorStore {
  const VendorStore({
    required this.id,
    required this.name,
    required this.addressLine,
    required this.city,
    this.latitude,
    this.longitude,
    this.phone,
    this.isActive = true,
    this.createdUtc,
  });

  final String id;
  final String name;
  final String addressLine;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? phone;

  /// False once archived; archived stores get no new codes.
  final bool isActive;
  final DateTime? createdUtc;

  /// `Address line, City`.
  String get addressSummary =>
      [addressLine, city].where((part) => part.isNotEmpty).join(', ');
}
