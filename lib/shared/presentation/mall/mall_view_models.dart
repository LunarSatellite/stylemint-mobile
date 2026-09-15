import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

// Small immutable view models consumed by the Mall kit. Feature screens map
// their own domain entities into these; the kit never sees DTOs or entities.

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
  });

  final String id;
  final String name;
  final Money price;
  final String? brandName;
  final String? imageUrl;

  /// Original price. The card shows a sale only when this is higher than
  /// [price] in the same currency.
  final Money? compareAtPrice;

  /// Average rating out of 5.
  final double? rating;
  final bool isNew;
  final bool isLowStock;
  final bool isSaved;

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
