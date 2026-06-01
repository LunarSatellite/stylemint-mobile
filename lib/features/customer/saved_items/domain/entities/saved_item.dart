import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A single saved / wishlisted item for the customer.
class SavedItem {
  const SavedItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.price,
    required this.rating,
    required this.savedAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final Money price;
  final double rating;
  final DateTime savedAt;

  SavedItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImageUrl,
    Money? price,
    double? rating,
    DateTime? savedAt,
  }) {
    return SavedItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}
