import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Full product detail returned by GET /v1/products/{id}.
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.price,
    this.compareAtPrice,
    required this.rating,
    required this.reviewCount,
    required this.soldCount,
    required this.vendorId,
    required this.vendorName,
    required this.vendorAvatarUrl,
    required this.isInStock,
    this.stockCount,
    required this.variants,
    required this.specifications,
    required this.shippingInfo,
    required this.isSaved,
    required this.isInCart,
  });

  final String id;
  final String name;
  final String description;
  final List<String> images;
  final Money price;
  final Money? compareAtPrice;
  final double rating;
  final int reviewCount;
  final int soldCount;
  final String vendorId;
  final String vendorName;
  final String vendorAvatarUrl;
  final bool isInStock;
  final int? stockCount;
  final List<ProductVariant> variants;
  final Map<String, String> specifications;
  final String shippingInfo;
  final bool isSaved;
  final bool isInCart;

  ProductDetail copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? images,
    Money? price,
    Money? compareAtPrice,
    double? rating,
    int? reviewCount,
    int? soldCount,
    String? vendorId,
    String? vendorName,
    String? vendorAvatarUrl,
    bool? isInStock,
    int? stockCount,
    List<ProductVariant>? variants,
    Map<String, String>? specifications,
    String? shippingInfo,
    bool? isSaved,
    bool? isInCart,
  }) {
    return ProductDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
      price: price ?? this.price,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      soldCount: soldCount ?? this.soldCount,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorAvatarUrl: vendorAvatarUrl ?? this.vendorAvatarUrl,
      isInStock: isInStock ?? this.isInStock,
      stockCount: stockCount ?? this.stockCount,
      variants: variants ?? this.variants,
      specifications: specifications ?? this.specifications,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      isSaved: isSaved ?? this.isSaved,
      isInCart: isInCart ?? this.isInCart,
    );
  }
}

/// A variant option group — e.g. "Size" with values ["S", "M", "L"].
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.name,
    required this.values,
    required this.type,
  });

  final String id;
  final String name;
  final List<String> values;
  final String type;

  ProductVariant copyWith({
    String? id,
    String? name,
    List<String>? values,
    String? type,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      values: values ?? this.values,
      type: type ?? this.type,
    );
  }
}

/// A single review shown in the preview section.
class ProductReviewPreview {
  const ProductReviewPreview({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String userName;
  final String userAvatarUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
}

/// A related / "You may also like" product card.
class RelatedProduct {
  const RelatedProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
  });

  final String id;
  final String name;
  final String imageUrl;
  final Money price;
  final double rating;
}
