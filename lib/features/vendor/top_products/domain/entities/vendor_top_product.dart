import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Mirrors one item of `GET /v1/vendor/analytics/products` (Vendor §8D — Top
/// Products full list): `{ productId, name, thumbnailUrl, unitsSold,
/// totalRevenue, distinctCreatorCount }`. The backend doesn't return a
/// rating, stock count, or per-unit price for this list — those belong to
/// the separate product-catalog endpoint.
class VendorTopProduct {
  const VendorTopProduct({
    required this.productId,
    required this.name,
    required this.thumbnailUrl,
    required this.unitsSold,
    required this.totalRevenue,
    required this.distinctCreatorCount,
  });

  final String productId;
  final String name;
  final String? thumbnailUrl;
  final int unitsSold;
  final Money totalRevenue;
  final int distinctCreatorCount;

  VendorTopProduct copyWith({
    String? productId,
    String? name,
    String? thumbnailUrl,
    int? unitsSold,
    Money? totalRevenue,
    int? distinctCreatorCount,
  }) {
    return VendorTopProduct(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      unitsSold: unitsSold ?? this.unitsSold,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      distinctCreatorCount: distinctCreatorCount ?? this.distinctCreatorCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorTopProduct &&
      other.productId == productId &&
      other.name == name &&
      other.thumbnailUrl == thumbnailUrl &&
      other.unitsSold == unitsSold &&
      other.totalRevenue == totalRevenue &&
      other.distinctCreatorCount == distinctCreatorCount;

  @override
  int get hashCode => Object.hash(
    productId,
    name,
    thumbnailUrl,
    unitsSold,
    totalRevenue,
    distinctCreatorCount,
  );
}
