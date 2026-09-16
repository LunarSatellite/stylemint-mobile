import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

// Small immutable view models consumed by the Mall kit. Feature screens map
// their own domain entities into these; the kit never sees DTOs or entities.

/// The reel a product is sold through, when it has one.
///
/// Null on most products — 24 of 106 carry a reel on production data — so
/// every Mall surface has to render well without it. The field does not
/// exist on the server yet either, so it is always parsed defensively.
@immutable
class MallReelRef {
  const MallReelRef({
    required this.reelId,
    this.posterUrl,
    this.hook,
    this.isAiGenerated = false,
    this.durationSeconds = 0,
  });

  final String reelId;

  /// Poster frame. Null until the platform sync has run.
  final String? posterUrl;

  /// The reel's opening line.
  final String? hook;

  /// AI-generated reels must carry the visible "AI-generated" label. Only
  /// ever what the server sent — never inferred.
  final bool isAiGenerated;

  /// Runtime in whole seconds; 0 when unknown, and then no duration shows.
  final int durationSeconds;

  bool get hasDuration => durationSeconds > 0;
}

@immutable
class MallProductVm {
  const MallProductVm({
    required this.id,
    required this.name,
    required this.price,
    this.brandName,
    this.imageUrl,
    this.compareAtPrice,
    this.rating,
    this.isNew = false,
    this.isLowStock = false,
    this.isSaved = false,
    this.reviewCount = 0,
    this.saleEndsUtc,
    this.reel,
  });

  final String id;
  final String name;
  final Money price;
  final String? brandName;

  /// Product photo. Shown on the product details page only: the Mall is
  /// video-first, so its tiles never build a product photo (owner directive,
  /// 2026-09-16). Kept on the view model because the details page and the
  /// surfaces around it still use it.
  final String? imageUrl;

  /// Original price. The card shows a sale only when this is higher than
  /// [price] in the same currency.
  final Money? compareAtPrice;

  /// Average rating out of 5.
  final double? rating;
  final bool isNew;
  final bool isLowStock;
  final bool isSaved;

  /// Ratings behind [rating]. Zero when the product has none.
  final int reviewCount;

  /// When the running sale ends, as the server sent it. Null when there is no
  /// sale — never inferred.
  final DateTime? saleEndsUtc;

  /// The product's reel. Null for most products, which then show the
  /// designed type tile instead of a poster.
  final MallReelRef? reel;

  /// The same product with its heart set to [saved].
  ///
  /// Rebuilding the view model field by field at call sites is how new fields
  /// quietly go missing, so the copy lives here with the fields.
  MallProductVm withSaved({required bool saved}) => saved == isSaved
      ? this
      : MallProductVm(
          id: id,
          name: name,
          price: price,
          brandName: brandName,
          imageUrl: imageUrl,
          compareAtPrice: compareAtPrice,
          rating: rating,
          isNew: isNew,
          isLowStock: isLowStock,
          isSaved: saved,
          reviewCount: reviewCount,
          saleEndsUtc: saleEndsUtc,
          reel: reel,
        );

  bool get isOnSale {
    final was = compareAtPrice;
    return was != null &&
        was.currency == price.currency &&
        was.amount > price.amount;
  }

  /// Whole-number discount, rounded down so it is never overstated. Null
  /// when not on sale or when the saving is under 1%.
  int? get discountPercent {
    final was = compareAtPrice;
    if (!isOnSale || was == null) return null;
    final percent = ((1 - price.amount / was.amount) * 100).floor();
    return percent >= 1 ? percent : null;
  }
}

@immutable
class MallReelVm {
  const MallReelVm({
    required this.id,
    required this.creatorName,
    this.posterUrl,
    this.creatorAvatarUrl,
    this.caption,
    this.taggedProductCount = 0,
    this.isAiGenerated = false,
    this.likeCount,
  });

  final String id;
  final String creatorName;
  final String? posterUrl;
  final String? creatorAvatarUrl;
  final String? caption;
  final int taggedProductCount;

  /// AI-generated reels must carry the visible "AI-generated" label.
  final bool isAiGenerated;
  final int? likeCount;
}

@immutable
class MallCreatorVm {
  const MallCreatorVm({
    required this.id,
    required this.name,
    this.handle,
    this.avatarUrl,
    this.coverUrl,
    this.isVerified = false,
    this.styleTags = const [],
    this.followerCount,
  });

  final String id;
  final String name;
  final String? handle;
  final String? avatarUrl;
  final String? coverUrl;
  final bool isVerified;
  final List<String> styleTags;
  final int? followerCount;
}

@immutable
class MallBrandVm {
  const MallBrandVm({
    required this.id,
    required this.name,
    this.logoUrl,
    this.coverUrl,
    this.isVerified = false,
    this.tagline,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? coverUrl;
  final bool isVerified;
  final String? tagline;
}

@immutable
class MallCategoryVm {
  const MallCategoryVm({required this.id, required this.label, this.imageUrl});

  final String id;
  final String label;
  final String? imageUrl;
}

@immutable
class MallCollectionVm {
  const MallCollectionVm({
    required this.id,
    required this.title,
    this.eyebrow,
    this.coverUrl,
    this.itemCount,
    this.previewImageUrls = const [],
  });

  final String id;
  final String title;
  final String? eyebrow;
  final String? coverUrl;
  final int? itemCount;

  /// Up to three are shown as thumbnails.
  final List<String> previewImageUrls;
}

/// A call to action on a campaign. The first action renders as the filled
/// primary button; the rest render as glass buttons. At most three show.
@immutable
class MallCampaignAction {
  const MallCampaignAction({required this.id, required this.label});

  final String id;
  final String label;
}

@immutable
class MallCampaignVm {
  const MallCampaignVm({
    required this.id,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.imageUrl,
    this.actions = const [],
  });

  final String id;
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? imageUrl;
  final List<MallCampaignAction> actions;
}

@immutable
class MallTrustItem {
  const MallTrustItem({required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;
}
