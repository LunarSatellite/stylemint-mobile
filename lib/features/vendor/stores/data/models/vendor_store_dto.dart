import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store_draft.dart';

/// Wire shape of backend `VendorStoreVm`: `{ id, name, addressLine, city,
/// latitude?, longitude?, phone?, isActive, createdUtc }`.
class VendorStoreDto {
  const VendorStoreDto({
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

  factory VendorStoreDto.fromJson(Map<String, dynamic> json) => VendorStoreDto(
    id: readString(json['id']),
    name: readString(json['name']),
    addressLine: readString(json['addressLine']),
    city: readString(json['city']),
    latitude: readOptionalDouble(json['latitude']),
    longitude: readOptionalDouble(json['longitude']),
    phone: readOptionalString(json['phone']),
    // A store is active unless the backend says otherwise.
    isActive: !json.containsKey('isActive') || readBool(json['isActive']),
    createdUtc: readDate(json['createdUtc']),
  );

  /// The `items` of a `PagedResult<VendorStoreVm>`; stores without an id
  /// are dropped.
  static List<VendorStoreDto> listFromPage(Object? raw) => readPagedItems(raw)
      .map(VendorStoreDto.fromJson)
      .where((store) => store.id.isNotEmpty)
      .toList(growable: false);

  /// The `CreateVendorStoreVm` / `UpdateVendorStoreVm` body.
  static Map<String, dynamic> draftToJson(VendorStoreDraft draft) {
    final d = draft.normalized();
    return <String, dynamic>{
      'name': d.name,
      'addressLine': d.addressLine,
      'city': d.city,
      'latitude': d.latitude,
      'longitude': d.longitude,
      'phone': d.phone,
    };
  }

  final String id;
  final String name;
  final String addressLine;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final bool isActive;
  final DateTime? createdUtc;

  VendorStore toDomain() => VendorStore(
    id: id,
    name: name,
    addressLine: addressLine,
    city: city,
    latitude: latitude,
    longitude: longitude,
    phone: phone,
    isActive: isActive,
    createdUtc: createdUtc,
  );
}
