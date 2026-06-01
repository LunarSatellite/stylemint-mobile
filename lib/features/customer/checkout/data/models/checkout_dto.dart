import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'checkout_dto.freezed.dart';
part 'checkout_dto.g.dart';

@freezed
abstract class ShippingAddressDto with _$ShippingAddressDto {
  const factory ShippingAddressDto({
    required String id,
    required String label,
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String zipCode,
    required bool isDefault,
  }) = _ShippingAddressDto;

  const ShippingAddressDto._();

  factory ShippingAddressDto.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressDtoFromJson(json);

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

@freezed
abstract class PaymentMethodDto with _$PaymentMethodDto {
  const factory PaymentMethodDto({
    required String id,
    required String type,
    required String label,
    String? lastFour,
    required bool isDefault,
  }) = _PaymentMethodDto;

  const PaymentMethodDto._();

  factory PaymentMethodDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodDtoFromJson(json);

  PaymentMethod toDomain() => PaymentMethod(
        id: id,
        type: _typeFromCode(type),
        label: label,
        lastFour: lastFour,
        isDefault: isDefault,
      );

  static PaymentMethodType _typeFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'card':
        return PaymentMethodType.card;
      case 'esewa':
        return PaymentMethodType.eSewa;
      case 'cod':
        return PaymentMethodType.cod;
      default:
        return PaymentMethodType.cod;
    }
  }
}

@freezed
abstract class CheckoutItemDto with _$CheckoutItemDto {
  const factory CheckoutItemDto({
    required String productId,
    required String productName,
    required String imageUrl,
    required String variantName,
    required int quantity,
    required double unitPriceAmount,
    @Default('NPR') String unitPriceCurrency,
  }) = _CheckoutItemDto;

  const CheckoutItemDto._();

  factory CheckoutItemDto.fromJson(Map<String, dynamic> json) =>
      _$CheckoutItemDtoFromJson(json);

  CheckoutItem toDomain() => CheckoutItem(
        productId: productId,
        productName: productName,
        imageUrl: imageUrl,
        variantName: variantName,
        quantity: quantity,
        unitPrice: Money(amount: unitPriceAmount, currency: unitPriceCurrency),
      );
}

@freezed
abstract class CheckoutSummaryDto with _$CheckoutSummaryDto {
  const factory CheckoutSummaryDto({
    required ShippingAddressDto shippingAddress,
    required PaymentMethodDto paymentMethod,
    @Default(<CheckoutItemDto>[]) List<CheckoutItemDto> items,
    required double subtotalAmount,
    @Default('NPR') String subtotalCurrency,
    required double shippingAmount,
    @Default('NPR') String shippingCurrency,
    required double taxAmount,
    @Default('NPR') String taxCurrency,
    required double discountAmount,
    @Default('NPR') String discountCurrency,
    required double totalAmount,
    @Default('NPR') String totalCurrency,
  }) = _CheckoutSummaryDto;

  const CheckoutSummaryDto._();

  factory CheckoutSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$CheckoutSummaryDtoFromJson(json);

  CheckoutSummary toDomain() => CheckoutSummary(
        shippingAddress: shippingAddress.toDomain(),
        paymentMethod: paymentMethod.toDomain(),
        items: items.map((dto) => dto.toDomain()).toList(growable: false),
        subtotal: Money(amount: subtotalAmount, currency: subtotalCurrency),
        shipping: Money(amount: shippingAmount, currency: shippingCurrency),
        tax: Money(amount: taxAmount, currency: taxCurrency),
        discount: Money(amount: discountAmount, currency: discountCurrency),
        total: Money(amount: totalAmount, currency: totalCurrency),
      );
}
