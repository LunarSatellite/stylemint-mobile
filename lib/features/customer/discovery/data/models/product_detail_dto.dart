import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'product_detail_dto.freezed.dart';
part 'product_detail_dto.g.dart';

/// Maps `GET /v1/public/products/{id}` — backend `ProductDto`
/// (StyleMint.Modules.Catalog). There is no top-level price or "compare at"
/// price on this DTO: price/stock live per-SKU on [variants]. The vendor's
/// display name/avatar are hydrated server-side from Identity's
/// VendorProfile (business_name/logo_url) via `IVendorProfileService` and
/// come through as [vendorDisplayName]/[vendorAvatarUrl] — null when the
/// vendor profile is missing or unapproved.
@freezed
abstract class ProductDetailDto with _$ProductDetailDto {
  const factory ProductDetailDto({
    required String id,
    required String vendorAccountId,
    required String name,
    String? vendorDisplayName,
    String? vendorAvatarUrl,
    @Default('') String shortDescription,
    @Default('') String longDescriptionMarkdown,
    @Default(0) double averageRating,
    @Default(0) int reviewCount,
    @Default(<ProductImageDto>[]) List<ProductImageDto> images,
    @Default(<ProductVariantDto>[]) List<ProductVariantDto> variants,
    ActiveFlashSaleDto? activeFlashSale,
  }) = _ProductDetailDto;

  const ProductDetailDto._();

  factory ProductDetailDto.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailDtoFromJson(json);

  ProductDetail toDomain() {
    final defaultVariant = variants.isEmpty
        ? null
        : variants.firstWhere((v) => v.isDefault, orElse: () => variants.first);
    final sortedImages = [...images]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final skuChoices = variants.length > 1
        ? [
            ProductVariant(
              id: 'sku',
              name: 'option',
              values: variants
                  .map((variant) => variant.sku)
                  .toList(growable: false),
              type: 'sku',
              optionVariantIds: {
                for (final variant in variants) variant.sku: variant.id,
              },
            ),
          ]
        : const <ProductVariant>[];

    final sale = activeFlashSale;
    return ProductDetail(
      id: id,
      name: name,
      description: longDescriptionMarkdown.isNotEmpty
          ? longDescriptionMarkdown
          : shortDescription,
      images: sortedImages.map((i) => i.cdnUrl).toList(growable: false),
      price: sale != null
          ? Money(amount: sale.salePrice, currency: sale.currency)
          : Money(
              amount: defaultVariant?.priceAmount ?? 0,
              currency: defaultVariant?.priceCurrency ?? 'NPR',
            ),
      compareAtPrice: sale != null
          ? Money(amount: sale.originalPrice, currency: sale.currency)
          : null,
      flashSaleEndsAt: sale?.endsUtc,
      rating: averageRating,
      reviewCount: reviewCount,
      soldCount: 0,
      vendorId: vendorAccountId,
      vendorName: vendorDisplayName ?? '',
      vendorAvatarUrl: vendorAvatarUrl ?? '',
      isInStock:
          defaultVariant == null ||
          !defaultVariant.trackInventory ||
          defaultVariant.quantityOnHand > 0,
      stockCount: defaultVariant?.trackInventory == true
          ? defaultVariant?.quantityOnHand
          : null,
      variants: skuChoices,
      specifications: const {},
      shippingInfo: '',
      isSaved: false,
      isInCart: false,
      defaultVariantId: defaultVariant?.id,
    );
  }
}

/// Maps backend `ActiveFlashSaleDto`, embedded on ProductDto when the
/// product's default variant currently has a running FlashSale.
@freezed
abstract class ActiveFlashSaleDto with _$ActiveFlashSaleDto {
  const factory ActiveFlashSaleDto({
    required String flashSaleId,
    @Default(0) double originalPrice,
    @Default(0) double salePrice,
    @Default('NPR') String currency,
    required DateTime endsUtc,
    @Default(0) int unitsLeft,
  }) = _ActiveFlashSaleDto;

  const ActiveFlashSaleDto._();

  factory ActiveFlashSaleDto.fromJson(Map<String, dynamic> json) =>
      _$ActiveFlashSaleDtoFromJson(json);
}

@freezed
abstract class ProductImageDto with _$ProductImageDto {
  const factory ProductImageDto({
    @Default('') String cdnUrl,
    @Default(0) int sortOrder,
    @Default(false) bool isPrimary,
  }) = _ProductImageDto;

  const ProductImageDto._();

  factory ProductImageDto.fromJson(Map<String, dynamic> json) =>
      _$ProductImageDtoFromJson(json);
}

@freezed
abstract class ProductVariantDto with _$ProductVariantDto {
  const factory ProductVariantDto({
    required String id,
    @Default('') String sku,
    @Default(false) bool isDefault,
    @Default(0) double priceAmount,
    @Default('NPR') String priceCurrency,
    @Default(true) bool trackInventory,
    @Default(0) int quantityOnHand,
  }) = _ProductVariantDto;

  const ProductVariantDto._();

  factory ProductVariantDto.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantDtoFromJson(json);

  ProductVariant toDomain() => ProductVariant(
    id: id,
    name: sku,
    values: const [],
    type: 'sku',
    optionVariantIds: {sku: id},
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
