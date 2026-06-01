import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'product_detail_dto.freezed.dart';
part 'product_detail_dto.g.dart';

@freezed
abstract class ProductDetailDto with _$ProductDetailDto {
  const factory ProductDetailDto({
    required String id,
    required String name,
    @Default('') String description,
    @Default(<String>[]) List<String> images,
    required double amount,
    @Default('NPR') String currency,
    double? compareAtAmount,
    String? compareAtCurrency,
    @Default(0) double rating,
    @Default(0) int reviewCount,
    @Default(0) int soldCount,
    required String vendorId,
    required String vendorName,
    @Default('') String vendorAvatarUrl,
    @Default(true) bool isInStock,
    int? stockCount,
    @Default(<ProductVariantDto>[]) List<ProductVariantDto> variants,
    @Default(<String, String>{}) Map<String, String> specifications,
    @Default('') String shippingInfo,
    @Default(false) bool isSaved,
    @Default(false) bool isInCart,
  }) = _ProductDetailDto;

  const ProductDetailDto._();

  factory ProductDetailDto.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailDtoFromJson(json);

  ProductDetail toDomain() => ProductDetail(
    id: id,
    name: name,
    description: description,
    images: images,
    price: Money(amount: amount, currency: currency),
    compareAtPrice: compareAtAmount != null
        ? Money(amount: compareAtAmount!, currency: compareAtCurrency ?? 'NPR')
        : null,
    rating: rating,
    reviewCount: reviewCount,
    soldCount: soldCount,
    vendorId: vendorId,
    vendorName: vendorName,
    vendorAvatarUrl: vendorAvatarUrl,
    isInStock: isInStock,
    stockCount: stockCount,
    variants: variants.map((v) => v.toDomain()).toList(growable: false),
    specifications: specifications,
    shippingInfo: shippingInfo,
    isSaved: isSaved,
    isInCart: isInCart,
  );
}

@freezed
abstract class ProductVariantDto with _$ProductVariantDto {
  const factory ProductVariantDto({
    required String id,
    required String name,
    @Default(<String>[]) List<String> values,
    @Default('size') String type,
  }) = _ProductVariantDto;

  const ProductVariantDto._();

  factory ProductVariantDto.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantDtoFromJson(json);

  ProductVariant toDomain() => ProductVariant(
    id: id,
    name: name,
    values: values,
    type: type,
  );
}

@freezed
abstract class ProductReviewPreviewDto with _$ProductReviewPreviewDto {
  const factory ProductReviewPreviewDto({
    required String id,
    required String userName,
    @Default('') String userAvatarUrl,
    @Default(0) double rating,
    @Default('') String comment,
    required DateTime createdAt,
  }) = _ProductReviewPreviewDto;

  const ProductReviewPreviewDto._();

  factory ProductReviewPreviewDto.fromJson(Map<String, dynamic> json) =>
      _$ProductReviewPreviewDtoFromJson(json);

  ProductReviewPreview toDomain() => ProductReviewPreview(
    id: id,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
  );
}

@freezed
abstract class RelatedProductDto with _$RelatedProductDto {
  const factory RelatedProductDto({
    required String id,
    required String name,
    @Default('') String imageUrl,
    required double amount,
    @Default('NPR') String currency,
    @Default(0) double rating,
  }) = _RelatedProductDto;

  const RelatedProductDto._();

  factory RelatedProductDto.fromJson(Map<String, dynamic> json) =>
      _$RelatedProductDtoFromJson(json);

  RelatedProduct toDomain() => RelatedProduct(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: Money(amount: amount, currency: currency),
    rating: rating,
  );
}
