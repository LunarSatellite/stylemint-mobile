/// Real search-result rows from `GET /api/v1/customer/search`.
class SearchResultProduct {
  const SearchResultProduct({
    required this.productId,
    required this.name,
    required this.heroImageUrl,
    required this.price,
    required this.currency,
    required this.averageRating,
  });

  final String productId;
  final String name;
  final String heroImageUrl;
  final double price;
  final String currency;
  final double averageRating;
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
