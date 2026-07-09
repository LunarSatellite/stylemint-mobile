import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_product_dto.freezed.dart';
part 'vendor_product_dto.g.dart';

/// Mirrors `ProductVariantDto` — stock/price live per-variant, not on the
/// product itself.
@freezed
abstract class VendorProductVariantDto with _$VendorProductVariantDto {
  const factory VendorProductVariantDto({
    required String id,
    required bool isDefault,
    required double priceAmount,
    String? priceCurrency,
    required int quantityOnHand,
  }) = _VendorProductVariantDto;

  factory VendorProductVariantDto.fromJson(Map<String, dynamic> json) =>
      _$VendorProductVariantDtoFromJson(json);
}

/// Mirrors `ProductImageDto`.
@freezed
abstract class VendorProductImageDto with _$VendorProductImageDto {
  const factory VendorProductImageDto({
    String? cdnUrl,
    required bool isPrimary,
  }) = _VendorProductImageDto;

  factory VendorProductImageDto.fromJson(Map<String, dynamic> json) =>
      _$VendorProductImageDtoFromJson(json);
}

/// Mirrors the real `ProductDto` returned by `GET /v1/vendor/products`.
/// `state` is the backend's numeric `ProductState` enum (1=Draft, 2=Active,
/// 3=OutOfStock, 4=Archived, 5=Suspended) — not a string status code.
@freezed
abstract class VendorProductDto with _$VendorProductDto {
  const factory VendorProductDto({
    required String id,
    required String name,
    required int state,
    required double averageRating,
    int? reviewCount,
    required DateTime createdUtc,
    @Default(<VendorProductVariantDto>[])
    List<VendorProductVariantDto> variants,
    @Default(<VendorProductImageDto>[]) List<VendorProductImageDto> images,
  }) = _VendorProductDto;

  const VendorProductDto._();

  factory VendorProductDto.fromJson(Map<String, dynamic> json) =>
      _$VendorProductDtoFromJson(json);

  VendorProduct toDomain() {
    final variant = _defaultVariant();
    final image = _primaryImage();
    return VendorProduct(
      id: id,
      variantId: variant?.id ?? '',
      name: name,
      imageUrl: image?.cdnUrl ?? '',
      price: Money(
        amount: variant?.priceAmount ?? 0,
        currency: variant?.priceCurrency ?? 'NPR',
      ),
      stockCount: variant?.quantityOnHand ?? 0,
      status: _statusFromState(state),
      // No bulk sales/units-sold field on ProductDto — backend confirmed
      // this only exists on the per-product analytics deep-dive endpoint
      // (N+1 to call per list row). Left null pending a denormalized
      // counter on the backend.
      totalSales: null,
      rating: averageRating,
      createdAt: createdUtc,
      reviewCount: reviewCount,
    );
  }

  VendorProductVariantDto? _defaultVariant() {
    if (variants.isEmpty) return null;
    for (final v in variants) {
      if (v.isDefault) return v;
    }
    return variants.first;
  }

  VendorProductImageDto? _primaryImage() {
    if (images.isEmpty) return null;
    for (final i in images) {
      if (i.isPrimary) return i;
    }
    return images.first;
  }

  static VendorProductStatus _statusFromState(int state) {
    switch (state) {
      case 1:
        return VendorProductStatus.draft;
      case 2:
        return VendorProductStatus.active;
      case 3:
        return VendorProductStatus.outOfStock;
      case 4: // Archived
      case 5: // Suspended — collapsed into discontinued; UI doesn't
        // distinguish an admin-suspended listing from a vendor-archived one.
        return VendorProductStatus.discontinued;
      default:
        return VendorProductStatus.draft;
    }
  }
}
