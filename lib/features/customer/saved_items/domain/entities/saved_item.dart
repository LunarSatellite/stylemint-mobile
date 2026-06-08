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

  SavedItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImageUrl,
    String? variantLabel,
    Money? price,
    double? rating,
    DateTime? savedAt,
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
    );
  }
}
