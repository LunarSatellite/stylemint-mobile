import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A "top selling" product from the dashboard payload (`topProducts[]`).
/// Matches the backend item: `productId, name, thumbnailUrl, unitsSold,
/// totalRevenue, distinctCreatorCount`.
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

/// Mirrors the `GET /v1/vendor/analytics/overview` payload (Vendor §8A) — the
/// fields the vendor home dashboard actually renders. (Previously this entity
/// was wired to `/v1/vendor/dashboard`, which is the unrelated Brand Studio
/// snapshot endpoint and never returned these fields.)
class VendorDashboard {
  const VendorDashboard({
    required this.grossSales,
    required this.netRevenue,
    required this.totalOrders,
    required this.topProducts,
    this.grossSalesDeltaPercent,
  });

  /// `grossSales.current` for the window.
  final Money grossSales;

  /// `grossSales.deltaPercent` — percent change vs the previous window.
  /// `null` when the backend has no comparison baseline yet.
  final double? grossSalesDeltaPercent;

  final Money netRevenue;
  final int totalOrders;
  final List<VendorTopProduct> topProducts;

  VendorDashboard copyWith({
    Money? grossSales,
    double? grossSalesDeltaPercent,
    Money? netRevenue,
    int? totalOrders,
    List<VendorTopProduct>? topProducts,
  }) {
    return VendorDashboard(
      grossSales: grossSales ?? this.grossSales,
      grossSalesDeltaPercent: grossSalesDeltaPercent ?? this.grossSalesDeltaPercent,
      netRevenue: netRevenue ?? this.netRevenue,
      totalOrders: totalOrders ?? this.totalOrders,
      topProducts: topProducts ?? this.topProducts,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorDashboard &&
      other.grossSales == grossSales &&
      other.grossSalesDeltaPercent == grossSalesDeltaPercent &&
      other.netRevenue == netRevenue &&
      other.totalOrders == totalOrders;

  @override
  int get hashCode =>
      Object.hash(grossSales, grossSalesDeltaPercent, netRevenue, totalOrders);
}
