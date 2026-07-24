import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'checkout_dto.freezed.dart';
part 'checkout_dto.g.dart';

/// Maps `ShippingAddressDto` from `StyleMint.Modules.CartCheckout` (the
/// `/v1/addresses` endpoints) — field names are the backend's actual wire
/// shape (`addressLine1`/`state`/`zipCode`/`country`), not the old
/// `line1`/`stateProvince`/`postalCode`/`countryCode` guess, which silently
/// failed to parse and made every saved address invisible to the app.
@freezed
abstract class ShippingAddressDto with _$ShippingAddressDto {
  const factory ShippingAddressDto({
    required String id,
    @Default('Home') String label,
    @Default('') String receiverName,
    @Default('') String receiverPhone,
    required String addressLine1,
    String? landmark,
    @Default('NP') String country,
    @Default('') String state,
    required String city,
    @Default('') String zipCode,
    @Default(false) bool isDefault,
    @Default('') String rowVersion,
  }) = _ShippingAddressDto;

  const ShippingAddressDto._();

  factory ShippingAddressDto.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressDtoFromJson(json);

  ShippingAddress toDomain() => ShippingAddress(
        id: id,
        label: label,
        line1: addressLine1,
        line2: landmark,
        city: city,
        stateProvince: state,
        postalCode: zipCode,
        countryCode: country,
        isDefault: isDefault,
        rowVersion: rowVersion,
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
      case 'paypal':
        return PaymentMethodType.paypal;
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
    required int quantity,
    required double unitPriceAmount,
    @Default('NPR') String unitPriceCurrency,
    // Frozen cart-line snapshot fields (CartLineDto on the backend) — the
    // checkout session's items carry these, not the old productName/imageUrl/
    // variantName shape.
    @Default('') String productTitleSnapshot,
    String? variantLabelSnapshot,
    String? thumbnailUrlSnapshot,
  }) = _CheckoutItemDto;

  const CheckoutItemDto._();

  factory CheckoutItemDto.fromJson(Map<String, dynamic> json) =>
      _$CheckoutItemDtoFromJson(json);

  CheckoutItem toDomain() => CheckoutItem(
        productId: productId,
        productName: productTitleSnapshot,
        imageUrl: thumbnailUrlSnapshot ?? '',
        variantName: variantLabelSnapshot ?? '',
        quantity: quantity,
        unitPrice: Money(amount: unitPriceAmount, currency: unitPriceCurrency),
      );
}

/// Maps `POST/GET /v1/checkout/sessions` (`CheckoutSessionDto` on the
/// backend). A session starts in Draft: no address/payment chosen yet and
/// totals are null until `RecordTotals` runs at Place time — see
/// `StyleMint.Modules.CartCheckout...CheckoutSessionDto.cs`. Address, payment
/// method, and totals are therefore all nullable here; the repository fills
/// the total gaps from the cart summary and the notifier fills the
/// address/payment gaps from the saved-addresses / saved-payment-methods
/// lists.
@freezed
abstract class CheckoutSummaryDto with _$CheckoutSummaryDto {
  const factory CheckoutSummaryDto({
    required String id,
    String? shippingAddressId,
    @Default(<CheckoutItemDto>[]) List<CheckoutItemDto> items,
    double? subtotalAmount,
    @Default('NPR') String subtotalCurrency,
    double? shippingAmount,
    @Default('NPR') String shippingCurrency,
    double? taxAmount,
    @Default('NPR') String taxCurrency,
    double? discountAmount,
    @Default('NPR') String discountCurrency,
    double? totalAmount,
    @Default('NPR') String totalCurrency,
  }) = _CheckoutSummaryDto;

  const CheckoutSummaryDto._();

  factory CheckoutSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$CheckoutSummaryDtoFromJson(json);

  /// [fallback] supplies subtotal/shipping/tax/total from the cart while the
  /// session's own totals are still null (Draft state).
  CheckoutSummary toDomain({required Cart fallback}) => CheckoutSummary(
        shippingAddress: const ShippingAddress.empty(),
        paymentMethod: const PaymentMethod.empty(),
        items: items.map((dto) => dto.toDomain()).toList(growable: false),
        subtotal: Money(
          amount: subtotalAmount ?? fallback.subtotal.amount,
          currency: subtotalCurrency,
        ),
        shipping: Money(
          amount: shippingAmount ?? fallback.shippingTotal.amount,
          currency: shippingCurrency,
        ),
        tax: Money(
          amount: taxAmount ?? fallback.taxTotal.amount,
          currency: taxCurrency,
        ),
        discount: Money(amount: discountAmount ?? 0, currency: discountCurrency),
        total: Money(
          amount: totalAmount ?? fallback.total.amount,
          currency: totalCurrency,
        ),
      );
}
