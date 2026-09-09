import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A single saved / wishlisted item for the customer.
class SavedItem {
  const SavedItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    this.variantLabel,
    required this.price,
    required this.rating,
    required this.savedAt,
    this.stockStatus = 'inStock',
    this.originalPrice,
    this.isFreeShipping = false,
    this.priceDrop,
  });

  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;

  /// Variant snapshot label from the saved line (backend
  /// SavedForLaterItemDto.variantLabelSnapshot). Null for single-variant
  /// products.
  final String? variantLabel;
  final Money price;
  final double rating;
  final DateTime savedAt;

  /// Derived from CartCheckout's live variant-inventory enrichment.
  /// 'inStock' | 'lowStock' | 'outOfStock'
  final String stockStatus;
  final Money? originalPrice;
  final bool isFreeShipping;
  final Money? priceDrop;

  SavedItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImageUrl,
    String? variantLabel,
    Money? price,
    double? rating,
    DateTime? savedAt,
    String? stockStatus,
    Money? originalPrice,
    bool? isFreeShipping,
    Money? priceDrop,
  }) {
    return SavedItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      variantLabel: variantLabel ?? this.variantLabel,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      savedAt: savedAt ?? this.savedAt,
      stockStatus: stockStatus ?? this.stockStatus,
      originalPrice: originalPrice ?? this.originalPrice,
      isFreeShipping: isFreeShipping ?? this.isFreeShipping,
      priceDrop: priceDrop ?? this.priceDrop,
    );
  }
}
