import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';

part 'shipping_address_dto.freezed.dart';
part 'shipping_address_dto.g.dart';

@freezed
abstract class ShippingAddressDto with _$ShippingAddressDto {
  const factory ShippingAddressDto({
    required String id,
    @Default('') String accountId,
    @Default('Home') String label,
    required String line1,
    String? line2,
    required String city,
    String? stateProvince,
    String? postalCode,
    required String countryCode,
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
    'line1': line1,
    if (line2 != null && line2!.isNotEmpty) 'line2': line2,
    'city': city,
    if (stateProvince != null && stateProvince!.isNotEmpty) 'stateProvince': stateProvince,
    if (postalCode != null && postalCode!.isNotEmpty) 'postalCode': postalCode,
    'countryCode': countryCode,
    'isDefault': isDefault,
    if (rowVersion.isNotEmpty) 'rowVersion': rowVersion,
  };

  ShippingAddress toDomain() => ShippingAddress(
    id: id,
    label: label,
    line1: line1,
    line2: line2,
    city: city,
    stateProvince: stateProvince,
    postalCode: postalCode,
    countryCode: countryCode,
    isDefault: isDefault,
    rowVersion: rowVersion,
  );
}
