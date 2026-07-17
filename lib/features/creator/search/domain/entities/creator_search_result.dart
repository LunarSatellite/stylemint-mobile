enum CreatorSearchType { brands, products, creators }

class SearchBrandResult {
  const SearchBrandResult({
    required this.brandId,
    required this.name,
    this.logoUrl,
    required this.averageRating,
    required this.productCount,
    required this.commissionRange,
  });

  final String brandId;
  final String name;
  final String? logoUrl;
  final double averageRating;
  final int productCount;
  final String commissionRange;
}

class SearchProductResult {
  const SearchProductResult({
    required this.productId,
    required this.name,
    required this.heroImageUrl,
    required this.price,
    required this.currency,
    required this.brandId,
    required this.brandName,
  });

  final String productId;
  final String name;
  final String heroImageUrl;
  final double price;
  final String currency;
  final String brandId;
  final String brandName;
}

class SearchCreatorResult {
  const SearchCreatorResult({
    required this.creatorProfileId,
    required this.handle,
    required this.displayName,
    this.avatarUrl,
    required this.followerCount,
    required this.reelCount,
  });

  final String creatorProfileId;
  final String handle;
  final String displayName;
  final String? avatarUrl;
  final int followerCount;
  final int reelCount;
}
