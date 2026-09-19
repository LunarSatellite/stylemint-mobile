/// What actually happened to an order — `GET /v1/orders/{orderNumber}/events`.
///
/// This is a log, not a ladder. It holds exactly as many entries as there are
/// records, which for a young or abandoned order may be one. Nothing in here
/// is ever derived: no timestamp is computed from another, and an event that
/// has no record simply does not exist.
library;

/// Health of one source behind an [OrderEventHistory].
///
/// The distinction between [empty] and [unavailable] is the whole reason this
/// list is on the wire: one means "nothing happened", the other means "we
/// could not find out". A client that renders them the same way presents a
/// gap as fact.
enum OrderEventSourceStatus {
  /// Read, and it contributed events.
  ok,

  /// Read fine, it had nothing to say. A true "nothing happened here".
  empty,

  /// The read failed. Events it would have contributed are missing.
  unavailable,

  /// Read and contributed events, but its own integrity check failed. The
  /// entries are shown; their trustworthiness is flagged.
  unverified;

  /// Unknown wire values read as [unavailable]: a status this app does not
  /// understand is not a licence to present the history as complete.
  static OrderEventSourceStatus fromWire(String value) => switch (value) {
    'ok' => ok,
    'empty' => empty,
    'unverified' => unverified,
    'unavailable' => unavailable,
    _ => unavailable,
  };

  /// True when this source leaves the history less than fully trustworthy.
  bool get needsTelling =>
      this == unavailable || this == unverified;
}

class OrderEventSource {
  const OrderEventSource({required this.name, required this.status, this.note});

  /// Wire name, e.g. `custody_chain`.
  final String name;
  final OrderEventSourceStatus status;

  /// Short human explanation, present for `unavailable` and `unverified`.
  final String? note;
}

/// One thing that happened, with the time it was recorded as happening.
class OrderEvent {
  const OrderEvent({
    required this.sequence,
    required this.code,
    required this.statement,
    required this.occurredUtc,
    required this.source,
    this.subOrderId,
    this.vendorName,
    this.detail,
  });

  /// 1-based position after ordering by [occurredUtc]. Presentation aid only.
  final int sequence;

  /// Stable snake_case key, e.g. `handed_to_courier`.
  final String code;

  /// The one plain sentence the buyer reads. Rendered verbatim — the client
  /// does not rephrase, shorten or supplement it.
  final String statement;

  /// Straight off the record that proves the event. Null only when the wire
  /// value was missing or unparseable, in which case the stamp is omitted
  /// rather than guessed at.
  final DateTime? occurredUtc;

  /// Null for order-level events; set for per-vendor events.
  final String? subOrderId;

  /// Brand name when resolved; null when the vendor lookup found nothing.
  final String? vendorName;

  /// Which source proved it: `order`, `sub_order_history`,
  /// `cancellation_request`, `custody_chain`.
  final String source;

  /// Buyer-authored context, currently only their own cancel reason.
  final String? detail;

  /// Events that stop the journey rather than advance it.
  bool get isStop =>
      code == 'cancelled' ||
      code == 'returned' ||
      code == 'refund_failed' ||
      code == 'handling_problem';
}

class OrderEventHistory {
  const OrderEventHistory({
    required this.orderNumber,
    required this.orderState,
    required this.events,
    required this.sources,
    this.placedUtc,
  });

  final String orderNumber;

  /// Backend `OrderState` int. Bookkeeping — the customer-facing vocabulary
  /// is each event's [OrderEvent.statement].
  final int orderState;

  /// The order's own placement time, for the header only. Null when the
  /// backend did not give one; it is never computed from anything else.
  final DateTime? placedUtc;

  /// In the order the backend sent them (oldest first).
  final List<OrderEvent> events;

  final List<OrderEventSource> sources;

  /// Sources whose read failed. Their events are missing from [events], so
  /// the screen must say the history may be incomplete.
  List<OrderEventSource> get unavailableSources => sources
      .where((s) => s.status == OrderEventSourceStatus.unavailable)
      .toList(growable: false);

  /// Sources that contributed events but failed their integrity check.
  List<OrderEventSource> get unverifiedSources => sources
      .where((s) => s.status == OrderEventSourceStatus.unverified)
      .toList(growable: false);

  /// True when [source] is one whose entries must render flagged.
  bool isSourceUnverified(String source) => sources.any(
    (s) =>
        s.name == source && s.status == OrderEventSourceStatus.unverified,
  );

  /// True when every source was read and simply had nothing to add. Only then
  /// is an absence safe to present as "nothing happened".
  bool get isComplete => sources.every((s) => !s.status.needsTelling);
}
