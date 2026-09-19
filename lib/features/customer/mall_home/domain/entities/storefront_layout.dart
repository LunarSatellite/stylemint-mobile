import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';

/// Why the layout looks the way it does. Operator-facing: every value other
/// than [personalized] renders as the same silent default page.
enum StorefrontLayoutStatus {
  personalized,
  noHistory,
  unavailable,

  /// The customer paused personalisation in their Memory Vault. Not a
  /// failure: no error, no nudge, and nothing collected either.
  personalizationPaused,

  /// A status this build does not know. Treated exactly like [unavailable]:
  /// the ordinary page, silently.
  unknown,
}

/// Which recorded signal put a module on the page.
enum StorefrontSignal {
  /// Orders the customer paid for in the window. Named for orders, not
  /// for the removed social-proof field of a similar name.
  recentOrders,
  watchedReels,
  activeMission,
  replenishmentDue,
  sessionIntent,
  unknown,
}

/// What a module is for. [unknown] is a kind a newer server sent and this
/// build cannot draw — it is skipped, never shown as an empty block.
enum StorefrontModuleKind {
  continueMission,
  refill,
  becauseYouWatched,
  boughtBefore,
  unknown,
}

/// One slot the server asks the client to organise the page around.
///
/// The server sends no copy, no imagery and no products: which modules, in
/// what order, about what, and on what evidence. Everything drawn is the
/// client's.
class StorefrontModule {
  const StorefrontModule({
    required this.kind,
    required this.rank,
    required this.signal,
    required this.evidence,
    this.categoryIds = const [],
    this.target,
  });

  final StorefrontModuleKind kind;

  /// 0 is first; contiguous and unique within a layout.
  final int rank;

  final StorefrontSignal signal;

  /// The count behind [signal], as recorded — purchases in the window,
  /// categories this session's watched reels resolved to, outstanding
  /// checklist lines, replenishment suggestions. Always a real observed
  /// number, never an estimate, and only ever shown as a count.
  final int evidence;

  /// The categories this module is about, best first. Empty for a module
  /// that is not category-anchored.
  final List<String> categoryIds;

  /// Where the module points, in the home page's own see-all vocabulary.
  final HomeSeeAll? target;
}

/// What the server sensed about this request.
class StorefrontContext {
  const StorefrontContext({
    required this.sessionIntent,
    this.signalsUsed = const [],
    this.signalsUnavailable = const [],
  });

  static const StorefrontContext none = StorefrontContext(
    sessionIntent: 'browsing',
  );

  /// `browsing`, `researching`, `hunting` or `entertaining`. `browsing` is
  /// also the honest answer when there was nothing to read.
  final String sessionIntent;

  final List<StorefrontSignal> signalsUsed;

  /// Signals whose source could not be read. Their modules are absent rather
  /// than guessed.
  final List<StorefrontSignal> signalsUnavailable;
}

/// The adaptive storefront layout: `GET v1/customer/feed/storefront-layout`.
///
/// The backend ranks the customer's *own* categories by how often they bought
/// from them in the last 90 days, and names the [modules] to organise the page
/// around. It is deterministic and grounded in recorded data — no LLM, no
/// inferred taste. It still does **not** send sections, tiles, products or
/// copy: the Mall's own `GET api/v1/public/home` stays the source of
/// everything shown, and this decides how it is arranged.
///
/// [none] is the invisible fallback: a guest, a failed call, an empty ranking
/// or paused personalisation all produce it, and applying it changes nothing.
class StorefrontLayout {
  const StorefrontLayout({
    required this.rankedCategories,
    required this.isPersonalized,
    this.status = StorefrontLayoutStatus.personalized,
    this.modules = const [],
    this.context = StorefrontContext.none,
  });

  /// Nothing to personalise with — the Mall renders exactly as it does today.
  static const StorefrontLayout none = StorefrontLayout(
    rankedCategories: [],
    isPersonalized: false,
    status: StorefrontLayoutStatus.noHistory,
  );

  /// Most-bought category first. Empty when [isPersonalized] is false.
  final List<StorefrontCategoryRank> rankedCategories;

  /// The server's own word for "this customer has a history worth using".
  /// Scoped to [rankedCategories] alone: a customer with no purchases but an
  /// open mission is still false here and still has [modules].
  final bool isPersonalized;

  /// Why this layout looks the way it does. Operator-facing.
  final StorefrontLayoutStatus status;

  /// The slots to organise the page around, in server rank order.
  final List<StorefrontModule> modules;

  final StorefrontContext context;

  /// Whether applying this layout could change anything at all.
  bool get hasRanking => isPersonalized && rankedCategories.isNotEmpty;

  /// Whether the server asked for any organising at all.
  bool get hasModules => modules.isNotEmpty;

  /// Whether anything at all is on offer. False is the invisible fallback.
  bool get isEmpty => !hasRanking && !hasModules;
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
