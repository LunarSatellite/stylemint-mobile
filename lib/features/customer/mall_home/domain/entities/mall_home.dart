import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// The Mall home page (`GET api/v1/public/home`): sections in display order.
class MallHome {
  const MallHome({
    required this.sections,
    this.personalized = false,
    this.generatedUtc,
    this.greetingFirstName,
  });

  final List<HomeSection> sections;
  final bool personalized;
  final DateTime? generatedUtc;

  /// Null when anonymous or the account has no name.
  final String? greetingFirstName;
}

/// Where a section's "See all" leads.
enum HomeSeeAllTarget {
  productList,
  reels,
  creators,
  brands,
  collections,
  category,
  collection,
  unknown,
}

class HomeSeeAll {
  const HomeSeeAll({required this.target, this.params = const {}});

  final HomeSeeAllTarget target;

  /// For [HomeSeeAllTarget.productList], the query of
  /// `GET v1/public/products`.
  final Map<String, String> params;
}

/// One section of the home page. Unknown kinds never reach the domain.
sealed class HomeSection {
  const HomeSection({
    required this.id,
    this.eyebrow,
    this.title,
    this.subtitle,
    this.reason,
    this.seeAll,
  });

  /// Stable key, e.g. `new-arrivals`.
  final String id;
  final String? eyebrow;
  final String? title;
  final String? subtitle;

  /// Personalisation hint, e.g. "Because you follow Stylemint Nepal".
  final String? reason;
  final HomeSeeAll? seeAll;
}

final class HomeCampaignsSection extends HomeSection {
  const HomeCampaignsSection({
    required super.id,
    required this.items,
    super.eyebrow,
    super.title,
    super.subtitle,
    super.reason,
    super.seeAll,
  });

  final List<HomeCampaign> items;
}

final class HomeProductsSection extends HomeSection {
  const HomeProductsSection({
    required super.id,
    required this.items,
    super.eyebrow,
    super.title,
    super.subtitle,
    super.reason,
    super.seeAll,
  });

  final List<HomeProduct> items;
}

final class HomeReelsSection extends HomeSection {
  const HomeReelsSection({
    required super.id,
    required this.items,
    super.eyebrow,
    super.title,
    super.subtitle,
    super.reason,
    super.seeAll,
  });

  final List<HomeReel> items;
}

final class HomeCategoriesSection extends HomeSection {
  const HomeCategoriesSection({
    required super.id,
    required this.items,
    super.eyebrow,
    super.title,
    super.subtitle,
    super.reason,
    super.seeAll,
  });

  final List<HomeCategory> items;
}

final class HomeBrandsSection extends HomeSection {
  const HomeBrandsSection({
    required super.id,
    required this.items,
    super.eyebrow,
    super.title,
    super.subtitle,
    super.reason,
    super.seeAll,
  });

  final List<HomeBrand> items;
}

final class HomeCreatorsSection extends HomeSection {
  const HomeCreatorsSection({
    required super.id,
    required this.items,
    super.eyebrow,
    super.title,
    super.subtitle,
    super.reason,
    super.seeAll,
  });

  final List<HomeCreator> items;
}

final class HomeCollectionsSection extends HomeSection {
  const HomeCollectionsSection({
    required super.id,
    required this.items,
    super.eyebrow,
    super.title,
    super.subtitle,
    super.reason,
    super.seeAll,
  });

  final List<HomeCollection> items;
}

/// Always sent, never has items: the client draws its own trust strip.
final class HomeTrustSection extends HomeSection {
  const HomeTrustSection({
    required super.id,
    super.eyebrow,
    super.title,
    super.subtitle,
    super.reason,
    super.seeAll,
  });
}

// ── Cards ──────────────────────────────────────────────────────────────────

enum HomeCtaTargetKind {
  collection,
  reels,
  creators,
  category,
  brand,
  product,
  url,
  unknown,
}

class HomeCampaignCta {
  const HomeCampaignCta({
    required this.label,
    required this.targetKind,
    this.targetValue = '',
  });

  final String label;
  final HomeCtaTargetKind targetKind;

  /// Slug, id or URL depending on [targetKind]; `''` for a directory.
  final String targetValue;
}

class HomeCampaign {
  const HomeCampaign({
    required this.id,
    required this.title,
    this.slug = '',
    this.eyebrow,
    this.subtitle,
    this.heroImageUrl,
    this.heroReelId,
    this.ctas = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? heroImageUrl;
  final String? heroReelId;
  final List<HomeCampaignCta> ctas;
}

class HomeProduct {
  const HomeProduct({
    required this.id,
    required this.name,
    required this.price,
    this.brandName,
    this.vendorAccountId,
    this.imageUrl,
    this.compareAtPrice,
    this.rating,
    this.reviewCount = 0,
    this.isNew = false,
    this.isLowStock = false,
    this.isOnSale = false,
    this.saleEndsUtc,
  });

  final String id;
  final String name;
  final Money price;
  final String? brandName;
  final String? vendorAccountId;
  final String? imageUrl;

  /// Null unless on sale.
  final Money? compareAtPrice;

  /// Null when there are no reviews.
  final double? rating;
  final int reviewCount;
  final bool isNew;
  final bool isLowStock;
  final bool isOnSale;
  final DateTime? saleEndsUtc;
}

class HomeReel {
  const HomeReel({
    required this.id,
    required this.creatorName,
    this.creatorAccountId = '',
    this.posterUrl,
    this.creatorAvatarUrl,
    this.hook,
    this.taggedProductCount = 0,
    this.isAiGenerated = false,
    this.likeCount = 0,
    this.sourcePlatform,
  });

  final String id;
  final String creatorName;
  final String creatorAccountId;
  final String? posterUrl;
  final String? creatorAvatarUrl;

  /// First caption line without links, hashtags or product/CTA lines.
  final String? hook;
  final int taggedProductCount;

  /// Must show the "AI-generated" label when true.
  final bool isAiGenerated;
  final int likeCount;
  final String? sourcePlatform;
}

class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.name,
    this.slug = '',
    this.imageUrl,
  });

  final String id;
  final String slug;
  final String name;
  final String? imageUrl;
}

class HomeBrand {
  const HomeBrand({
    required this.vendorAccountId,
    required this.name,
    this.logoUrl,
    this.coverImageUrl,
    this.tagline,
    this.isVerified = false,
  });

  final String vendorAccountId;
  final String name;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? tagline;
  final bool isVerified;
}

class HomeCreator {
  const HomeCreator({
    required this.accountId,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.coverImageUrl,
    this.isVerified = false,
    this.styleTags = const [],
    this.followerCount,
  });

  final String accountId;
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final String? coverImageUrl;
  final bool isVerified;
  final List<String> styleTags;
  final int? followerCount;
}

class HomeCollection {
  const HomeCollection({
    required this.slug,
    required this.title,
    this.kind = CollectionKind.editorial,
    this.subtitle,
    this.coverImageUrl,
    this.itemCount,
    this.previewImageUrls = const [],
  });

  final String slug;
  final CollectionKind kind;
  final String title;
  final String? subtitle;
  final String? coverImageUrl;
  final int? itemCount;
  final List<String> previewImageUrls;
}
