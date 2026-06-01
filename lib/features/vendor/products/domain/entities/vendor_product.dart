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
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.stockCount,
    required this.status,
    required this.totalSales,
    required this.rating,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String imageUrl;
  final Money price;
  final int stockCount;
  final VendorProductStatus status;
  final int totalSales;
  final double rating;
  final DateTime createdAt;

  VendorProduct copyWith({
    String? id,
    String? name,
    String? imageUrl,
    Money? price,
    int? stockCount,
    VendorProductStatus? status,
    int? totalSales,
    double? rating,
    DateTime? createdAt,
  }) {
    return VendorProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      stockCount: stockCount ?? this.stockCount,
      status: status ?? this.status,
      totalSales: totalSales ?? this.totalSales,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorProduct &&
      other.id == id &&
      other.name == name &&
      other.imageUrl == imageUrl &&
      other.price == price &&
      other.stockCount == stockCount &&
      other.status == status &&
      other.totalSales == totalSales &&
      other.rating == rating &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        imageUrl,
        price,
        stockCount,
        status,
        totalSales,
        rating,
        createdAt,
      );
}
