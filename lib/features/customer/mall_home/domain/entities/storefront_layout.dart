/// The adaptive storefront layout: `GET v1/customer/feed/storefront-layout`.
///
/// The backend ranks the customer's *own* categories by how often they bought
/// from them in the last 90 days. It is deterministic and grounded in real
/// purchase data — no LLM, no inferred taste. It does **not** send sections,
/// tiles or copy: the Mall's own `GET api/v1/public/home` stays the source of
/// everything shown, and this only decides the order it is shown in.
///
/// [none] is the invisible fallback: a guest, a failed call, an empty ranking
/// or paused personalisation all produce it, and applying it changes nothing.
class StorefrontLayout {
  const StorefrontLayout({
    required this.rankedCategories,
    required this.isPersonalized,
  });

  /// Nothing to personalise with — the Mall renders exactly as it does today.
  static const StorefrontLayout none = StorefrontLayout(
    rankedCategories: [],
    isPersonalized: false,
  );

  /// Most-bought category first. Empty when [isPersonalized] is false.
  final List<StorefrontCategoryRank> rankedCategories;

  /// The server's own word for "this customer has a history worth using".
  final bool isPersonalized;

  /// Whether applying this layout could change anything at all.
  bool get hasRanking => isPersonalized && rankedCategories.isNotEmpty;
}

/// One category in the ranking.
class StorefrontCategoryRank {
  const StorefrontCategoryRank({
    required this.categoryId,
    required this.label,
    required this.recentPurchaseCount,
  });

  /// The catalog category id, as the home page also reports it.
  final String categoryId;

  /// The server's display label, e.g. "Dresses". May be the placeholder
  /// "Category" when the catalog lookup failed, so never shown on its own.
  final String label;

  final int recentPurchaseCount;
}
