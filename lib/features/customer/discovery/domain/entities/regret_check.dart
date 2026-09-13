/// Voyager "Regret-Aware Product Reranker" — the product a shopper is looking
/// at and its same-category alternatives, ordered by how unlikely buyers are
/// to regret them (returns, ratings, stock). Abstains instead of pushing an
/// option when none has a good enough track record. Backend
/// `RegretAwareRanking`.
class RegretCheck {
  const RegretCheck({
    required this.productId,
    required this.abstained,
    required this.summary,
    required this.windowDays,
    required this.options,
    this.recommendedProductId,
  });

  /// The product the check was run for (the one being viewed).
  final String productId;

  /// True when no option has a good enough track record to recommend.
  final bool abstained;

  /// The option to suggest; ignored for display while [abstained].
  final String? recommendedProductId;

  /// One plain sentence explaining the outcome.
  final String summary;

  /// How many days of order history the facts cover.
  final int windowDays;

  /// Best first; the viewed product is one of them.
  final List<RegretOption> options;

  /// Whether there is anything to weigh the viewed product against.
  bool get hasAlternatives => options.length > 1;
}

enum RegretLevel { low, medium, high, unknown }

class RegretOption {
  const RegretOption({
    required this.rank,
    required this.productId,
    required this.productName,
    required this.eligible,
    required this.level,
    required this.reviewCount,
    required this.reasons,
    this.regretScore,
    this.returnRate,
    this.averageRating,
  });

  final int rank;
  final String productId;
  final String productName;

  /// False when the option can't be recommended right now (e.g. out of
  /// stock); still listed so the shopper sees why.
  final bool eligible;
  final RegretLevel level;
  final double? regretScore;
  final double? returnRate;
  final double? averageRating;
  final int reviewCount;

  /// The facts behind this option's position, one short line each.
  final List<String> reasons;
}
