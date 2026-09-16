// @JsonKey on freezed factory parameters is supported by json_serializable.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/mall_json_readers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/shared/data/product_options_json.dart';
import 'package:stylemint_mobile_frontend/shared/data/product_reel_ref_json.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/product_reel_ref.dart';

part 'catalog_dto.freezed.dart';
part 'catalog_dto.g.dart';

/// Stock at or below this (and above zero) shows the "Low stock" badge.
const int lowStockThreshold = 5;

/// Catalog `ProductDto` card (docs/mall/catalog-contract.md): the product
/// header, `variants` = [default variant], `images` = [primary image] and
/// `activeFlashSale` while a sale runs.
@freezed
abstract class CatalogProductDto with _$CatalogProductDto {
  const factory CatalogProductDto({
    @Default('') String id,
    String? vendorAccountId,
    @Default('') String name,
    @JsonKey(fromJson: readWireEnum) @Default('') String state,
    double? averageRating,
    @Default(0) int reviewCount,
    @JsonKey(fromJson: readVariants)
    @Default(<CatalogVariantDto>[])
    List<CatalogVariantDto> variants,
    @JsonKey(fromJson: readImages)
    @Default(<CatalogImageDto>[])
    List<CatalogImageDto> images,
    CatalogFlashSaleDto? activeFlashSale,
    String? vendorDisplayName,
    // Nullable and not on the server yet; read tolerantly so a product still
    // renders (as its type tile) whatever shape arrives.
    @JsonKey(fromJson: readProductReelRef, includeToJson: false)
    ProductReelRef? reel,
    // Ships with `defaultVariantId`, but not on the deployed server yet:
    // absent or unparseable reads as true, so the card sends the buyer to the
    // product page rather than guessing a variant.
    @JsonKey(fromJson: readRequiresOptionSelection, includeToJson: false)
    @Default(true)
    bool requiresOptionSelection,
    @JsonKey(fromJson: readDefaultVariantId, includeToJson: false)
    String? defaultVariantId,
    @JsonKey(fromJson: readIsInStock, includeToJson: false)
    @Default(false)
    bool isInStock,
  }) = _CatalogProductDto;

  const CatalogProductDto._();

  factory CatalogProductDto.fromJson(Map<String, dynamic> json) =>
      _$CatalogProductDtoFromJson(json);

  /// Null without an id, a name or a price.
  CatalogProduct? toDomain() {
    if (id.isEmpty || name.trim().isEmpty) return null;
    final variant =
        variants.where((v) => v.isDefault).firstOrNull ?? variants.firstOrNull;
    final sale = activeFlashSale;
    final saleAmount = sale?.salePrice;
    final amount = saleAmount ?? variant?.priceAmount;
    if (amount == null) return null;
    final currency =
        (saleAmount != null ? sale?.currency : null) ??
        variant?.priceCurrency ??
        'NPR';
    final original = sale?.originalPrice;
    final stock = sale?.unitsLeft ?? variant?.quantityOnHand;
    final image =
        images.where((i) => i.isPrimary).firstOrNull ??
        ([
          ...images,
        ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))).firstOrNull;
    final rating = averageRating;
    return CatalogProduct(
      id: id,
      name: name.trim(),
      price: Money(amount: amount, currency: currency),
      compareAtPrice: original != null && original > amount
          ? Money(amount: original, currency: currency)
          : null,
      vendorAccountId: optionalText(vendorAccountId),
      vendorDisplayName: optionalText(vendorDisplayName),
      imageUrl: mediaUrlOrNull(image?.cdnUrl),
      rating: rating != null && rating > 0 && reviewCount > 0 ? rating : null,
      reviewCount: reviewCount,
      isLowStock: stock != null && stock > 0 && stock <= lowStockThreshold,
      isOutOfStock: const {'3', 'outofstock'}.contains(state.toLowerCase()),
      reel: reel,
      requiresOptionSelection: requiresOptionSelection,
      defaultVariantId: defaultVariantId,
      isInStock: isInStock,
    );
  }
}

List<CatalogVariantDto> readVariants(Object? raw) =>
    readJsonList(raw, CatalogVariantDto.fromJson);
List<CatalogImageDto> readImages(Object? raw) =>
    readJsonList(raw, CatalogImageDto.fromJson);
List<CatalogProductDto> readProducts(Object? raw) =>
    readJsonList(raw, CatalogProductDto.fromJson);
List<CollectionItemDto> readCollectionItems(Object? raw) =>
    readJsonList(raw, CollectionItemDto.fromJson);

@freezed
abstract class CatalogVariantDto with _$CatalogVariantDto {
  const factory CatalogVariantDto({
    @Default(false) bool isDefault,
    double? priceAmount,
    String? priceCurrency,
    int? quantityOnHand,
  }) = _CatalogVariantDto;

  factory CatalogVariantDto.fromJson(Map<String, dynamic> json) =>
      _$CatalogVariantDtoFromJson(json);
}

@freezed
abstract class CatalogImageDto with _$CatalogImageDto {
  const factory CatalogImageDto({
    String? cdnUrl,
    @Default(false) bool isPrimary,
    @Default(0) int sortOrder,
  }) = _CatalogImageDto;

  factory CatalogImageDto.fromJson(Map<String, dynamic> json) =>
      _$CatalogImageDtoFromJson(json);
}

@freezed
abstract class CatalogFlashSaleDto with _$CatalogFlashSaleDto {
  const factory CatalogFlashSaleDto({
    double? originalPrice,
    double? salePrice,
    String? currency,
    DateTime? endsUtc,
    int? unitsLeft,
  }) = _CatalogFlashSaleDto;

  factory CatalogFlashSaleDto.fromJson(Map<String, dynamic> json) =>
      _$CatalogFlashSaleDtoFromJson(json);
}

/// `PagedResult<ProductDto>`.
@freezed
abstract class CatalogProductPageDto with _$CatalogProductPageDto {
  const factory CatalogProductPageDto({
    @JsonKey(fromJson: readProducts)
    @Default(<CatalogProductDto>[])
    List<CatalogProductDto> items,
    int? totalCount,
    String? nextCursor,
    @Default(false) bool hasMore,
  }) = _CatalogProductPageDto;

  const CatalogProductPageDto._();

  factory CatalogProductPageDto.fromJson(Map<String, dynamic> json) =>
      _$CatalogProductPageDtoFromJson(json);

  CatalogPage<CatalogProduct> toDomain() => CatalogPage(
    items: List.unmodifiable(items.map((p) => p.toDomain()).nonNulls),
    nextCursor: _nextCursor(nextCursor, hasMore: hasMore),
    totalCount: totalCount,
  );
}

@freezed
abstract class CollectionOwnerDto with _$CollectionOwnerDto {
  const factory CollectionOwnerDto({
    @JsonKey(fromJson: readWireEnum) @Default('') String kind,
    String? accountId,
    String? displayName,
    String? avatarUrl,
  }) = _CollectionOwnerDto;

  factory CollectionOwnerDto.fromJson(Map<String, dynamic> json) =>
      _$CollectionOwnerDtoFromJson(json);
}

@freezed
abstract class CollectionItemDto with _$CollectionItemDto {
  const factory CollectionItemDto({
    @Default('') String productId,
    @Default(0) int sortOrder,
    String? note,
    double? positionX,
    double? positionY,
    CatalogProductDto? product,
  }) = _CollectionItemDto;

  const CollectionItemDto._();

  factory CollectionItemDto.fromJson(Map<String, dynamic> json) =>
      _$CollectionItemDtoFromJson(json);

  CollectionItem? toDomain() {
    final card = product?.toDomain();
    if (card == null) return null;
    final x = positionX;
    final y = positionY;
    final placed = x != null && y != null;
    return CollectionItem(
      product: card,
      sortOrder: sortOrder,
      note: optionalText(note),
      positionX: placed ? x.clamp(0, 1).toDouble() : null,
      positionY: placed ? y.clamp(0, 1).toDouble() : null,
    );
  }
}

/// `PagedResult<CollectionItemDto>`.
@freezed
abstract class CollectionItemPageDto with _$CollectionItemPageDto {
  const factory CollectionItemPageDto({
    @JsonKey(fromJson: readCollectionItems)
    @Default(<CollectionItemDto>[])
    List<CollectionItemDto> items,
    int? totalCount,
    String? nextCursor,
    @Default(false) bool hasMore,
  }) = _CollectionItemPageDto;

  const CollectionItemPageDto._();

  factory CollectionItemPageDto.fromJson(Map<String, dynamic> json) =>
      _$CollectionItemPageDtoFromJson(json);

  CatalogPage<CollectionItem> toDomain() => CatalogPage(
    items: List.unmodifiable(items.map((i) => i.toDomain()).nonNulls),
    nextCursor: _nextCursor(nextCursor, hasMore: hasMore),
    totalCount: totalCount,
  );
}

/// `CollectionDetailDto`.
@freezed
abstract class CollectionDetailDto with _$CollectionDetailDto {
  const factory CollectionDetailDto({
    @Default('') String id,
    @Default('') String slug,
    @Default('') String title,
    String? subtitle,
    String? description,
    String? coverImageUrl,
    @JsonKey(fromJson: readWireEnum) @Default('') String kind,
    CollectionOwnerDto? owner,
    @Default(0) int itemCount,
    CollectionItemPageDto? items,
  }) = _CollectionDetailDto;

  const CollectionDetailDto._();

  factory CollectionDetailDto.fromJson(Map<String, dynamic> json) =>
      _$CollectionDetailDtoFromJson(json);

  CollectionDetail toDomain() => CollectionDetail(
    id: id,
    slug: slug,
    title: title.trim(),
    kind: collectionKindFromWire(kind),
    subtitle: optionalText(subtitle),
    description: optionalText(description),
    coverImageUrl: mediaUrlOrNull(coverImageUrl),
    ownerDisplayName: optionalText(owner?.displayName),
    itemCount: itemCount,
    items: items?.toDomain() ?? const CatalogPage(items: []),
  );
}

/// A cursor is only usable while the server says there is more.
String? _nextCursor(String? cursor, {required bool hasMore}) {
  final value = optionalText(cursor);
  return hasMore ? value : null;
}
