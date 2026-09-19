import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Everything the Discover/Search landing needs in one round-trip
/// (Figma "Search", node 9611-3671).
class DiscoverData {
  const DiscoverData({
    required this.popularSearches,
    required this.categories,
    required this.trending,
    required this.topCreators,
  });

  final List<String> popularSearches; // e.g. "#SneakersAirJordan"
  final List<DiscoverCategory> categories;
  final List<TrendingProduct> trending;
  final List<DiscoverCreator> topCreators;
}

/// A "Browse by Category" chip (emoji + label).
class DiscoverCategory {
  const DiscoverCategory({
    required this.id,
    required this.label,
    required this.emoji,
  });

  final String id;
  final String label;
  final String emoji;
}

/// A product in the "Trending Now" list.
///
/// It used to carry `soldToday`, which no endpoint ever populated — it was
/// always the DTO's default of 0 — while the card it fed rendered
/// "N sold today" behind a flame whenever it was non-zero. The field is gone
/// rather than left as a loaded gun; a units-sold figure comes back only
/// when the contract really carries one.
class TrendingProduct {
  const TrendingProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
  });

  final String id;
  final String name;
  final String imageUrl;
  final Money price;

  /// 0 when the catalogue has no rating for this product. Surfaces must
  /// check before drawing a star: 0 means "unknown", not "one star".
  final double rating;
}

/// A creator in the "Top Creators" list.
class DiscoverCreator {
  const DiscoverCreator({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    required this.category,
    required this.description,
    required this.rating,
    required this.followers,
    required this.isFollowing,
  });

  final String id;
  final String name;
  final String handle; // e.g. "@alieen.ace43"
  final String avatarUrl;
  final String category; // e.g. "Travel & Skincare"
  final String description;
  final double rating;
  final int followers;
  final bool isFollowing;
}
