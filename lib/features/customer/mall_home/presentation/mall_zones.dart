import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

// How the Mall decides what each section looks like, and what it is allowed
// to say about it.
//
// Everything here is a pure function of the section the server sent, so the
// page has no layout opinions of its own and all of this is unit-testable.
//
// The rule that matters: a signal is built from a field the API populated, or
// it is not built. Nothing on this page estimates, extrapolates or rounds a
// number up to look busier than the data is. Where a zone wanted a figure the
// contract does not carry — units sold, stock counts, live viewers — the
// figure is simply absent rather than invented.

/// The four treatments the Mall page is built from. They differ in density
/// and dress, never in identity: one palette, one type scale, one motion
/// language runs through all four.
enum MallZone {
  /// Full-bleed stages that move: the campaign hero and the reel marquee.
  cinematic,

  /// Magazine blocks: collections and the brands behind them.
  editorial,

  /// Compact, information-rich rails carrying live signals.
  discovery,

  /// Colour-blocked graphic moments: a real drop, and the category mosaic.
  retail,
}

/// The treatment [section] is drawn with, or null for the trust strip, which
/// closes the page and belongs to no zone.
MallZone? zoneFor(HomeSection section) => switch (section) {
  HomeCampaignsSection() => MallZone.cinematic,
  HomeReelsSection() => MallZone.cinematic,
  HomeCollectionsSection() => MallZone.editorial,
  HomeBrandsSection() => MallZone.editorial,
  HomeCategoriesSection() => MallZone.retail,
  HomeCreatorsSection() => MallZone.discovery,
  HomeProductsSection(:final items) =>
    isDropBlock(items) ? MallZone.retail : MallZone.discovery,
  // Typography and one control: the editorial plate, not a retail one.
  HomePromptSection() => MallZone.editorial,
  HomeTrustSection() => null,
};

/// Whether a products block has earned the bold-retail plate.
///
/// Decided by the data, not by the section's id: the plate promises a drop,
/// so it only appears when the items really carry one — a live sale deadline,
/// or several genuine discounts. A rail the server happened to call "deals"
/// with nothing discounted in it stays a discovery rail.
bool isDropBlock(List<HomeProduct> items) {
  if (items.any((product) => product.saleEndsUtc != null)) return true;
  return items.where((product) => discountPercentOf(product) != null).length >=
      2;
}

/// Whole-number discount for [product], floored so it is never overstated,
/// or null when there is no genuine saving in the same currency.
int? discountPercentOf(HomeProduct product) {
  final was = product.compareAtPrice;
  if (was == null ||
      was.currency != product.price.currency ||
      was.amount <= product.price.amount) {
    return null;
  }
  final percent = ((1 - product.price.amount / was.amount) * 100).floor();
  return percent >= 1 ? percent : null;
}

/// What the drop plate is allowed to claim about a block.
@immutable
class MallDealFacts {
  const MallDealFacts({this.topDiscountPercent, this.endsUtc});

  /// Reads [items] for the only two numbers the plate may show.
  factory MallDealFacts.from(List<HomeProduct> items) {
    int? top;
    DateTime? soonest;
    for (final product in items) {
      final percent = discountPercentOf(product);
      if (percent != null && (top == null || percent > top)) top = percent;
      final ends = product.saleEndsUtc;
      if (ends != null && (soonest == null || ends.isBefore(soonest))) {
        soonest = ends;
      }
    }
    return MallDealFacts(topDiscountPercent: top, endsUtc: soonest);
  }

  /// Largest real discount in the block, or null when nothing is discounted.
  final int? topDiscountPercent;

  /// Soonest real sale deadline in the block, or null when none was sent.
  final DateTime? endsUtc;

  bool get isEmpty => topDiscountPercent == null && endsUtc == null;

  @override
  bool operator ==(Object other) =>
      other is MallDealFacts &&
      other.topDiscountPercent == topDiscountPercent &&
      other.endsUtc == endsUtc;

  @override
  int get hashCode => Object.hash(topDiscountPercent, endsUtc);
}

/// Whole days, in Kathmandu, between [now] and [endsUtc]: 0 is later today.
int kathmanduDaysUntil(DateTime endsUtc, DateTime now) {
  DateTime dayOf(DateTime instant) {
    final local = instant.toUtc().add(nepalUtcOffset);
    return DateTime.utc(local.year, local.month, local.day);
  }

  return dayOf(endsUtc).difference(dayOf(now)).inDays;
}

/// Longest lead time a card still calls out. Past this a deadline is not news.
const int mallDeadlineHorizonDays = 14;

/// The one live fact a product card carries under its price, or null when the
/// API gave this product nothing worth saying.
///
/// Ordered by what a shopper acts on: a real deadline, then genuinely low
/// stock, then how well reviewed it is. The rating itself already shows on
/// the image, so the line adds the count behind it rather than repeating it.
MallSignal? mallProductSignal(
  HomeProduct product, {
  required DateTime now,
  required MallStrings strings,
}) {
  final ends = product.saleEndsUtc;
  if (ends != null) {
    final days = kathmanduDaysUntil(ends, now);
    if (days >= 0 && days <= mallDeadlineHorizonDays) {
      return MallSignal(
        label: switch (days) {
          0 => strings.endsToday,
          1 => strings.endsTomorrow,
          _ => strings.endsInDays(days),
        },
        tone: MallSignalTone.urgent,
        icon: Icons.schedule_rounded,
      );
    }
  }
  // The contract defines low stock as 1–5 units left and sends no count, so
  // the card says that and no more.
  if (product.isLowStock) {
    return MallSignal(
      label: strings.onlyAFewLeft,
      tone: MallSignalTone.urgent,
      icon: Icons.inventory_2_outlined,
    );
  }
  if (product.rating != null && product.reviewCount > 0) {
    return MallSignal(label: strings.reviews(product.reviewCount));
  }
  return null;
}

// ── The spotlight ──────────────────────────────────────────────────────────

/// Why one product was given the whole block.
///
/// Each value is a fact checked against the block's own items, which is why
/// the copy says "here" — the claim is about this block, never the catalogue.
enum MallSpotlightReason {
  /// Largest genuine discount among the items.
  biggestSaving,

  /// Soonest real sale deadline among the items.
  endingSoonest,

  /// Most-reviewed item that also carries a rating.
  bestReviewed,

  /// Flagged new by the server.
  justArrived,
}

/// The product a block leads with, and why.
@immutable
class MallSpotlightPick {
  const MallSpotlightPick({required this.product, this.reason});

  final HomeProduct product;

  /// Null when the API gave this block nothing to single anybody out for. The
  /// block still runs — a name, a price and a way to buy is a complete idea —
  /// it just makes no claim it cannot support.
  final MallSpotlightReason? reason;

  @override
  bool operator ==(Object other) =>
      other is MallSpotlightPick &&
      other.product == product &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(product, reason);
}

/// The item [items] leads with, or null when the block is empty.
///
/// Ordered by what a shopper acts on: money off, then a deadline, then what
/// other people thought, then newness. Falls through to the first item with
/// no reason attached rather than skipping the block, because a thin
/// catalogue still deserves a composed page.
MallSpotlightPick? spotlightPickOf(List<HomeProduct> items) {
  if (items.isEmpty) return null;

  HomeProduct? best;
  var bestPercent = 0;
  for (final product in items) {
    final percent = discountPercentOf(product);
    if (percent != null && percent > bestPercent) {
      best = product;
      bestPercent = percent;
    }
  }
  if (best != null) {
    return MallSpotlightPick(
      product: best,
      reason: MallSpotlightReason.biggestSaving,
    );
  }

  HomeProduct? soonest;
  for (final product in items) {
    final ends = product.saleEndsUtc;
    if (ends == null) continue;
    if (soonest == null || ends.isBefore(soonest.saleEndsUtc!)) {
      soonest = product;
    }
  }
  if (soonest != null) {
    return MallSpotlightPick(
      product: soonest,
      reason: MallSpotlightReason.endingSoonest,
    );
  }

  HomeProduct? reviewed;
  for (final product in items) {
    if (product.rating == null || product.reviewCount <= 0) continue;
    if (reviewed == null || product.reviewCount > reviewed.reviewCount) {
      reviewed = product;
    }
  }
  if (reviewed != null) {
    return MallSpotlightPick(
      product: reviewed,
      reason: MallSpotlightReason.bestReviewed,
    );
  }

  final arrival = items.where((product) => product.isNew).firstOrNull;
  if (arrival != null) {
    return MallSpotlightPick(
      product: arrival,
      reason: MallSpotlightReason.justArrived,
    );
  }

  return MallSpotlightPick(product: items.first);
}

/// The eyebrow for [reason], or null when the pick makes no claim.
String? mallSpotlightEyebrow(
  MallSpotlightReason? reason,
  MallStrings strings,
) => switch (reason) {
  MallSpotlightReason.biggestSaving => strings.biggestSaving,
  MallSpotlightReason.endingSoonest => strings.endingSoonest,
  MallSpotlightReason.bestReviewed => strings.bestReviewed,
  MallSpotlightReason.justArrived => strings.justArrived,
  null => null,
};

/// Which section on the page leads with the spotlight, or null for none.
///
/// One per page: the block is a statement, and a page of statements is a page
/// of noise. The drop plate is skipped — it is already the loud one, and two
/// oversized discount numerals in a row read as a mistake rather than a
/// rhythm.
int? spotlightSectionIndex(List<HomeSection> sections) {
  for (var index = 0; index < sections.length; index++) {
    final section = sections[index];
    if (section is! HomeProductsSection) continue;
    if (isDropBlock(section.items)) continue;
    if (spotlightPickOf(section.items) == null) continue;
    return index;
  }
  return null;
}

// ── The directory band ─────────────────────────────────────────────────────

/// The words the signage band scrolls: the brands, edits and categories the
/// page is actually carrying, interleaved so the band reads as a directory
/// rather than as three lists stitched together.
///
/// Names only — no counts, no claims. Every string is one the server sent,
/// so the band gets richer as the catalogue does and never overstates it.
List<String> mallTickerWords(List<HomeSection> sections, {int max = 16}) {
  final brands = <String>[];
  final edits = <String>[];
  final categories = <String>[];
  for (final section in sections) {
    switch (section) {
      case HomeBrandsSection(:final items):
        brands.addAll(items.map((item) => item.name));
      case HomeCollectionsSection(:final items):
        edits.addAll(items.map((item) => item.title));
      case HomeCategoriesSection(:final items):
        categories.addAll(items.map((item) => item.name));
      case HomeCampaignsSection() ||
          HomeProductsSection() ||
          HomeReelsSection() ||
          HomeCreatorsSection() ||
          HomePromptSection() ||
          HomeTrustSection():
        break;
    }
  }

  final lanes = [brands, edits, categories];
  final longest = lanes.fold(0, (a, lane) => lane.length > a ? lane.length : a);
  final words = <String>[];
  final seen = <String>{};
  for (var index = 0; index < longest && words.length < max; index++) {
    for (final lane in lanes) {
      if (index >= lane.length) continue;
      final word = lane[index].trim();
      if (word.isEmpty || !seen.add(word.toLowerCase())) continue;
      words.add(word);
      if (words.length == max) break;
    }
  }
  return words;
}

/// Fewer than this and a marquee reads as a glitch rather than a directory.
const int mallTickerMinimumWords = 3;

/// The block the directory band is hung under: the first one after the
/// stage, so the page's one self-moving element lands where it is seen and
/// the stage hands over to the shopping rather than simply stopping.
int? tickerSectionIndex(List<HomeSection> sections) {
  for (var index = 0; index < sections.length; index++) {
    final section = sections[index];
    if (section is HomeCampaignsSection || section is HomeTrustSection) {
      continue;
    }
    // Nothing to separate if it is the last thing on the page.
    return index == sections.length - 1 ? null : index;
  }
  return null;
}

/// Whether any card in [items] has something to say, and so whether the rail
/// should reserve the signal slot for all of them.
bool mallRailHasSignals(
  List<HomeProduct> items, {
  required DateTime now,
  required MallStrings strings,
}) => items.any(
  (product) =>
      mallProductSignal(product, now: now, strings: strings) != null,
);

/// The live facts shown beside a section's title.
///
/// Each one counts something the response actually contains; a section whose
/// data supports no claim gets no chips.
List<MallSignal> mallSectionMeta(HomeSection section, MallStrings strings) =>
    switch (section) {
      HomeProductsSection(:final items) => _productMeta(items, strings),
      HomeReelsSection(:final items) => _reelMeta(items, strings),
      HomeCreatorsSection(:final items) => _verifiedMeta(
        items.where((creator) => creator.isVerified).length,
        strings,
      ),
      HomeBrandsSection(:final items) => _verifiedMeta(
        items.where((brand) => brand.isVerified).length,
        strings,
      ),
      HomeCollectionsSection(:final items) => _collectionMeta(items, strings),
      // The recorded count the server sent, phrased as the count it is and
      // placed where the kit puts one scannable fact.
      HomePromptSection(:final fact) => fact == null
          ? const []
          : [MallSignal(label: fact)],
      HomeCampaignsSection() ||
      HomeCategoriesSection() ||
      HomeTrustSection() => const [],
    };

List<MallSignal> _productMeta(List<HomeProduct> items, MallStrings strings) {
  final discounts = items.map(discountPercentOf).nonNulls;
  final top = discounts.isEmpty
      ? null
      : discounts.reduce((a, b) => a > b ? a : b);
  return [
    MallSignal(label: strings.picks(items.length)),
    if (top != null)
      MallSignal(
        label: strings.upToPercentOff(top),
        tone: MallSignalTone.accent,
      ),
  ];
}

List<MallSignal> _reelMeta(List<HomeReel> items, MallStrings strings) {
  var tagged = 0;
  for (final reel in items) {
    tagged += reel.taggedProductCount;
  }
  return [
    if (tagged > 0)
      MallSignal(
        label: strings.taggedTotal(tagged),
        tone: MallSignalTone.accent,
        icon: Icons.shopping_bag_outlined,
      ),
  ];
}

List<MallSignal> _verifiedMeta(int verified, MallStrings strings) => [
  if (verified > 0)
    MallSignal(
      label: strings.verifiedCount(verified),
      tone: MallSignalTone.accent,
      icon: Icons.verified_rounded,
    ),
];

List<MallSignal> _collectionMeta(
  List<HomeCollection> items,
  MallStrings strings,
) {
  var pieces = 0;
  for (final collection in items) {
    pieces += collection.itemCount ?? 0;
  }
  return [if (pieces > 0) MallSignal(label: strings.pieces(pieces))];
}
