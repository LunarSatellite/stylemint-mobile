/// Rider ratings (rider-rating contract): what a buyer or a vendor said about
/// the StyleMint rider who carried their parcel, and what those ratings add
/// up to.
///
/// Hand-written, tolerant reads like the delivery-request entities: the
/// backend ships these fields after the app, so every parser here accepts a
/// missing or malformed field and leaves it null rather than throwing — the
/// screens hide what they cannot show.
library;

/// The fixed tag list. Positive tags go with 4–5 stars, negative ones with
/// 1–3; the form offers only the set that matches the stars picked.
enum RiderRatingTag {
  onTime('OnTime', 'On time', positive: true),
  friendly('Friendly', 'Friendly', positive: true),
  carefulWithParcel(
    'CarefulWithParcel',
    'Careful with parcel',
    positive: true,
  ),
  goodCommunication(
    'GoodCommunication',
    'Good communication',
    positive: true,
  ),
  professional('Professional', 'Professional', positive: true),
  late('Late', 'Late', positive: false),
  rude('Rude', 'Rude', positive: false),
  parcelDamaged('ParcelDamaged', 'Parcel damaged', positive: false),
  hardToReach('HardToReach', 'Hard to reach', positive: false),
  wrongLocation('WrongLocation', 'Went to the wrong place', positive: false);

  const RiderRatingTag(this.wire, this.label, {required this.positive});

  final String wire;
  final String label;
  final bool positive;

  /// The contract allows at most four tags on one rating.
  static const maxPerRating = 4;

  /// Case- and separator-insensitive; null for a tag this app does not know
  /// (a newer server's tag is dropped, not shown raw).
  static RiderRatingTag? fromWire(Object? value) {
    final raw = _norm(value);
    if (raw == null) return null;
    for (final tag in values) {
      if (tag.wire.toLowerCase() == raw) return tag;
    }
    return null;
  }

  /// A JSON list of tag strings, unknown and repeated ones dropped.
  static List<RiderRatingTag> listFrom(Object? value) {
    if (value is! List) return const [];
    final seen = <RiderRatingTag>{};
    for (final item in value) {
      final tag = fromWire(item);
      if (tag != null) seen.add(tag);
    }
    return seen.toList(growable: false);
  }

  /// The tags that fit [stars]: praise for 4–5, problems for 1–3.
  static List<RiderRatingTag> forStars(int stars) => values
      .where((tag) => tag.positive == (stars >= 4))
      .toList(growable: false);
}

/// Who gave a rating. The PUT/GET path segment differs by role.
enum RiderRaterRole {
  buyer('Buyer', 'customer'),
  vendor('Vendor', 'vendor');

  const RiderRaterRole(this.wire, this.pathSegment);

  final String wire;

  /// `/v1/{pathSegment}/sub-orders/{id}/rider-rating`.
  final String pathSegment;

  static RiderRaterRole? fromWire(Object? value) {
    final raw = _norm(value);
    if (raw == null) return null;
    if (raw == 'buyer' || raw == 'customer') return RiderRaterRole.buyer;
    if (raw == 'vendor' || raw == 'seller') return RiderRaterRole.vendor;
    return null;
  }
}

/// `riderRating: { stars, tags }` on an order's `delivery` block — enough to
/// show what was said without another call.
class RiderRatingBrief {
  const RiderRatingBrief({required this.stars, this.tags = const []});

  final int stars;
  final List<RiderRatingTag> tags;

  @override
  bool operator ==(Object other) =>
      other is RiderRatingBrief &&
      other.stars == stars &&
      other.tags.length == tags.length &&
      other.tags.every(tags.contains);

  @override
  int get hashCode => Object.hash(stars, Object.hashAllUnordered(tags));

  /// Null when absent, not an object, or the stars are not 1–5.
  static RiderRatingBrief? fromJson(Object? value) {
    if (value is! Map) return null;
    final stars = readStars(value['stars']);
    if (stars == null) return null;
    return RiderRatingBrief(
      stars: stars,
      tags: RiderRatingTag.listFrom(value['tags']),
    );
  }
}

/// `RiderRatingDto`: one rating as saved, with when it can still be changed.
class RiderRating {
  const RiderRating({
    required this.subOrderId,
    required this.stars,
    this.courierId,
    this.riderName,
    this.raterRole,
    this.tags = const [],
    this.comment,
    this.createdUtc,
    this.updatedUtc,
    this.editableUntilUtc,
  });

  /// Null when the body has no valid star count — a rating without stars is
  /// not one, and the card falls back to what the order said.
  static RiderRating? fromJson(Object? value) {
    if (value is! Map) return null;
    final stars = readStars(value['stars']);
    if (stars == null) return null;
    return RiderRating(
      subOrderId: _text(value['subOrderId']) ?? '',
      courierId: _text(value['courierId']),
      riderName: _text(value['riderName']),
      raterRole: RiderRaterRole.fromWire(value['raterRole']),
      stars: stars,
      tags: RiderRatingTag.listFrom(value['tags']),
      comment: _text(value['comment']),
      createdUtc: _date(value['createdUtc']),
      updatedUtc: _date(value['updatedUtc']),
      editableUntilUtc: _date(value['editableUntilUtc']),
    );
  }

  final String subOrderId;
  final String? courierId;
  final String? riderName;
  final RiderRaterRole? raterRole;
  final int stars;
  final List<RiderRatingTag> tags;
  final String? comment;
  final DateTime? createdUtc;
  final DateTime? updatedUtc;

  /// Seven days after delivery (or pickup). Null when the server did not
  /// say; the caller's own eligibility flag decides then.
  final DateTime? editableUntilUtc;

  RiderRatingBrief get brief => RiderRatingBrief(stars: stars, tags: tags);

  bool isEditableAt(DateTime nowUtc) {
    final until = editableUntilUtc;
    return until == null || nowUtc.isBefore(until);
  }
}

/// Whether a rating can be given on one sub-order, and what was given — the
/// `courierId`, `canRateRider` and `riderRating` fields the contract adds to
/// the buyer's `delivery` block and to the vendor's sub-order detail.
class RiderRatingEligibility {
  const RiderRatingEligibility({
    required this.canRateRider,
    this.courierId,
    this.rating,
  });

  /// Null when the payload carries neither field, i.e. a backend without
  /// ratings: the rating UI is then not drawn at all.
  static RiderRatingEligibility? fromJson(Object? value) {
    if (value is! Map) return null;
    final can = value['canRateRider'];
    final rating = RiderRatingBrief.fromJson(value['riderRating']);
    if (can == null && rating == null) return null;
    return RiderRatingEligibility(
      canRateRider: can == true || can?.toString().toLowerCase() == 'true',
      courierId: _text(value['courierId']),
      rating: rating,
    );
  }

  final bool canRateRider;
  final String? courierId;
  final RiderRatingBrief? rating;

  /// Something to show: a rating to give, or one already given.
  bool get isShown => canRateRider || rating != null;

  @override
  bool operator ==(Object other) =>
      other is RiderRatingEligibility &&
      other.canRateRider == canRateRider &&
      other.courierId == courierId &&
      other.rating == rating;

  @override
  int get hashCode => Object.hash(canRateRider, courierId, rating);
}

/// A tag and how often it was given.
class RiderTagCount {
  const RiderTagCount(this.tag, this.count);

  final RiderRatingTag tag;
  final int count;

  static List<RiderTagCount> listFrom(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map)
          if (RiderRatingTag.fromWire(item['tag']) case final tag?)
            RiderTagCount(tag, _int(item['count']) ?? 0),
    ];
  }
}

/// What a rider's ratings add up to.
class RiderRatingSummary {
  const RiderRatingSummary({
    required this.count,
    this.average,
    this.breakdown = const {},
    this.topTags = const [],
  });

  /// `{ average, count, breakdown, topTags }`; null when not an object.
  static RiderRatingSummary? fromJson(Object? value) {
    if (value is! Map) return null;
    final breakdown = <int, int>{};
    final raw = value['breakdown'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        final stars = int.tryParse(entry.key.toString());
        final count = _int(entry.value);
        if (stars != null && stars >= 1 && stars <= 5 && count != null) {
          breakdown[stars] = count;
        }
      }
    }
    final average = _double(value['average']);
    return RiderRatingSummary(
      // Zero or below is not an average anybody gave.
      average: average != null && average > 0 ? average : null,
      count: _int(value['count']) ?? 0,
      breakdown: breakdown,
      topTags: RiderTagCount.listFrom(value['topTags']),
    );
  }

  /// Null under three ratings: the app says "New rider" rather than letting
  /// one early review define someone.
  final double? average;
  final int count;

  /// Stars (1–5) to how many ratings gave that many.
  final Map<int, int> breakdown;
  final List<RiderTagCount> topTags;

  bool get isNew => average == null;

  /// The tallest bar, for scaling the breakdown.
  int get largestBucket =>
      breakdown.values.fold(0, (max, n) => n > max ? n : max);
}

/// One review as shown to someone other than its author: no rater name.
class RiderReview {
  const RiderReview({
    required this.stars,
    this.tags = const [],
    this.comment,
    this.raterRole,
    this.ageDays,
  });

  static List<RiderReview> listFrom(Object? value, {int? max}) {
    if (value is! List) return const [];
    final reviews = <RiderReview>[
      for (final item in value)
        if (item is Map)
          if (readStars(item['stars']) case final stars?)
            RiderReview(
              stars: stars,
              tags: RiderRatingTag.listFrom(item['tags']),
              comment: _text(item['comment']),
              raterRole: RiderRaterRole.fromWire(item['raterRole']),
              ageDays: _int(item['ageDays']),
            ),
    ];
    return max == null || reviews.length <= max
        ? reviews
        : reviews.sublist(0, max);
  }

  final int stars;
  final List<RiderRatingTag> tags;
  final String? comment;
  final RiderRaterRole? raterRole;
  final int? ageDays;

  /// "Today", "Yesterday", "3 days ago"; null when the age is unknown.
  String? get ageLabel {
    final days = ageDays;
    if (days == null || days < 0) return null;
    return switch (days) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => '$days days ago',
    };
  }
}

/// `GET /v1/courier/me/rating`: the rider's own summary and latest reviews.
class CourierRatingOverview {
  const CourierRatingOverview({required this.summary, this.recent = const []});

  static CourierRatingOverview? fromJson(Object? value) {
    final summary = RiderRatingSummary.fromJson(value);
    if (summary == null || value is! Map) return null;
    return CourierRatingOverview(
      summary: summary,
      recent: RiderReview.listFrom(value['recent'], max: 10),
    );
  }

  final RiderRatingSummary summary;
  final List<RiderReview> recent;
}

/// 1–5, or null.
int? readStars(Object? value) {
  final stars = _int(value);
  return stars != null && stars >= 1 && stars <= 5 ? stars : null;
}

String? _norm(Object? value) {
  final raw = value?.toString().trim().toLowerCase().replaceAll(
    RegExp('[ _-]'),
    '',
  );
  return raw == null || raw.isEmpty ? null : raw;
}

String? _text(Object? value) {
  final raw = value?.toString().trim();
  return raw == null || raw.isEmpty ? null : raw;
}

int? _int(Object? value) => switch (value) {
  final num v => v.toInt(),
  final String v => int.tryParse(v) ?? double.tryParse(v)?.toInt(),
  _ => null,
};

double? _double(Object? value) => switch (value) {
  final num v => v.toDouble(),
  final String v => double.tryParse(v),
  _ => null,
};

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}
