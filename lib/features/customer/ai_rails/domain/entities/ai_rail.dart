import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

/// Why a rail holds what it holds (AI features contract v1.0 §3 `status`,
/// plus the client's own "the server does not have this yet").
enum AiRailStatus {
  /// The server computed neighbours and sent them.
  ok,

  /// Collaborative filtering ran and too few people produced a pair. Items
  /// are empty; the page shows its other rails instead.
  notEnoughData,

  /// The feature is off or failed on the server. Items are empty.
  unavailable,

  /// The endpoint is not deployed (404) or the call failed. Items are empty
  /// and the page behaves exactly as it did before the rail existed.
  notDeployed;

  static AiRailStatus parse(Object? raw) => switch (raw) {
    'ok' => ok,
    'notEnoughData' => notEnoughData,
    // An unknown status is treated as nothing to show, never as "ok".
    _ => unavailable,
  };
}

/// One collaborative-filtering rail: aggregate "people who … also …"
/// neighbours of one item, best first. Never says who.
class AiRail<T> {
  const AiRail({required this.items, required this.status});

  const AiRail.empty(this.status) : items = const [];

  final List<T> items;
  final AiRailStatus status;

  bool get hasItems => items.isNotEmpty;
}

/// How a reel was matched to a product or to another reel (AI features
/// contract v1.0 §4.2 / §4.3 `matchType`).
enum ReelMatchKind {
  /// The reel tags the product.
  featured,

  /// Close in meaning (reel and product or reel vectors).
  meaning,

  /// A value this build does not know. Shown as a plain reel.
  unknown;

  static ReelMatchKind parse(Object? raw) => switch (raw) {
    'featured' => featured,
    'meaning' => meaning,
    _ => unknown,
  };
}

/// One reel in a §4 answer.
class MatchedReel {
  const MatchedReel({
    required this.reel,
    required this.kind,
    this.score,
    this.reason,
  });

  final Reel reel;
  final ReelMatchKind kind;

  /// Similarity, comparable only within one answer. Never drawn as a figure.
  final double? score;
  final String? reason;
}

/// A §4.2 / §4.3 answer, or [notDeployed] when the server does not have the
/// endpoint yet (the caller then falls back to what it showed before).
class ReelMatches {
  const ReelMatches({
    required this.items,
    required this.aiApplied,
    this.notDeployed = false,
  });

  const ReelMatches.notDeployed()
    : items = const [],
      aiApplied = false,
      notDeployed = true;

  final List<MatchedReel> items;

  /// Whether meaning matching contributed to this answer.
  final bool aiApplied;
  final bool notDeployed;

  /// Reels that tag the product, in server order.
  List<MatchedReel> get featured => [
    for (final item in items)
      if (item.kind == ReelMatchKind.featured) item,
  ];

  /// Reels matched by meaning — only when meaning matching really ran.
  List<MatchedReel> get byMeaning => aiApplied
      ? [
          for (final item in items)
            if (item.kind == ReelMatchKind.meaning) item,
        ]
      : const [];
}

/// A rail of products ("Frequently bought together", "People also viewed").
typedef ProductRail = AiRail<RelatedProduct>;

/// A rail of reels ("People also watched").
typedef ReelRail = AiRail<Reel>;
