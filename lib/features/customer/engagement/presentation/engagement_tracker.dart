import 'dart:async';
import 'dart:math' as math;

import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/repositories/engagement_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/reel_view_recorder.dart';

/// Records what a signed-in customer does with reels and products and sends
/// it, in batches, to `POST v1/customer/feed/interactions` (AI features
/// contract v1.0 §2.1) — the behaviour the personal feed is ranked from.
///
/// ## Consent first
///
/// Every event asks [allowed] — the same gate as the adaptive storefront:
/// signed in, not paused in the Memory Vault, storefront personalisation
/// permitted. A "no" records nothing. A queue that was waiting when the
/// answer turned to "no" is thrown away, not sent later.
///
/// ## Batching and offline
///
/// Events queue in memory and on the device (so a dead network, flight mode
/// or a killed app does not lose them) and go out every [flushInterval],
/// when [flushAt] are waiting, and when the app goes to the background.
/// Each event carries a `clientEventId` minted when it happened; a failed
/// batch (network, timeout, `5xx`) is resent later with the same ids, which
/// the server stores idempotently. A `4xx` drops the batch — sending it
/// again would be refused again.
///
/// ## A server without the endpoint
///
/// A `404` means the batch endpoint is not deployed. The tracker then stops
/// for the rest of the run and drops what it held; the older per-signal path
/// (`FeedSignalRecorder`) carries on exactly as before.
///
/// ## Whose events
///
/// The queue belongs to the account it was recorded for ([owner]). After a
/// sign-out or an account switch it is discarded, never sent under another
/// account's token.
///
/// Every public method is fire-and-forget: it never throws, never blocks a
/// tap and never shows an error.
class EngagementTracker {
  EngagementTracker({
    required EngagementRepository repository,
    required Future<bool> Function() allowed,
    required String? Function() owner,
    required String Function() newId,
    DateTime Function() clock = _wallClock,
    this.flushInterval = const Duration(seconds: 10),
    this.flushAt = 20,
    this.maxQueued = 500,
    this.maxAge = const Duration(days: 7),
    this.attributionWindow = const Duration(minutes: 30),
    this.maxBackoff = const Duration(minutes: 5),
  }) : _repository = repository,
       _allowed = allowed,
       _owner = owner,
       _newId = newId,
       _clock = clock;

  static DateTime _wallClock() => DateTime.now();

  final EngagementRepository _repository;
  final Future<bool> Function() _allowed;
  final String? Function() _owner;
  final String Function() _newId;
  final DateTime Function() _clock;

  final Duration flushInterval;
  final int flushAt;
  final int maxQueued;
  final Duration maxAge;

  /// How long after a tag tap a product page or cart add still counts as
  /// coming from that reel.
  final Duration attributionWindow;
  final Duration maxBackoff;

  final List<EngagementEvent> _queue = [];

  /// The account [_queue] belongs to; null before the first event.
  String? _queueOwner;
  Future<void>? _restoring;
  bool _flushing = false;
  bool _disposed = false;

  /// True once the server answered `404`: nothing more is collected.
  bool _endpointMissing = false;
  int _failures = 0;
  Timer? _timer;

  /// Where each product was last opened from, and when: the reel of a tag
  /// tap, or a search result. Carries the ranking echo (`requestId`,
  /// `position`) of the item it was opened from, when known.
  final Map<String, _OpenedFrom> _tappedFrom = {};

  /// Whether the batch endpoint answered `404` this run.
  bool get endpointMissing => _endpointMissing;

  /// Events waiting to be sent (for tests and diagnostics).
  List<EngagementEvent> get pending => List.unmodifiable(_queue);

  // ── What happened ─────────────────────────────────────────────────────────

  /// A reel left the screen after [dwell]. Records a `skip` inside the skip
  /// threshold, otherwise a `view` with its dwell and watch fraction — plus
  /// a `complete` when it played to the end.
  ///
  /// Returns the `clientEventId` of the skip or view, so the older
  /// per-signal call for the same exposure can carry it and the server can
  /// tell the two are one event. Null when there is no reel to speak of.
  String? reelLeft(
    Reel reel,
    Duration dwell, {
    EngagementSurface surface = EngagementSurface.feed,
  }) {
    final reelId = reel.id.trim();
    if (reelId.isEmpty || dwell.isNegative) return null;
    final requestId = reel.provenance?.requestId;
    final position = reel.provenance?.position;
    final id = _newId();
    if (dwell < reelViewThreshold) {
      _record(
        EngagementEvent(
          clientEventId: id,
          kind: EngagementKind.skip,
          reelId: reelId,
          occurredUtc: _now(),
          surface: surface,
          requestId: requestId,
          position: position,
        ),
      );
      return id;
    }
    _record(
      EngagementEvent(
        clientEventId: id,
        kind: EngagementKind.view,
        reelId: reelId,
        dwellMs: math.min(dwell.inMilliseconds, EngagementEvent.maxDwellMs),
        watchFraction: reelWatchFraction(dwell, reel.durationSeconds),
        occurredUtc: _now(),
        surface: surface,
        requestId: requestId,
        position: position,
      ),
    );
    if (reelViewCompleted(dwell, reel.durationSeconds)) {
      _record(
        EngagementEvent(
          clientEventId: _newId(),
          kind: EngagementKind.complete,
          reelId: reelId,
          occurredUtc: _now(),
          surface: surface,
          requestId: requestId,
          position: position,
        ),
      );
    }
    return id;
  }

  /// The viewer saved or unsaved a reel (after the server agreed).
  ///
  /// [requestId] and [position] are the reel's personal-feed ranking echo
  /// (`Reel.provenance`), when it came from the feed; omitted otherwise.
  void saveChanged(
    String reelId, {
    required bool saved,
    EngagementSurface? surface,
    String? requestId,
    int? position,
  }) => _reelEvent(
    saved ? EngagementKind.save : EngagementKind.unsave,
    reelId,
    surface,
    requestId,
    position,
  );

  /// The share sheet completed, or the link was copied.
  void shared(
    String reelId, {
    EngagementSurface? surface,
    String? requestId,
    int? position,
  }) => _reelEvent(EngagementKind.share, reelId, surface, requestId, position);

  /// A tagged-product card on a reel was tapped. Remembers the reel, so the
  /// product page and a cart add that follow are attributed to it.
  void tagTapped({
    required String reelId,
    required String productId,
    EngagementSurface? surface,
    String? requestId,
    int? position,
  }) {
    final reel = reelId.trim();
    final product = productId.trim();
    if (reel.isEmpty || product.isEmpty) return;
    _tappedFrom[product] = _OpenedFrom(
      reelId: reel,
      at: _now(),
      requestId: requestId,
      position: position,
    );
    _record(
      EngagementEvent(
        clientEventId: _newId(),
        kind: EngagementKind.tagTap,
        reelId: reel,
        productId: product,
        occurredUtc: _now(),
        surface: surface,
        requestId: requestId,
        position: position,
      ),
    );
  }

  /// A product search result was opened. Records nothing itself: the
  /// product page that follows records the `product_view`, which then
  /// carries `surface: search`, the search response's [requestId] and the
  /// result's 0-based [position] as displayed. A later cart add of the same
  /// product within [attributionWindow] carries them too.
  void searchResultOpened({
    required String productId,
    String? requestId,
    int? position,
  }) {
    final product = productId.trim();
    if (product.isEmpty) return;
    _tappedFrom[product] = _OpenedFrom(
      at: _now(),
      surface: EngagementSurface.search,
      requestId: requestId,
      position: position,
    );
  }

  /// A product page was opened. [viaReelId] when the caller knows the reel;
  /// otherwise the reel of a recent tag tap on this product, if any.
  ///
  /// Returns the event's `clientEventId` (see [reelLeft]), or null.
  String? productViewed(String productId, {String? viaReelId}) =>
      _productEvent(EngagementKind.productView, productId, viaReelId, null);

  /// An item was added to the cart. Attributed like [productViewed].
  void addedToCart(
    String productId, {
    String? viaReelId,
    EngagementSurface? surface,
  }) => _productEvent(EngagementKind.addToCart, productId, viaReelId, surface);

  // ── Sending ───────────────────────────────────────────────────────────────

  /// Sends what is waiting, batch by batch, until the queue is empty or a
  /// batch must wait for a retry. Never throws.
  Future<void> flush() async {
    if (_flushing || _disposed) return;
    _timer?.cancel();
    _timer = null;
    _flushing = true;
    try {
      final who = _owner();
      if (who == null || _endpointMissing) {
        await _discard();
        return;
      }
      await _adopt(who);
      if (_queue.isEmpty) return;
      if (!await _allowedSafely()) {
        await _discard();
        return;
      }
      while (_queue.isNotEmpty && !_disposed) {
        final batch = _queue
            .take(EngagementRepository.maxBatch)
            .toList(growable: false);
        final outcome = await _sendSafely(batch);
        switch (outcome) {
          case EngagementSendOutcome.accepted:
          case EngagementSendOutcome.rejected:
            final sent = {for (final event in batch) event.clientEventId};
            _queue.removeWhere((event) => sent.contains(event.clientEventId));
            _failures = 0;
            await _persist();
          case EngagementSendOutcome.notDeployed:
            _endpointMissing = true;
            await _discard();
            return;
          case EngagementSendOutcome.retry:
            _failures++;
            await _persist();
            _schedule(_backoff());
            return;
        }
      }
    } on Object catch (_) {
      // Best effort only.
    } finally {
      _flushing = false;
    }
  }

  /// Stops the timer. Pending events stay on the device for the next run.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  DateTime _now() => _clock().toUtc();

  void _reelEvent(
    EngagementKind kind,
    String reelId,
    EngagementSurface? surface,
    String? requestId,
    int? position,
  ) {
    final reel = reelId.trim();
    if (reel.isEmpty) return;
    _record(
      EngagementEvent(
        clientEventId: _newId(),
        kind: kind,
        reelId: reel,
        occurredUtc: _now(),
        surface: surface,
        requestId: requestId,
        position: position,
      ),
    );
  }

  String? _productEvent(
    EngagementKind kind,
    String productId,
    String? viaReelId,
    EngagementSurface? surface,
  ) {
    final product = productId.trim();
    if (product.isEmpty) return null;
    final via = viaReelId?.trim();
    final hasVia = via != null && via.isNotEmpty;
    final from = _attributed(product);
    // The opening's ranking echo only applies when this event is about the
    // same opening: no explicit reel, or the very reel it was tapped from.
    final echo = from != null && (!hasVia || from.reelId == via) ? from : null;
    final id = _newId();
    _record(
      EngagementEvent(
        clientEventId: id,
        kind: kind,
        productId: product,
        reelId: hasVia ? via : from?.reelId,
        occurredUtc: _now(),
        surface: surface ?? echo?.surface ?? EngagementSurface.product,
        requestId: echo?.requestId,
        position: echo?.position,
      ),
    );
    return id;
  }

  /// Where [productId] was opened from within [attributionWindow].
  _OpenedFrom? _attributed(String productId) {
    final tap = _tappedFrom[productId];
    if (tap == null) return null;
    if (_now().difference(tap.at) > attributionWindow) {
      _tappedFrom.remove(productId);
      return null;
    }
    return tap;
  }

  void _record(EngagementEvent event) {
    if (_endpointMissing || _disposed) return;
    unawaited(_enqueue(event));
  }

  Future<void> _enqueue(EngagementEvent event) async {
    try {
      final who = _owner();
      if (who == null) return;
      if (!await _allowedSafely()) return;
      if (_endpointMissing || _disposed) return;
      await _adopt(who);
      _queue.add(event);
      if (_queue.length > maxQueued) {
        _queue.removeRange(0, _queue.length - maxQueued);
      }
      await _persist();
      if (_queue.length >= flushAt) {
        unawaited(flush());
      } else if (_failures == 0) {
        _schedule(flushInterval);
      }
    } on Object catch (_) {
      // Best effort only.
    }
  }

  /// Makes [who] the queue's owner: restores what an earlier run left for
  /// them, and drops anything recorded for someone else.
  Future<void> _adopt(String who) async {
    await (_restoring ??= _restore(who));
    if (_queueOwner != who) {
      if (_queueOwner != null) _queue.clear();
      _queueOwner = who;
      _tappedFrom.clear();
    }
  }

  /// Once per run: takes back what an earlier run left unsent for [who],
  /// minus anything older than [maxAge]; anyone else's leftovers are
  /// deleted unsent.
  Future<void> _restore(String who) async {
    final saved = await _repository.readPending();
    if (saved == null) return;
    if (saved.owner != who) {
      await _repository.clearPending();
      return;
    }
    final oldest = _now().subtract(maxAge);
    final known = {for (final event in _queue) event.clientEventId};
    _queue.insertAll(0, [
      for (final event in saved.events)
        if (event.occurredUtc.isAfter(oldest) &&
            !known.contains(event.clientEventId))
          event,
    ]);
    _queueOwner = who;
    if (_queue.isNotEmpty) _schedule(flushInterval);
  }

  Future<void> _persist() async {
    final who = _queueOwner;
    if (who == null) return;
    await _repository.writePending(
      PendingEngagement(owner: who, events: List.of(_queue)),
    );
  }

  Future<void> _discard() async {
    _queue.clear();
    _tappedFrom.clear();
    await _repository.clearPending();
  }

  Future<bool> _allowedSafely() async {
    try {
      return await _allowed();
    } on Object catch (_) {
      return false;
    }
  }

  Future<EngagementSendOutcome> _sendSafely(List<EngagementEvent> batch) async {
    try {
      return await _repository.send(batch);
    } on Object catch (_) {
      return EngagementSendOutcome.retry;
    }
  }

  Duration _backoff() {
    final factor = 1 << math.min(_failures - 1, 10);
    final wait = flushInterval * factor;
    return wait > maxBackoff ? maxBackoff : wait;
  }

  void _schedule(Duration after) {
    if (_disposed || _timer != null) return;
    _timer = Timer(after, () {
      _timer = null;
      unawaited(flush());
    });
  }
}

/// One opening of a product page: from a reel's tag, or from a search hit.
class _OpenedFrom {
  const _OpenedFrom({
    required this.at,
    this.reelId,
    this.surface,
    this.requestId,
    this.position,
  });

  final DateTime at;
  final String? reelId;

  /// The surface the product events inherit; null keeps the default.
  final EngagementSurface? surface;
  final String? requestId;
  final int? position;
}
