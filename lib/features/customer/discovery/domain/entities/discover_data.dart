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
class TrendingProduct {
  const TrendingProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.soldToday,
  });

  final String id;
  final String name;
  final String imageUrl;
  final Money price;
  final double rating;
  final int soldToday;
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
