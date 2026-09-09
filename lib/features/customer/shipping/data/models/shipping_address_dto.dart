import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';

part 'shipping_address_dto.freezed.dart';
part 'shipping_address_dto.g.dart';

/// Maps `ShippingAddressDto` from `StyleMint.Modules.CartCheckout`
/// (`/v1/addresses`) — the real, checkout-connected address book. Field
/// names match the backend's actual wire shape (`addressLine1`/`state`/
/// `zipCode`/`country`/`receiverName`/`receiverPhone`), not the old
/// `line1`/`stateProvince`/`postalCode`/`countryCode` guess that pointed at
/// Identity's dead-end `/v1/accounts/{id}/addresses` book.
@freezed
abstract class ShippingAddressDto with _$ShippingAddressDto {
  const factory ShippingAddressDto({
    required String id,
    @Default('') String accountId,
    @Default('Home') String label,
    @Default('') String receiverName,
    @Default('') String receiverPhone,
    required String addressLine1,
    String? landmark,
    @Default('NP') String country,
    @Default('') String state,
    required String city,
    @Default('') String zipCode,
    double? latitude,
    double? longitude,
    @Default(false) bool isDefault,
    @Default('') String rowVersion,
    DateTime? createdUtc,
    DateTime? updatedUtc,
  }) = _ShippingAddressDto;

  const ShippingAddressDto._();

  factory ShippingAddressDto.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressDtoFromJson(json);

  // Manual toJson sends only the write fields the API expects.
  Map<String, dynamic> toJson() => {
    'label': label,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'addressLine1': addressLine1,
    if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
    'country': country,
    'state': state,
    'city': city,
    'zipCode': zipCode,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  ShippingAddress toDomain() => ShippingAddress(
    id: id,
    label: label,
    receiverName: receiverName,
    receiverPhone: receiverPhone,
    addressLine1: addressLine1,
    landmark: landmark,
    city: city,
    state: state,
    zipCode: zipCode,
    country: country,
    isDefault: isDefault,
    rowVersion: rowVersion,
  );
}
