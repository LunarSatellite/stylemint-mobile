import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'cart_dto.freezed.dart';
part 'cart_dto.g.dart';

@freezed
abstract class CartItemDto with _$CartItemDto {
  const factory CartItemDto({
    required String id,
    required String productId,
    required String productName,
    required String productImageUrl,
    required String variantName,
    required int quantity,
    required double unitPriceAmount,
    @Default('NPR') String unitPriceCurrency,
    required bool isInStock,
  }) = _CartItemDto;

  const CartItemDto._();

  factory CartItemDto.fromJson(Map<String, dynamic> json) =>
      _$CartItemDtoFromJson(json);

  CartItem toDomain() => CartItem(
        id: id,
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        variantName: variantName,
        quantity: quantity,
        unitPrice: Money(amount: unitPriceAmount, currency: unitPriceCurrency),
        isInStock: isInStock,
      );
}

@freezed
abstract class CartDto with _$CartDto {
  const factory CartDto({
    required String id,
    @Default(<CartItemDto>[]) List<CartItemDto> items,
    required double subtotalAmount,
    @Default('NPR') String subtotalCurrency,
    required double shippingTotalAmount,
    @Default('NPR') String shippingTotalCurrency,
    required double taxTotalAmount,
    @Default('NPR') String taxTotalCurrency,
    required double totalAmount,
    @Default('NPR') String totalCurrency,
  }) = _CartDto;

  const CartDto._();

  factory CartDto.fromJson(Map<String, dynamic> json) =>
      _$CartDtoFromJson(json);

  Cart toDomain() => Cart(
        id: id,
        items: items.map((dto) => dto.toDomain()).toList(growable: false),
        subtotal: Money(amount: subtotalAmount, currency: subtotalCurrency),
        shippingTotal:
            Money(amount: shippingTotalAmount, currency: shippingTotalCurrency),
        taxTotal: Money(amount: taxTotalAmount, currency: taxTotalCurrency),
        total: Money(amount: totalAmount, currency: totalCurrency),
      );
}
