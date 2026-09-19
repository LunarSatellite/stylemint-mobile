import 'package:flutter/foundation.dart' show immutable;

/// Where a companion recommendation actually came from, mirroring the backend
/// `RecommendationBasis`.
///
/// This replaced a `double Score` that every code path filled with a hand
/// written literal — 0.8, 0.75, 0.7 — while the copy read "Matches your food
/// preferences". A basis is a fact; a score was a figure measuring nothing.
enum RecommendationBasis {
  /// Drawn from the category of a product this customer really viewed, liked,
  /// saved or bought. The only value that asserts anything personal.
  shoppedCategory,

  /// Globally popular products or trending reels. Identical for every
  /// customer, carrying no personal signal at all.
  popularNow,

  /// A basis this build does not know. Degrades conservatively: never
  /// personal, and its label claims nothing.
  unknown;

  /// Reads the wire value, integer ordinal or name. An absent or unrecognised
  /// value is [unknown] — never [shoppedCategory].
  static RecommendationBasis parse(Object? raw) {
    if (raw is num) {
      return switch (raw.toInt()) {
        1 => shoppedCategory,
        2 => popularNow,
        _ => unknown,
      };
    }
    if (raw is String) {
      final name = raw.trim().toLowerCase();
      if (name.isEmpty) return unknown;
      return switch (name) {
        'shoppedcategory' || 'shopped_category' => shoppedCategory,
        'popularnow' || 'popular_now' => popularNow,
        _ => parse(int.tryParse(name)),
      };
    }
    return unknown;
  }

  /// True only for [shoppedCategory]. [unknown] is false, permanently.
  bool get isPersonal => this == shoppedCategory;

  /// The eyebrow above the card. [popularNow] and [unknown] say nothing about
  /// the reader; [shoppedCategory] names the real mechanism rather than
  /// implying a model.
  String get label => switch (this) {
    RecommendationBasis.shoppedCategory => 'From a category you shopped',
    RecommendationBasis.popularNow => 'Popular right now',
    RecommendationBasis.unknown => 'From the Mall',
  };
}

/// One suggestion from Minty.
///
/// Two absences are deliberate:
///
/// * **No score.** The backend removed `Score` outright rather than making it
///   nullable, because a permanently-null field is the same defect wearing a
///   different shape. Nothing here ranks anything, so there is no number.
/// * **No thumbnail.** The wire still carries `thumbnailUrl`, and for a
///   product that is a product photograph. The Mall is video-first and product
///   photos appear on product detail and nowhere else, so the field is not
///   modelled: a card cannot draw what the entity does not hold.
@immutable
class CompanionRecommendation {
  const CompanionRecommendation({
    required this.entityId,
    required this.entityType,
    required this.title,
    required this.friendMessage,
    required this.basis,
    required this.reason,
  });

  final String entityId;

  /// `product` or `reel`, lowercased.
  final String entityType;
  final String title;

  /// Minty's own line about the item.
  final String friendMessage;

  final RecommendationBasis basis;

  /// The server's true sentence about why this item is here — "Popular in the
  /// same category as Runner X, which you saved", or "Popular with shoppers
  /// right now".
  ///
  /// Rendered **verbatim**. The strings are already written to be true, and
  /// rephrasing them client-side is how a true sentence becomes a claim
  /// nobody checked.
  final String reason;

  bool get isProduct => entityType == 'product';
  bool get isReel => entityType == 'reel';

  @override
  bool operator ==(Object other) =>
      other is CompanionRecommendation &&
      other.entityId == entityId &&
      other.entityType == entityType &&
      other.title == title &&
      other.friendMessage == friendMessage &&
      other.basis == basis &&
      other.reason == reason;

  @override
  int get hashCode =>
      Object.hash(entityId, entityType, title, friendMessage, basis, reason);
}
