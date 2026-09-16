import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

// Small immutable view models consumed by the Mall kit. Feature screens map
// their own domain entities into these; the kit never sees DTOs or entities.

/// The reel a product is sold through, when it has one.
///
/// Parsed defensively so older payloads and products still syncing their reel
/// can fall back gracefully.
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
    this.requiresOptionSelection = true,
    this.defaultVariantId,
    this.isInStock = false,
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

  /// The product's reel. A temporarily missing value falls back to the
  /// designed type tile instead of leaving a broken poster.
  final MallReelRef? reel;

  /// Whether the buyer must choose a size or a colour before this product can
  /// go in a cart — true when the card has an option offering a real choice,
  /// or more than one variant.
  ///
  /// Defaults to **true**, which is the safe answer: a card whose payload did
  /// not carry the field (every card, until the server ships it) sends the
  /// buyer to the product page rather than putting a guessed size in the bag.
  final bool requiresOptionSelection;

  /// The variant the server would have picked, sent explicitly on a quick add
  /// so nothing is left implicit. Null when the card did not carry one, and
  /// then there is no quick add — see [canQuickAdd].
  final String? defaultVariantId;

  /// Whether the server proved this card's default variant is buyable now.
  /// False by default so an older or malformed payload never offers Add.
  final bool isInStock;

  /// Whether this product may be added straight from a tile.
  ///
  /// Both halves of the contract have to hold: the card said no choice is
  /// needed **and** it named the variant to send. `false` with no default
  /// variant id is a card we cannot add without guessing, so it opens its
  /// page like any other.
  bool get canQuickAdd =>
      isInStock && !requiresOptionSelection && defaultVariantId != null;

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
          requiresOptionSelection: requiresOptionSelection,
          defaultVariantId: defaultVariantId,
          isInStock: isInStock,
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
    this.reelId,
    this.actions = const [],
  });

  final String id;
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? imageUrl;
  final String? reelId;
  final List<MallCampaignAction> actions;
}

@immutable
class MallTrustItem {
  const MallTrustItem({required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;
}
