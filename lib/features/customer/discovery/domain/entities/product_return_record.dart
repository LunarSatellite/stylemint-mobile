/// Capability 10, "Regret-aware ranking", as far as the platform's own data
/// honestly reaches: `GET /v1/public/products/{id}/return-record`.
///
/// ## What is deliberately absent
///
/// There is no score, no level, no confidence and no rank anywhere in this
/// file, and there is no cross-category number for anything to be measured
/// against. The endpoint this replaces shipped all four, and the blend was
/// computed against a single universal worst-return-rate constant — so 6% on
/// a book read as fine and 25% on a shoe read as near-worst, for reasons that
/// had nothing to do with either product. Return rates are a property of
/// categories far more than of products.
///
/// Every rate here is nullable and travels beside the two counts it was
/// divided from, so nothing downstream can render a percentage on its own.
library;

/// How one product's return record sits against the measured record of its
/// own category — the only comparison this capability makes.
enum CategoryComparison {
  /// Either the product or its category is below the minimum volume, so no
  /// comparison exists. An absent value, not a middle one.
  notEnoughData,

  /// Came back less often than the category's own measured rate.
  belowCategoryTypical,

  /// Within the band where the two rates are indistinguishable.
  aboutCategoryTypical,

  /// Came back more often than the category's own measured rate.
  aboveCategoryTypical,

  /// A value this build does not know. Treated exactly like
  /// [notEnoughData]: no comparison is drawn.
  unknown;

  /// True when there is a comparison worth stating. Renderers gate on this
  /// rather than listing the two absent cases at every call site, which is
  /// how a new server value would otherwise slip through as a blank chip.
  bool get isStated =>
      this != CategoryComparison.notEnoughData &&
      this != CategoryComparison.unknown;
}

/// The measured return record of one category, and the only basis a product
/// is ever compared against.
///
/// When the category has not sold enough, or too few products contributed,
/// [available] is false, [returnsPerHundredSold] is null and
/// [unavailableReason] says which test failed. There is no floored or
/// borrowed rate to fall back on.
class CategoryReturnBasis {
  const CategoryReturnBasis({
    required this.categoryId,
    required this.available,
    required this.productsCounted,
    required this.unitsSold,
    required this.unitsReturned,
    this.unavailableReason,
    this.returnsPerHundredSold,
  });

  final String categoryId;
  final bool available;

  /// Which volume test failed, in the server's own words. Null while
  /// [available].
  final String? unavailableReason;

  final int productsCounted;
  final int unitsSold;
  final int unitsReturned;

  /// Null whenever it could not be measured from real sales and real
  /// returns. Never defaulted.
  final int? returnsPerHundredSold;

  /// True only when there is a rate *and* the counts behind it, which is the
  /// only form in which it may be shown.
  bool get hasQuotableRate =>
      available && returnsPerHundredSold != null && unitsSold > 0;
}

/// The fit-to-resell split for one product's returned units.
///
/// [notFitToResell] counts units a person handling the actual item routed
/// somewhere other than straight back onto the shelf. It is a handling
/// record: not a fault finding, not a judgement of the seller, and not a
/// claim about why any buyer sent anything back.
class ReturnedUnitSplit {
  const ReturnedUnitSplit({
    required this.classifiedReturns,
    required this.fitToResell,
    required this.notFitToResell,
  });

  final int classifiedReturns;
  final int fitToResell;
  final int notFitToResell;
}

/// One product's recorded return facts.
///
/// [returnsPerHundredSold] is null unless [hasEnoughSales] and a real
/// denominator exist. [returnedUnits] is null for most products — absent
/// means nobody recorded where the units were sent, never "none came back
/// unfit".
class ProductReturnOption {
  const ProductReturnOption({
    required this.position,
    required this.suppliedPosition,
    required this.productId,
    required this.productName,
    required this.hasEnoughSales,
    required this.unitsSold,
    required this.unitsReturned,
    required this.comparedWithCategory,
    this.returnsPerHundredSold,
    this.returnedUnits,
    this.facts = const <String>[],
  });

  final int position;
  final int suppliedPosition;
  final String productId;
  final String productName;

  /// False when the product has not sold enough in the window for its own
  /// rate to have a denominator worth quoting.
  final bool hasEnoughSales;

  final int unitsSold;
  final int unitsReturned;
  final int? returnsPerHundredSold;
  final CategoryComparison comparedWithCategory;
  final ReturnedUnitSplit? returnedUnits;

  /// The server's counts in plain words. Carried for contract fidelity; the
  /// card states the same counts from the structured fields above rather
  /// than printing each one twice.
  final List<String> facts;

  /// True only when a rate exists *and* the two counts it came from exist.
  /// A renderer that gates on this cannot show a rate without its counts.
  bool get hasQuotableRate =>
      hasEnoughSales && returnsPerHundredSold != null && unitsSold > 0;
}

/// A product and its same-category alternatives, with the return counts
/// behind each one.
class ProductReturnRecord {
  const ProductReturnRecord({
    required this.productId,
    required this.categoryId,
    required this.windowDays,
    required this.orderingApplied,
    required this.basis,
    required this.options,
    this.orderingSkippedReason,
  });

  final String productId;
  final String categoryId;

  /// How many days of sales and returns the counts cover.
  final int windowDays;

  /// Whether the server reordered the supplied options. Nothing in the UI
  /// numbers or ranks them, so this needs no disclosure — it is carried so
  /// the contract stays whole.
  final bool orderingApplied;
  final String? orderingSkippedReason;

  final CategoryReturnBasis basis;
  final List<ProductReturnOption> options;

  /// The options that have a rate with its counts. Everything else is left
  /// out entirely rather than shown as a zero, a dash or an empty slot.
  List<ProductReturnOption> get quotableOptions =>
      options.where((o) => o.hasQuotableRate).toList(growable: false);

  /// Nothing is worth drawing unless at least one option can be quoted.
  bool get hasQuotableOptions => quotableOptions.isNotEmpty;
}
