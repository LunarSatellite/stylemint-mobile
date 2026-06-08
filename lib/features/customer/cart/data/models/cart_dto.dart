import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'cart_dto.freezed.dart';
part 'cart_dto.g.dart';

/// Maps the backend CartViewDto / CartLineDto contract (camelCase). Amounts are
/// `num` because System.Text.Json serializes whole `decimal`s as ints (e.g.
/// 5000), which `as double` would reject.
@freezed
abstract class CartItemDto with _$CartItemDto {
  const factory CartItemDto({
    @JsonKey(name: 'lineId') required String id,
    required String productId,
    @JsonKey(name: 'productTitleSnapshot') required String productName,
    @JsonKey(name: 'thumbnailUrlSnapshot') String? productImageUrl,
    @JsonKey(name: 'variantLabelSnapshot') String? variantName,
    required int quantity,
    required num unitPriceAmount,
    @Default('NPR') String unitPriceCurrency,
    @JsonKey(name: 'creatorHandleSnapshot') String? creatorHandle,
    @JsonKey(name: 'commissionRateSnapshot') num? commissionRate,
  }) = _CartItemDto;

  const CartItemDto._();

  factory CartItemDto.fromJson(Map<String, dynamic> json) =>
      _$CartItemDtoFromJson(json);

  CartItem toDomain() => CartItem(
        id: id,
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl ?? '',
        variantName: variantName ?? '',
        quantity: quantity,
        unitPrice: Money(
            amount: unitPriceAmount.toDouble(), currency: unitPriceCurrency),
        // The cart-line contract carries no per-line stock flag; treat as in
        // stock (out-of-stock lines are auto-removed server-side; see Notices).
        isInStock: true,
        creatorHandle: creatorHandle,
        commissionRate: commissionRate?.toDouble(),
      );
}

@freezed
abstract class CartAppreciationDto with _$CartAppreciationDto {
  const factory CartAppreciationDto({
    @Default(0) int supportedCreatorsCount,
  }) = _CartAppreciationDto;

  factory CartAppreciationDto.fromJson(Map<String, dynamic> json) =>
      _$CartAppreciationDtoFromJson(json);
}

@freezed
abstract class CartDto with _$CartDto {
  const factory CartDto({
    @JsonKey(name: 'accountId') required String id,
    @JsonKey(name: 'lines') @Default(<CartItemDto>[]) List<CartItemDto> items,
    required num subtotalAmount,
    @Default('NPR') String subtotalCurrency,
    @JsonKey(name: 'shippingAmount') required num shippingTotalAmount,
    @JsonKey(name: 'shippingCurrency')
    @Default('NPR')
    String shippingTotalCurrency,
    @JsonKey(name: 'taxAmount') required num taxTotalAmount,
    @JsonKey(name: 'taxCurrency') @Default('NPR') String taxTotalCurrency,
    @JsonKey(name: 'grandTotalAmount') required num totalAmount,
    @JsonKey(name: 'grandTotalCurrency') @Default('NPR') String totalCurrency,
    @Default(CartAppreciationDto()) CartAppreciationDto appreciation,
  }) = _CartDto;

  const CartDto._();

  factory CartDto.fromJson(Map<String, dynamic> json) =>
      _$CartDtoFromJson(json);

  Cart toDomain() => Cart(
        id: id,
        items: items.map((dto) => dto.toDomain()).toList(growable: false),
        subtotal:
            Money(amount: subtotalAmount.toDouble(), currency: subtotalCurrency),
        shippingTotal: Money(
            amount: shippingTotalAmount.toDouble(),
            currency: shippingTotalCurrency),
        taxTotal:
            Money(amount: taxTotalAmount.toDouble(), currency: taxTotalCurrency),
        total: Money(amount: totalAmount.toDouble(), currency: totalCurrency),
        supportedCreatorsCount: appreciation.supportedCreatorsCount,
      );
}
