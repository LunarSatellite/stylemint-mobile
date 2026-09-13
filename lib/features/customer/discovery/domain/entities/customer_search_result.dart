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
  final int followerCount;
}

class CustomerSearchResults {
  const CustomerSearchResults({
    required this.products,
    required this.brands,
    required this.reels,
    required this.creators,
    required this.totalHits,
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
}
