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

class AppliedPromoCodeDto {
  const AppliedPromoCodeDto({
    required this.code,
    required this.discountAmount,
    required this.discountCurrency,
  });

  factory AppliedPromoCodeDto.fromJson(Map<String, dynamic> json) =>
      AppliedPromoCodeDto(
        code: json['code'] as String? ?? '',
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
        discountCurrency: json['discountAmountCurrency'] as String? ?? 'NPR',
      );

  final String code;
  final double discountAmount;
  final String discountCurrency;

  AppliedPromoCode toDomain() => AppliedPromoCode(
        code: code,
        discount: Money(amount: discountAmount, currency: discountCurrency),
      );
}

class SavedForLaterItemDto {
  const SavedForLaterItemDto({
    required this.id,
    required this.productName,
    required this.variantName,
    required this.productImageUrl,
    required this.quantity,
    required this.unitPriceAmount,
    required this.unitPriceCurrency,
  });

  factory SavedForLaterItemDto.fromJson(Map<String, dynamic> json) =>
      SavedForLaterItemDto(
        id: json['id'] as String,
        productName: json['productTitleSnapshot'] as String? ?? '',
        variantName: json['variantLabelSnapshot'] as String? ?? '',
        productImageUrl: json['thumbnailUrlSnapshot'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        unitPriceAmount: (json['unitPriceAmount'] as num?)?.toDouble() ?? 0,
        unitPriceCurrency: json['unitPriceCurrency'] as String? ?? 'NPR',
      );

  final String id;
  final String productName;
  final String variantName;
  final String productImageUrl;
  final int quantity;
  final double unitPriceAmount;
  final String unitPriceCurrency;

  SavedForLaterItem toDomain() => SavedForLaterItem(
        id: id,
        productName: productName,
        variantName: variantName,
        productImageUrl: productImageUrl,
        quantity: quantity,
        unitPrice: Money(amount: unitPriceAmount, currency: unitPriceCurrency),
      );
}

AppliedPromoCodeDto? _promoFromJson(Map<String, dynamic>? json) =>
    json == null ? null : AppliedPromoCodeDto.fromJson(json);

Map<String, dynamic>? _promoToJson(AppliedPromoCodeDto? promo) => promo == null
    ? null
    : <String, dynamic>{
        'code': promo.code,
        'discountAmount': promo.discountAmount,
        'discountAmountCurrency': promo.discountCurrency,
      };

List<SavedForLaterItemDto> _savedForLaterFromJson(List<dynamic>? json) =>
    json
        ?.map((item) =>
            SavedForLaterItemDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false) ??
    const <SavedForLaterItemDto>[];

List<Map<String, dynamic>> _savedForLaterToJson(
  List<SavedForLaterItemDto> items,
) => items
    .map(
      (item) => <String, dynamic>{
        'id': item.id,
        'productTitleSnapshot': item.productName,
        'variantLabelSnapshot': item.variantName,
        'thumbnailUrlSnapshot': item.productImageUrl,
        'quantity': item.quantity,
        'unitPriceAmount': item.unitPriceAmount,
        'unitPriceCurrency': item.unitPriceCurrency,
      },
    )
    .toList(growable: false);

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
    @Default(0) num discountAmount,
    @Default('NPR') String discountCurrency,
    @Default(CartAppreciationDto()) CartAppreciationDto appreciation,
    @JsonKey(fromJson: _promoFromJson, toJson: _promoToJson)
    AppliedPromoCodeDto? appliedPromoCode,
    @JsonKey(fromJson: _savedForLaterFromJson, toJson: _savedForLaterToJson)
    @Default(<SavedForLaterItemDto>[]) List<SavedForLaterItemDto> savedForLater,
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
        discount:
            Money(amount: discountAmount.toDouble(), currency: discountCurrency),
        supportedCreatorsCount: appreciation.supportedCreatorsCount,
        appliedPromoCode: appliedPromoCode?.toDomain(),
        savedForLater:
            savedForLater.map((dto) => dto.toDomain()).toList(growable: false),
      );
}
