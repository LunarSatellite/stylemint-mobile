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
    this.limitedTime = 'Limited time',
    this.shopTheDrop = 'Shop the drop',
    this.onlyAFewLeft = 'Only a few left',
    this.endsToday = 'Ends today',
    this.endsTomorrow = 'Ends tomorrow',
    this.discountBadge = _discountBadge,
    this.percentOff = _percentOff,
    this.wasPrice = _wasPrice,
    this.rating = _rating,
    this.saveItem = _saveItem,
    this.unsaveItem = _unsaveItem,
    this.watchReel = 'Watch reel',
    this.reelDuration = _reelDuration,
    this.spokenReelDuration = _spokenReelDuration,
    this.taggedProducts = _taggedProducts,
    this.likes = _likes,
    this.followers = _followers,
    this.itemCount = _itemCount,
    this.slideOf = _slideOf,
    this.reelBy = _reelBy,
    this.reviews = _reviews,
    this.endsIn = _endsIn,
    this.endsInDays = _endsInDays,
    this.upToPercentOff = _upToPercentOff,
    this.picks = _picks,
    this.verifiedCount = _verifiedCount,
    this.taggedTotal = _taggedTotal,
    this.pieces = _pieces,
    this.addToBag = 'Add to bag',
    this.added = 'Added',
    this.addItem = _addItem,
    this.chooseOptions = 'Choose options',
    this.chooseItem = _chooseItem,
    this.addFailed = "Couldn't add to bag",
    this.viewItem = 'View',
    this.biggestSaving = 'Biggest saving here',
    this.endingSoonest = 'Ending soonest here',
    this.bestReviewed = 'Best reviewed here',
    this.justArrived = 'Just arrived',
    this.inTheMall = 'In the Mall right now',
    this.brandCount = _brandCount,
    this.creatorCount = _creatorCount,
    this.categoryCount = _categoryCount,
    this.editCount = _editCount,
    this.reelCount = _reelCount,
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

  /// Eyebrow fallback on the drop block when the server sent none.
  final String limitedTime;

  /// Primary action on the drop block.
  final String shopTheDrop;

  /// Honest wording for `isLowStock`, which the contract defines as 1–5 units
  /// left. The exact count is not sent, so no number is shown.
  final String onlyAFewLeft;
  final String endsToday;
  final String endsTomorrow;

  /// Discount pill text, e.g. "-30%".
  final String Function(int percent) discountBadge;

  /// Spoken discount, e.g. "30% off".
  final String Function(int percent) percentOff;

  /// Spoken original price, e.g. "was Rs 4,999".
  final String Function(String formattedPrice) wasPrice;
  final String Function(double rating) rating;
  final String Function(String name) saveItem;
  final String Function(String name) unsaveItem;

  /// What tapping a reel tile does.
  final String watchReel;

  /// Runtime on a reel poster, e.g. "0:12".
  final String Function(int seconds) reelDuration;

  /// Spoken runtime, e.g. "12 second reel".
  final String Function(int seconds) spokenReelDuration;
  final String Function(int count) taggedProducts;
  final String Function(int count) likes;
  final String Function(int count) followers;
  final String Function(int count) itemCount;
  final String Function(int position, int total) slideOf;
  final String Function(String creator) reelBy;

  /// Ratings behind a score, e.g. "12 reviews".
  final String Function(int count) reviews;

  /// Live countdown, e.g. "Ends in 4h 12m".
  final String Function(String remaining) endsIn;

  /// Coarse deadline for a card, e.g. "Ends in 3 days".
  final String Function(int days) endsInDays;

  /// Best discount in a block, e.g. "Up to 30% off".
  final String Function(int percent) upToPercentOff;

  /// How many cards a rail carries, e.g. "12 picks".
  final String Function(int count) picks;

  /// Verified accounts in a rail, e.g. "4 verified".
  final String Function(int count) verifiedCount;

  /// Products tagged across a reel rail, e.g. "9 products tagged".
  final String Function(int count) taggedTotal;

  /// Products across a collection block, e.g. "48 pieces".
  final String Function(int count) pieces;

  /// Quick-add's label on a block wide enough to spell it out.
  final String addToBag;

  /// Quick-add's confirmation, held briefly after the item lands.
  final String added;

  /// Spoken quick-add, e.g. "Add Linen co-ord set to bag".
  final String Function(String name) addItem;

  /// Words on the buy control of a product whose buyer has to pick a size or
  /// a colour first. It opens the product page, so it must not say "add".
  final String chooseOptions;

  /// Spoken label of that control, e.g. "Choose options for Linen co-ord set".
  final String Function(String name) chooseItem;

  /// Spoken state when an add did not go through.
  final String addFailed;

  /// Secondary action beside quick-add: open the product.
  final String viewItem;

  /// Why one product earned the spotlight. Each is a fact the block checked
  /// against its own items — never a claim about the catalogue at large.
  final String biggestSaving;
  final String endingSoonest;
  final String bestReviewed;
  final String justArrived;

  /// Spoken name of the directory band.
  final String inTheMall;

  final String Function(int count) brandCount;
  final String Function(int count) creatorCount;
  final String Function(int count) categoryCount;

  /// Collections, e.g. "32 edits".
  final String Function(int count) editCount;
  final String Function(int count) reelCount;

  static String _discountBadge(int percent) => '-$percent%';

  static String _percentOff(int percent) => '$percent% off';

  static String _wasPrice(String price) => 'was $price';

  static String _rating(double rating) =>
      'Rated ${rating.toStringAsFixed(1)} out of 5';

  static String _saveItem(String name) => 'Save $name';

  static String _unsaveItem(String name) => 'Remove $name from saved';

  static String _reelDuration(int seconds) {
    final total = seconds < 0 ? 0 : seconds;
    final minutes = total ~/ 60;
    return '$minutes:${(total % 60).toString().padLeft(2, '0')}';
  }

  static String _spokenReelDuration(int seconds) =>
      seconds == 1 ? '1 second reel' : '$seconds second reel';

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

  static String _reviews(int count) =>
      count == 1 ? '1 review' : '$count reviews';

  static String _endsIn(String remaining) => 'Ends in $remaining';

  static String _endsInDays(int days) =>
      days == 1 ? 'Ends in 1 day' : 'Ends in $days days';

  static String _upToPercentOff(int percent) => 'Up to $percent% off';

  static String _picks(int count) => count == 1 ? '1 pick' : '$count picks';

  static String _verifiedCount(int count) => '$count verified';

  static String _taggedTotal(int count) =>
      count == 1 ? '1 product tagged' : '$count products tagged';

  static String _pieces(int count) => count == 1 ? '1 piece' : '$count pieces';

  static String _addItem(String name) => 'Add $name to bag';

  static String _chooseItem(String name) => 'Choose options for $name';

  static String _brandCount(int count) =>
      count == 1 ? '1 brand' : '$count brands';

  static String _creatorCount(int count) =>
      count == 1 ? '1 creator' : '$count creators';

  static String _categoryCount(int count) =>
      count == 1 ? '1 category' : '$count categories';

  static String _editCount(int count) => count == 1 ? '1 edit' : '$count edits';

  static String _reelCount(int count) => count == 1 ? '1 reel' : '$count reels';
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
