import 'package:flutter/foundation.dart' show immutable;
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';

/// The fixed feeds of the Discover chips, in display order.
///
/// Every label here describes the **content** behind the chip, because that
/// is all any of these feeds can support. [forYou] is the enum name of the
/// lead chip — it is a code identifier and route key, kept stable — but its
/// label is `The Mall`: the feed is built from the public merchandised home
/// page and the bestselling listing, so a "For You" label was a claim about
/// the reader that nothing in the system made. `ForYouFeedSource` carries the
/// full account of what that feed does and does not know.
enum DiscoverFeedKind {
  forYou('The Mall'),
  trending('Trending'),
  newDrops('New Drops'),
  sale('Sale'),
  reels('Reels'),
  creators('Creators'),
  brands('Brands'),
  collections('Collections');

  const DiscoverFeedKind(this.label);

  final String label;
}

/// A chip above the Discover feed.
@immutable
sealed class DiscoverChip {
  const DiscoverChip();

  /// The fixed chips; category chips follow once the home page is known.
  static const List<DiscoverChip> fixed = [
    DiscoverKindChip(DiscoverFeedKind.forYou),
    DiscoverKindChip(DiscoverFeedKind.trending),
    DiscoverKindChip(DiscoverFeedKind.newDrops),
    DiscoverKindChip(DiscoverFeedKind.sale),
    DiscoverKindChip(DiscoverFeedKind.reels),
    DiscoverKindChip(DiscoverFeedKind.creators),
    DiscoverKindChip(DiscoverFeedKind.brands),
    DiscoverKindChip(DiscoverFeedKind.collections),
  ];

  /// Stable id; also keys the per-chip feed cache.
  String get key;

  String get label;

  @override
  bool operator ==(Object other) => other is DiscoverChip && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

final class DiscoverKindChip extends DiscoverChip {
  const DiscoverKindChip(this.kind);

  final DiscoverFeedKind kind;

  @override
  String get key => kind.name;

  @override
  String get label => kind.label;
}

final class DiscoverCategoryChip extends DiscoverChip {
  const DiscoverCategoryChip(this.category);

  final HomeCategory category;

  @override
  String get key =>
      'category:${category.slug.isEmpty ? category.id : category.slug}';

  @override
  String get label => category.name;
}

/// How a block of cards is laid out.
enum DiscoverLayout { rail, grid }

/// One editorial block of the Discover feed. Every block is labelled by
/// type ([eyebrow]) so the mixed feed reads as curated.
sealed class DiscoverBlock {
  const DiscoverBlock({
    required this.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String key;
  final String eyebrow;
  final String title;
  final String? subtitle;
}

final class DiscoverProductsBlock extends DiscoverBlock {
  const DiscoverProductsBlock({
    required super.key,
    required super.eyebrow,
    required super.title,
    required this.items,
    super.subtitle,
    this.isListing = false,
  });

  final List<HomeProduct> items;

  /// A full product result list: offers the grid/list toggle.
  final bool isListing;
}

final class DiscoverReelsBlock extends DiscoverBlock {
  const DiscoverReelsBlock({
    required super.key,
    required super.eyebrow,
    required super.title,
    required this.items,
    super.subtitle,
    this.layout = DiscoverLayout.rail,
  });

  final List<HomeReel> items;
  final DiscoverLayout layout;
}

final class DiscoverCreatorsBlock extends DiscoverBlock {
  const DiscoverCreatorsBlock({
    required super.key,
    required super.eyebrow,
    required super.title,
    required this.items,
    super.subtitle,
    this.layout = DiscoverLayout.rail,
  });

  final List<HomeCreator> items;
  final DiscoverLayout layout;
}

final class DiscoverBrandsBlock extends DiscoverBlock {
  const DiscoverBrandsBlock({
    required super.key,
    required super.eyebrow,
    required super.title,
    required this.items,
    super.subtitle,
    this.layout = DiscoverLayout.rail,
  });

  final List<HomeBrand> items;
  final DiscoverLayout layout;
}

/// One featured editorial collection card.
final class DiscoverCollectionBlock extends DiscoverBlock {
  const DiscoverCollectionBlock({
    required super.key,
    required super.eyebrow,
    required super.title,
    required this.collection,
    super.subtitle,
  });

  final HomeCollection collection;
}

/// A list of collections (the Collections chip).
final class DiscoverCollectionsBlock extends DiscoverBlock {
  const DiscoverCollectionsBlock({
    required super.key,
    required super.eyebrow,
    required super.title,
    required this.items,
    super.subtitle,
  });

  final List<HomeCollection> items;
}
