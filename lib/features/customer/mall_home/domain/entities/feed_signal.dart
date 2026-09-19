/// A signal sent to `POST v1/customer/feed/interaction`, which is what shapes
/// the adaptive storefront and the realtime intent the feed reads.
///
/// Only the kinds the backend actually consumes exist here. The server reads
/// `reel`/`watched` and `reel`/`skipped` to boost and suppress, and derives
/// the current intent from `viewed_detail` (researching), `searched`
/// (hunting), `watched` (entertaining) and `bought` (back to browsing).
/// Anything else would be a write nobody reads.
enum FeedSignalEntity {
  reel('reel'),
  product('product'),
  search('search');

  const FeedSignalEntity(this.wire);

  final String wire;
}

enum FeedSignalAction {
  /// A reel held the viewer's attention, not merely appeared.
  watched('watched'),

  /// A reel was swiped past almost immediately.
  skipped('skipped'),

  /// A product details page was opened — the strongest intent the app has.
  viewedDetail('viewed_detail'),

  /// A search was submitted.
  searched('searched'),

  /// An order was placed; the server treats this as intent satisfied.
  bought('bought');

  const FeedSignalAction(this.wire);

  final String wire;
}

/// One interaction, ready for the wire.
///
/// Two shapes, and the constructors are the only way to build either, so an
/// invalid combination cannot exist in the first place — the same rule the
/// backend enforces in `RealtimePersonalizationService.TrackInteractionAsync`:
///
///  * **id-shaped** ([FeedSignal.forEntity]) — every signal except a
///    free-text search. `entityId` must be a real id; blank and the zero
///    GUID are both refused, because the server refuses them too and an
///    invented id would teach the feed a lie.
///  * **query-shaped** ([FeedSignal.searchedQuery]) — a free-text search,
///    which has no id to send. It carries the raw text in `query`, sends no
///    `entityId` at all, and exists only for the `searched` action.
///
/// `query` is never sent by an id-shaped signal, and `entityId` is never
/// sent by a query-shaped one; the server rejects either mix-up.
class FeedSignal {
  const FeedSignal._({
    required this.entity,
    required this.action,
    this.entityId,
    this.query,
  });

  /// A signal about a specific entity — a reel, a product, or a search
  /// scoped to a known category.
  ///
  /// Throws [ArgumentError] when [entityId] is blank or an all-zero GUID:
  /// those are exactly the values the backend rejects, so catching them
  /// here turns a silently dropped signal into a visible programming error.
  factory FeedSignal.forEntity({
    required String entityId,
    required FeedSignalEntity entity,
    required FeedSignalAction action,
  }) {
    final id = entityId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        entityId,
        'entityId',
        'An id-shaped signal needs a real entity id.',
      );
    }
    if (isEmptyGuid(id)) {
      throw ArgumentError.value(
        entityId,
        'entityId',
        'The zero GUID is not an id. A signal with no id to send must be a '
            'free-text search (FeedSignal.searchedQuery).',
      );
    }
    return FeedSignal._(entityId: id, entity: entity, action: action);
  }

  /// A free-text search the customer submitted, which has no id at all.
  ///
  /// Throws [ArgumentError] on a blank query: the backend only treats a
  /// `searched` signal as query-shaped while the text is non-blank, so a
  /// blank one would fall through to its id-required branch and be dropped.
  factory FeedSignal.searchedQuery(String query) {
    final text = query.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(
        query,
        'query',
        'A free-text search signal needs the search text.',
      );
    }
    return FeedSignal._(
      entity: FeedSignalEntity.search,
      action: FeedSignalAction.searched,
      query: text,
    );
  }

  /// The id of the thing this signal is about, or null for a free-text
  /// search — the backend types it `Guid?` for exactly that case.
  final String? entityId;

  /// The raw search text, on a free-text `searched` signal only.
  final String? query;

  final FeedSignalEntity entity;
  final FeedSignalAction action;

  /// Whether this is the query-shaped free-text search signal.
  bool get isQueryShaped => query != null;

  Map<String, dynamic> toJson() => {
    if (entityId != null) 'entityId': entityId,
    'entityType': entity.wire,
    'action': action.wire,
    if (query != null) 'query': query,
  };
}

/// Whether [id] is the all-zero GUID in any of the spellings a client might
/// produce — the placeholder the backend refuses and no client may invent.
bool isEmptyGuid(String id) {
  final normalized = id.replaceAll('-', '').replaceAll(RegExp('[{}]'), '');
  return normalized.length == 32 && !normalized.contains(RegExp('[^0]'));
}
