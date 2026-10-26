import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// One row of `GET v1/creator/reels/{reelRef}/suggested-products` (AI
/// features contract v1.0 §4.1). Plain Dart rather than freezed so the
/// match fields can be read without a codegen step; the first six fields are
/// the ones the app always read.
class SuggestedProductDto {
  const SuggestedProductDto({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.amount,
    required this.currency,
    required this.vendorName,
    this.score,
    this.matchType,
    this.reason,
    this.isOwnProduct,
  });

  factory SuggestedProductDto.fromJson(Map<String, dynamic> p) {
    final score = p['score'];
    final reason = p['reason'];
    final matchType = p['matchType'];
    final own = p['isOwnProduct'];
    return SuggestedProductDto(
      productId: p['productId'] as String? ?? '',
      productName: p['name'] as String? ?? '',
      imageUrl: p['heroImageUrl'] as String? ?? '',
      amount: (p['price'] as num?)?.toDouble() ?? 0.0,
      currency: p['currency'] as String? ?? 'NPR',
      vendorName: p['brandName'] as String? ?? '',
      score: score is num ? score.toDouble() : null,
      matchType: matchType is String ? matchType : null,
      reason: reason is String && reason.trim().isNotEmpty
          ? reason.trim()
          : null,
      isOwnProduct: own is bool ? own : null,
    );
  }

  final String productId;
  final String productName;
  final String imageUrl;
  final double amount;
  final String currency;
  final String vendorName;
  final double? score;

  /// `meaning` or `fallback` (or absent on an older server).
  final String? matchType;
  final String? reason;
  final bool? isOwnProduct;

  bool get isMeaningMatch => matchType == 'meaning';

  TaggedProductForImport toDomain() => TaggedProductForImport(
    productId: productId,
    productName: productName,
    imageUrl: absoluteMediaUrl(imageUrl),
    price: Money(amount: amount, currency: currency),
    vendorName: vendorName,
    // A fallback row carries `score = 0` and a generic reason: neither is a
    // match, so neither is kept.
    matchScore: isMeaningMatch ? score : null,
    matchReason: isMeaningMatch ? reason : null,
    isMeaningMatch: isMeaningMatch,
    isOwnProduct: isOwnProduct,
  );
}
