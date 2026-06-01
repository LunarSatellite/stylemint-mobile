import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';

part 'shipping_address_dto.freezed.dart';
part 'shipping_address_dto.g.dart';

@freezed
abstract class ShippingAddressDto with _$ShippingAddressDto {
  const factory ShippingAddressDto({
    required String id,
    @Default('Home') String label,
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String zipCode,
    @Default(false) bool isDefault,
  }) = _ShippingAddressDto;

  const ShippingAddressDto._();

  factory ShippingAddressDto.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressDtoFromJson(json);

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'fullName': fullName,
    'phone': phone,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'state': state,
    'zipCode': zipCode,
    'isDefault': isDefault,
  };

  ShippingAddress toDomain() => ShippingAddress(
    id: id,
    label: label,
    fullName: fullName,
    phone: phone,
    addressLine1: addressLine1,
    addressLine2: addressLine2,
    city: city,
    state: state,
    zipCode: zipCode,
    isDefault: isDefault,
  );
}
