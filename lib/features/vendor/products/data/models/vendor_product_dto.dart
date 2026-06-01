import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_product_dto.freezed.dart';
part 'vendor_product_dto.g.dart';

@freezed
abstract class VendorProductDto with _$VendorProductDto {
  const factory VendorProductDto({
    required String id,
    required String name,
    required String imageUrl,
    required double priceAmount,
    required int stockCount,
    required String status,
    required int totalSales,
    required double rating,
    required DateTime createdAt,
    @Default('NPR') String currency,
  }) = _VendorProductDto;

  const VendorProductDto._();

  factory VendorProductDto.fromJson(Map<String, dynamic> json) =>
      _$VendorProductDtoFromJson(json);

  VendorProduct toDomain() => VendorProduct(
        id: id,
        name: name,
        imageUrl: imageUrl,
        price: Money(amount: priceAmount, currency: currency),
        stockCount: stockCount,
        status: _statusFromCode(status),
        totalSales: totalSales,
        rating: rating,
        createdAt: createdAt,
      );

  static VendorProductStatus _statusFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'active':
        return VendorProductStatus.active;
      case 'draft':
        return VendorProductStatus.draft;
      case 'out_of_stock':
      case 'outofstock':
        return VendorProductStatus.outOfStock;
      case 'discontinued':
        return VendorProductStatus.discontinued;
      default:
        return VendorProductStatus.draft;
    }
  }
}
