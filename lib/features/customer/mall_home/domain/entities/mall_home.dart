import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/product_reel_ref.dart';

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
///
/// This is also the routing vocabulary the adaptive storefront speaks: a
/// `StorefrontModule` names its destination with the same `(target, params)`
/// pair, so a module can be lined up with a section the page already renders
/// instead of being guessed at from titles.
enum HomeSeeAllTarget {
  productList,
  reels,
  creators,
  brands,
  collections,
  category,
  collection,

  /// One of the customer's own shopping missions — `params['missionId']`.
  mission,

  /// The replenishment ("Buy It Again") list. No destination screen exists
  /// yet, so this resolves to no route; see [HomeSeeAll].
  reorder,

  unknown,
}

/// Reads a wire `target` name. One parser, so the home page and the adaptive
/// storefront cannot drift apart on what a target is called.
HomeSeeAllTarget homeSeeAllTargetFromWire(String raw) =>
    switch (raw.trim().toLowerCase()) {
      'productlist' => HomeSeeAllTarget.productList,
      'reels' => HomeSeeAllTarget.reels,
      'creators' => HomeSeeAllTarget.creators,
      'brands' => HomeSeeAllTarget.brands,
      'collections' => HomeSeeAllTarget.collections,
      'category' => HomeSeeAllTarget.category,
      'collection' => HomeSeeAllTarget.collection,
      'mission' => HomeSeeAllTarget.mission,
      'reorder' => HomeSeeAllTarget.reorder,
      _ => HomeSeeAllTarget.unknown,
    };

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

/// A typographic prompt: a line of the customer's own business — an open
/// mission, essentials coming due — and one way into it.
///
/// The home API never sends one. It is synthesised by the adaptive storefront
/// for a module the page has no section for, which is why it carries no items
/// and no imagery: it says a fact and opens a screen that already exists.
/// [fact] is a recorded count phrased as a count; the layer that builds it
/// refuses to draw a number the server did not send.
final class HomePromptSection extends HomeSection {
  const HomePromptSection({
    required super.id,
    required this.action,
    this.fact,
    super.eyebrow,
    super.title,
    super.subtitle,
    super.reason,
    super.seeAll,
  });

  /// The label on the block's single control. Where it leads is [seeAll].
  final String action;

  /// The evidence line, already phrased, or null when there is none to show.
  final String? fact;
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
    this.reel,
    this.requiresOptionSelection = true,
    this.defaultVariantId,
    this.isInStock = false,
  });

  final String id;
  final String name;
  final Money price;
  final String? brandName;
  final String? vendorAccountId;

  /// Whether the buyer has to choose a size or a colour before this can go in
  /// a cart. Defaults to `true`: a card that did not say is never quick-added.
  final bool requiresOptionSelection;

  /// The variant a quick add sends. Null when the server sent none.
  final String? defaultVariantId;

  /// Whether the server proved the default variant can currently be bought.
  final bool isInStock;

  /// Product photo. The Mall's tiles never build one — photos are the
  /// product details page's (owner directive, 2026-09-16).
  final String? imageUrl;

  /// The reel this product is sold through. Null for most products.
  final ProductReelRef? reel;

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
