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
class FeedSignal {
  const FeedSignal({
    required this.entityId,
    required this.entity,
    required this.action,
  });

  /// The backend types this as a `Guid`, so a signal without a real id is
  /// never sent.
  final String entityId;
  final FeedSignalEntity entity;
  final FeedSignalAction action;

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'entityType': entity.wire,
    'action': action.wire,
  };
}
