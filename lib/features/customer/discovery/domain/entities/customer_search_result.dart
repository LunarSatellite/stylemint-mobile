import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/image_recognition_outcome.dart';

/// Real search-result rows from `GET /api/v1/customer/search`.
class SearchResultProduct {
  const SearchResultProduct({
    required this.productId,
    required this.name,
    required this.heroImageUrl,
    required this.price,
    required this.currency,
    required this.averageRating,
    this.isSponsored = false,
    this.sponsoredLabel,
    this.organicPosition,
    this.matchReason,
  });

  final String productId;
  final String name;
  final String heroImageUrl;
  final double price;
  final String currency;
  final double averageRating;

  /// Voyager "Transparent Sponsored Product Boosting": true when this result
  /// is in a paid slot. Backend `ProductTileDto.IsSponsored`.
  final bool isSponsored;

  /// The disclosure the backend wants shown ("Sponsored"); null otherwise.
  final String? sponsoredLabel;

  /// Where this product ranked organically for the search (1-based); null
  /// for organic results or when unknown.
  final int? organicPosition;

  /// A short explanation supplied by the AI ranker when available.
  final String? matchReason;

  /// The disclosure a sponsored result must show, falling back to
  /// "Sponsored" if the label is missing; null for organic results.
  String? get sponsoredDisclosure =>
      isSponsored ? (sponsoredLabel ?? 'Sponsored') : null;
}

class SearchResultBrand {
  const SearchResultBrand({
    required this.brandId,
    required this.name,
    this.logoUrl,
    required this.averageRating,
    required this.productCount,
  });

  final String brandId;
  final String name;
  final String? logoUrl;
  final double averageRating;
  final int productCount;
}

class SearchResultReel {
  const SearchResultReel({
    required this.reelId,
    required this.thumbnailUrl,
    required this.viewCount,
  });

  final String reelId;
  final String thumbnailUrl;
  final int viewCount;
}

class SearchResultCreator {
  const SearchResultCreator({
    required this.creatorProfileId,
    required this.handle,
    required this.displayName,
    this.avatarUrl,
    required this.followerCount,
  });

  final String creatorProfileId;
  final String handle;
  final String displayName;
  final String? avatarUrl;
  /// Follower total, or null when it was not measured. Null renders as
  /// absent rather than as a zero.
  final int? followerCount;
}

class CustomerSearchResults {
  const CustomerSearchResults({
    required this.products,
    required this.brands,
    required this.reels,
    required this.creators,
    required this.totalHits,
    this.queryUnderstanding,
    this.imageRecognition,
    this.recognizedFeatures = const [],
  });

  static const empty = CustomerSearchResults(
    products: [],
    brands: [],
    reels: [],
    creators: [],
    totalHits: 0,
  );

  final List<SearchResultProduct> products;
  final List<SearchResultBrand> brands;
  final List<SearchResultReel> reels;
  final List<SearchResultCreator> creators;
  final int totalHits;
  final String? queryUnderstanding;

  /// What the image arm of the search achieved, or `null` when no image was
  /// part of the request. When this is anything other than
  /// [ImageRecognitionOutcome.matched], nothing in [products] may be
  /// presented to the customer as recognised from their picture.
  final ImageRecognitionOutcome? imageRecognition;

  /// The features vision read out of the image, so a no-match can say what
  /// was seen instead of shrugging. Empty when nothing was recognised or
  /// when the endpoint does not report features.
  final List<String> recognizedFeatures;
}
