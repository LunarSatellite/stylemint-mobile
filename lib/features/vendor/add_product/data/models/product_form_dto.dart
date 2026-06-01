import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'product_form_dto.freezed.dart';
part 'product_form_dto.g.dart';

@freezed
abstract class ProductDraftDto with _$ProductDraftDto {
  const factory ProductDraftDto({
    required String id,
    required String productName,
    required String description,
    required List<String> categories,
    String? brand,
    required List<String> tags,
    required List<String> images,
    required int primaryImageIndex,
    required double basePrice,
    double? compareAtPrice,
    double? costPerItem,
    required double taxRate,
    required bool discountEnabled,
    double? discountPercent,
    required double weight,
    required String weightUnit,
    required double dimensionsLength,
    required double dimensionsWidth,
    required double dimensionsHeight,
    required bool requiresShipping,
    double? shippingFee,
    double? freeShippingOver,
    required int deliveryEstimateMin,
    required int deliveryEstimateMax,
    required String status,
    @Default('NPR') String currency,
  }) = _ProductDraftDto;

  const ProductDraftDto._();

  factory ProductDraftDto.fromJson(Map<String, dynamic> json) =>
      _$ProductDraftDtoFromJson(json);

  ProductDraft toDomain() => ProductDraft(
        id: id,
        basicInfo: BasicInfo(
          productName: productName,
          description: description,
          categories: categories,
          brand: brand,
          tags: tags,
        ),
        imagesInfo: ImagesInfo(
          images: images,
          primaryImageIndex: primaryImageIndex,
        ),
        pricingInfo: PricingInfo(
          basePrice: Money(amount: basePrice, currency: currency),
          compareAtPrice: compareAtPrice != null
              ? Money(amount: compareAtPrice!, currency: currency)
              : null,
          costPerItem: costPerItem != null
              ? Money(amount: costPerItem!, currency: currency)
              : null,
          taxRate: taxRate,
          discountEnabled: discountEnabled,
          discountPercent: discountPercent,
        ),
        shippingInfo: ShippingInfo(
          weight: weight,
          weightUnit: weightUnit,
          dimensionsLength: dimensionsLength,
          dimensionsWidth: dimensionsWidth,
          dimensionsHeight: dimensionsHeight,
          requiresShipping: requiresShipping,
          shippingFee: shippingFee != null
              ? Money(amount: shippingFee!, currency: currency)
              : null,
          freeShippingOver: freeShippingOver != null
              ? Money(amount: freeShippingOver!, currency: currency)
              : null,
          deliveryEstimateMin: deliveryEstimateMin,
          deliveryEstimateMax: deliveryEstimateMax,
        ),
        status: status,
      );

  factory ProductDraftDto.fromDomain(ProductDraft draft) => ProductDraftDto(
        id: draft.id,
        productName: draft.basicInfo.productName,
        description: draft.basicInfo.description,
        categories: draft.basicInfo.categories,
        brand: draft.basicInfo.brand,
        tags: draft.basicInfo.tags,
        images: draft.imagesInfo.images,
        primaryImageIndex: draft.imagesInfo.primaryImageIndex,
        basePrice: draft.pricingInfo.basePrice.amount,
        compareAtPrice: draft.pricingInfo.compareAtPrice?.amount,
        costPerItem: draft.pricingInfo.costPerItem?.amount,
        taxRate: draft.pricingInfo.taxRate,
        discountEnabled: draft.pricingInfo.discountEnabled,
        discountPercent: draft.pricingInfo.discountPercent,
        weight: draft.shippingInfo.weight,
        weightUnit: draft.shippingInfo.weightUnit,
        dimensionsLength: draft.shippingInfo.dimensionsLength,
        dimensionsWidth: draft.shippingInfo.dimensionsWidth,
        dimensionsHeight: draft.shippingInfo.dimensionsHeight,
        requiresShipping: draft.shippingInfo.requiresShipping,
        shippingFee: draft.shippingInfo.shippingFee?.amount,
        freeShippingOver: draft.shippingInfo.freeShippingOver?.amount,
        deliveryEstimateMin: draft.shippingInfo.deliveryEstimateMin,
        deliveryEstimateMax: draft.shippingInfo.deliveryEstimateMax,
        status: draft.status,
        currency: draft.pricingInfo.basePrice.currency,
      );
}

@freezed
abstract class ImageUploadResponseDto with _$ImageUploadResponseDto {
  const factory ImageUploadResponseDto({
    required String url,
  }) = _ImageUploadResponseDto;

  const ImageUploadResponseDto._();

  factory ImageUploadResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ImageUploadResponseDtoFromJson(json);
}
