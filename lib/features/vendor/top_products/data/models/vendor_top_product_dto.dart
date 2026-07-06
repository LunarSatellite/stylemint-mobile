import 'package:stylemint_mobile_frontend/features/vendor/top_products/domain/entities/vendor_top_product.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Matches `GET /v1/vendor/analytics/products` (Vendor §8D):
/// `{ window: {...}, items: [{ productId, name, thumbnailUrl, unitsSold,
/// totalRevenue, distinctCreatorCount }] }`. `window` is echoed back for the
/// date-range filter chip but isn't rendered by this screen yet.
class VendorTopProductDto {
  const VendorTopProductDto({
    required this.productId,
    this.name,
    this.thumbnailUrl,
    required this.unitsSold,
    required this.totalRevenue,
    required this.distinctCreatorCount,
  });

  factory VendorTopProductDto.fromJson(Map<String, dynamic> json) =>
      VendorTopProductDto(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        unitsSold: (json['unitsSold'] as num?)?.toInt() ?? 0,
        totalRevenue: _MoneyDto.fromJson(
          json['totalRevenue'] as Map<String, dynamic>?,
        ),
        distinctCreatorCount:
            (json['distinctCreatorCount'] as num?)?.toInt() ?? 0,
      );

  final String productId;
  final String? name;
  final String? thumbnailUrl;
  final int unitsSold;
  final _MoneyDto totalRevenue;
  final int distinctCreatorCount;

  VendorTopProduct toDomain() => VendorTopProduct(
    productId: productId,
    name: (name?.isNotEmpty ?? false) ? name! : 'Unnamed product',
    thumbnailUrl: thumbnailUrl,
    unitsSold: unitsSold,
    totalRevenue: totalRevenue.toDomain(),
    distinctCreatorCount: distinctCreatorCount,
  );
}

class _MoneyDto {
  const _MoneyDto({required this.amount, this.currency = 'NPR'});

  factory _MoneyDto.fromJson(Map<String, dynamic>? json) => _MoneyDto(
    amount: (json?['amount'] as num?)?.toDouble() ?? 0,
    currency: json?['currency'] as String? ?? 'NPR',
  );

  final double amount;
  final String currency;

  Money toDomain() => Money(amount: amount, currency: currency);
}

class VendorTopProductsPageDto {
  const VendorTopProductsPageDto({required this.items});

  factory VendorTopProductsPageDto.fromJson(Map<String, dynamic> json) =>
      VendorTopProductsPageDto(
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => VendorTopProductDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<VendorTopProductDto> items;

  List<VendorTopProduct> toDomain() =>
      items.map((e) => e.toDomain()).toList(growable: false);
}
