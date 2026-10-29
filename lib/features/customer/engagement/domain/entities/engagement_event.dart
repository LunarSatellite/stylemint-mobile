/// What happened, in the words of `POST v1/customer/feed/interactions` (AI
/// features contract v1.0 §2.1).
///
/// Likes, unlikes and purchases are deliberately absent: the server records
/// those itself (`ReelLikedV1`, `ReelUnlikedV1`, `OrderPlacedV1`) and
/// attributes a purchase to the reel of the latest `tag_tap` /
/// `add_to_cart` for that product. Sending them would count them twice.
enum EngagementKind {
  /// The viewer left a reel after watching it — one per exposure.
  view('view'),

  /// Playback reached the end (≥ 90 %); sent in addition to the [view].
  complete('complete'),

  /// Left within 1.5 s; sent instead of a [view].
  skip('skip'),
  save('save'),
  unsave('unsave'),

  /// The share sheet completed, or the link was copied.
  share('share'),

  /// A tagged-product card on a reel was tapped.
  tagTap('tag_tap'),

  /// A product page was opened.
  productView('product_view'),

  /// An item was added to the cart.
  addToCart('add_to_cart');

  const EngagementKind(this.wire);

  final String wire;

  static EngagementKind? parse(Object? raw) {
    for (final kind in values) {
      if (kind.wire == raw) return kind;
    }
    return null;
  }

  /// Whether the event is about a reel, and so needs a `reelId`.
  bool get needsReel => switch (this) {
    view || complete || skip || save || unsave || share || tagTap => true,
    productView || addToCart => false,
  };

  /// Whether the event is about a product, and so needs a `productId`.
  bool get needsProduct =>
      this == tagTap || this == productView || this == addToCart;
}

/// Where in the app the event happened (`surface`, optional on the wire).
enum EngagementSurface {
  feed('feed'),
  reelDetail('reel_detail'),
  profile('profile'),
  search('search'),
  product('product'),
  other('other');

  const EngagementSurface(this.wire);

  final String wire;

  static EngagementSurface? parse(Object? raw) {
    for (final surface in values) {
      if (surface.wire == raw) return surface;
    }
    return null;
  }
}

/// One event, ready for the batch.
///
/// [clientEventId] is minted once, when the event happens, and kept through
/// every retry: the server stores events idempotently by it, so a batch that
/// is sent twice (the answer was lost, the app was killed mid-flight) counts
/// once.
class EngagementEvent {
  const EngagementEvent({
    required this.clientEventId,
    required this.kind,
    required this.occurredUtc,
    this.reelId,
    this.productId,
    this.dwellMs,
    this.watchFraction,
    this.surface,
    this.requestId,
    this.position,
  });

  /// Reads one persisted event; null when it is not one this build wrote.
  static EngagementEvent? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['clientEventId'];
    final kind = EngagementKind.parse(raw['kind']);
    final at = DateTime.tryParse(raw['occurredUtc']?.toString() ?? '');
    if (id is! String || id.isEmpty || kind == null || at == null) return null;
    final dwell = raw['dwellMs'];
    final fraction = raw['watchFraction'];
    final reelId = raw['reelId'];
    final productId = raw['productId'];
    return EngagementEvent(
      clientEventId: id,
      kind: kind,
      occurredUtc: at.toUtc(),
      reelId: reelId is String && reelId.isNotEmpty ? reelId : null,
      productId: productId is String && productId.isNotEmpty ? productId : null,
      dwellMs: dwell is num ? dwell.toInt() : null,
      watchFraction: fraction is num ? fraction.toDouble() : null,
      surface: EngagementSurface.parse(raw['surface']),
      requestId: readRankingRequestId(raw['requestId']),
      position: readRankingPosition(raw['position']),
    );
  }

  final String clientEventId;
  final EngagementKind kind;
  final DateTime occurredUtc;
  final String? reelId;
  final String? productId;

  /// `view` only: time on screen, 0..600000.
  final int? dwellMs;

  /// `view` only: how much of the reel played, 0..1.
  final double? watchFraction;
  final EngagementSurface? surface;

  /// The ranking response the item was served in (personal feed `requestId`
  /// or search `requestId`), echoed for ranking-model training. Null when
  /// the item did not come from such a response, or the server sent none.
  final String? requestId;

  /// The item's 0-based place in that ranking; null when unknown.
  final int? position;

  /// The longest dwell the contract accepts.
  static const int maxDwellMs = 600000;

  Map<String, dynamic> toJson() => {
    'clientEventId': clientEventId,
    'kind': kind.wire,
    'reelId': ?reelId,
    'productId': ?productId,
    if (dwellMs case final dwell?) 'dwellMs': dwell.clamp(0, maxDwellMs),
    if (watchFraction case final fraction?)
      'watchFraction': fraction.clamp(0.0, 1.0),
    'occurredUtc': occurredUtc.toUtc().toIso8601String(),
    if (surface case final where?) 'surface': where.wire,
    'requestId': ?requestId,
    'position': ?position,
  };
}

/// A ranking `requestId` as sent by the server, or null when absent or blank.
String? readRankingRequestId(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

/// A 0-based ranking position, or null when absent, negative or not a number.
int? readRankingPosition(Object? raw) {
  final value = raw is num
      ? (raw == raw.truncate() ? raw.toInt() : null)
      : (raw is String ? int.tryParse(raw.trim()) : null);
  return value != null && value >= 0 ? value : null;
}

/// The share of a reel that played, or null when its length is unknown.
///
/// Without a position from the player, the best measure is time on screen
/// over length, capped at 1 for a reel that looped.
double? reelWatchFraction(Duration dwell, int? durationSeconds) {
  if (durationSeconds == null || durationSeconds <= 0) return null;
  final fraction = dwell.inMilliseconds / (durationSeconds * 1000);
  return fraction.clamp(0.0, 1.0);
}

/// The events not yet accepted by the server, and whose they are.
class PendingEngagement {
  const PendingEngagement({required this.owner, required this.events});

  /// The account the events were recorded for. A queue is only ever sent
  /// for its own account: after a sign-out or an account switch it is
  /// thrown away, never delivered under somebody else's token.
  final String owner;
  final List<EngagementEvent> events;
}

/// How one batch went, and so what to do with its events.
enum EngagementSendOutcome {
  /// Stored (`204`). Never resent.
  accepted,

  /// The endpoint is not deployed (`404`): stop batching for this run and
  /// leave the older per-signal path to do what it always did.
  notDeployed,

  /// Refused for good (`400`, `401`, `403`, any other `4xx`): dropped, since
  /// sending it again would be refused again.
  rejected,

  /// The network failed, timed out, or the server erred (`5xx`, `429`):
  /// kept and retried later with the same `clientEventId`s.
  retry,
}
