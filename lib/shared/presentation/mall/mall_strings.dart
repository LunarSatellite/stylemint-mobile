import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';

/// User-facing copy used inside the Mall kit.
///
/// Defaults are English. Once the app's localisations land, wrap the Mall
/// page in a [MallStringsScope] carrying translated strings; every component
/// reads its copy through [MallStrings.of].
@immutable
class MallStrings {
  const MallStrings({
    this.seeAll = 'See all',
    this.newBadge = 'New',
    this.lowStockBadge = 'Low stock',
    this.aiGenerated = 'AI-generated',
    this.verified = 'Verified',
    this.loading = 'Loading',
    this.featured = 'Featured',
    this.discountBadge = _discountBadge,
    this.percentOff = _percentOff,
    this.wasPrice = _wasPrice,
    this.rating = _rating,
    this.saveItem = _saveItem,
    this.unsaveItem = _unsaveItem,
    this.taggedProducts = _taggedProducts,
    this.likes = _likes,
    this.followers = _followers,
    this.itemCount = _itemCount,
    this.slideOf = _slideOf,
    this.reelBy = _reelBy,
  });

  static const MallStrings english = MallStrings();

  /// The nearest [MallStringsScope]'s strings, or [english].
  static MallStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MallStringsScope>()?.strings ??
      english;

  final String seeAll;
  final String newBadge;
  final String lowStockBadge;

  /// Disclosure label on AI-generated reels. Required whenever a reel is
  /// flagged — never hide or truncate it.
  final String aiGenerated;
  final String verified;
  final String loading;

  /// Semantic name of the campaign hero carousel.
  final String featured;

  /// Discount pill text, e.g. "-30%".
  final String Function(int percent) discountBadge;

  /// Spoken discount, e.g. "30% off".
  final String Function(int percent) percentOff;

  /// Spoken original price, e.g. "was Rs 4,999".
  final String Function(String formattedPrice) wasPrice;
  final String Function(double rating) rating;
  final String Function(String name) saveItem;
  final String Function(String name) unsaveItem;
  final String Function(int count) taggedProducts;
  final String Function(int count) likes;
  final String Function(int count) followers;
  final String Function(int count) itemCount;
  final String Function(int position, int total) slideOf;
  final String Function(String creator) reelBy;

  static String _discountBadge(int percent) => '-$percent%';

  static String _percentOff(int percent) => '$percent% off';

  static String _wasPrice(String price) => 'was $price';

  static String _rating(double rating) =>
      'Rated ${rating.toStringAsFixed(1)} out of 5';

  static String _saveItem(String name) => 'Save $name';

  static String _unsaveItem(String name) => 'Remove $name from saved';

  static String _taggedProducts(int count) =>
      count == 1 ? '1 product' : '$count products';

  static String _likes(int count) =>
      count == 1 ? '1 like' : '${formatCompactNumber(count)} likes';

  static String _followers(int count) =>
      count == 1 ? '1 follower' : '${formatCompactNumber(count)} followers';

  static String _itemCount(int count) => count == 1 ? '1 item' : '$count items';

  static String _slideOf(int position, int total) =>
      'Slide $position of $total';

  static String _reelBy(String creator) => 'Reel by $creator';
}

/// Provides [MallStrings] to the Mall components below it.
class MallStringsScope extends InheritedWidget {
  const MallStringsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  final MallStrings strings;

  @override
  bool updateShouldNotify(MallStringsScope oldWidget) =>
      !identical(strings, oldWidget.strings);
}
