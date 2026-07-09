import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum VendorProductStatus {
  active('Active'),
  draft('Draft'),
  outOfStock('Out of Stock'),
  discontinued('Discontinued');

  const VendorProductStatus(this.label);

  final String label;
}

class VendorProduct {
  const VendorProduct({
    required this.id,
    required this.variantId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.stockCount,
    required this.status,
    required this.rating,
    required this.createdAt,
    this.totalSales,
    this.commissionRate,
    this.reviewCount,
    this.reelCount,
  });

  final String id;

  /// The default variant's id — stock updates (`PATCH .../stock`) are
  /// per-variant. Empty when the product has no variant yet (e.g. a Draft
  /// that hasn't reached the pricing/inventory wizard step).
  final String variantId;
  final String name;
  final String imageUrl;
  final Money price;
  final int stockCount;
  final VendorProductStatus status;

  /// `null` when unavailable — the backend has no bulk sales/units-sold
  /// field on the vendor products list endpoint (only a per-product
  /// analytics deep-dive, which isn't feasible to call per list row).
  final int? totalSales;
  final double rating;
  final DateTime createdAt;
  final double? commissionRate;
  final int? reviewCount;
  final int? reelCount;

  VendorProduct copyWith({
    String? id,
    String? variantId,
    String? name,
    String? imageUrl,
    Money? price,
    int? stockCount,
    VendorProductStatus? status,
    int? totalSales,
    double? rating,
    DateTime? createdAt,
    double? commissionRate,
    int? reviewCount,
    int? reelCount,
  }) {
    return VendorProduct(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      stockCount: stockCount ?? this.stockCount,
      status: status ?? this.status,
      totalSales: totalSales ?? this.totalSales,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      commissionRate: commissionRate ?? this.commissionRate,
      reviewCount: reviewCount ?? this.reviewCount,
      reelCount: reelCount ?? this.reelCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorProduct &&
      other.id == id &&
      other.variantId == variantId &&
      other.name == name &&
      other.imageUrl == imageUrl &&
      other.price == price &&
      other.stockCount == stockCount &&
      other.status == status &&
      other.totalSales == totalSales &&
      other.rating == rating &&
      other.createdAt == createdAt &&
      other.commissionRate == commissionRate &&
      other.reviewCount == reviewCount &&
      other.reelCount == reelCount;

  @override
  int get hashCode => Object.hash(
    id,
    variantId,
    name,
    imageUrl,
    price,
    stockCount,
    status,
    totalSales,
    rating,
    createdAt,
    commissionRate,
    reviewCount,
    reelCount,
  );
}
