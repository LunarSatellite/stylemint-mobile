import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_queue_store.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/repositories/engagement_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/presentation/engagement_tracker.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

import '../reels/fake_reels_repository.dart';

/// AI features contract v1.0 §2.1: engagement goes to
/// `POST v1/customer/feed/interactions` in batches, behind the consent gate,
/// survives being offline, is retried idempotently, and stops quietly on a
/// server without the endpoint.
class _Api extends ApiClient {
  _Api() : super(dio: Dio());

  /// What each successive POST answers: null = 204, else a status code, or
  /// -1 for a connection failure (no response at all).
  final List<int?> answers = [];
  final List<List<Map<String, dynamic>>> batches = [];

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    expect(uri, EngagementRemoteDataSource.batchPath);
    final events = ((data as Map)['events'] as List)
        .cast<Map<String, dynamic>>();
    batches.add(events);
    final answer = answers.isEmpty ? null : answers.removeAt(0);
    if (answer == null) return null;
    final request = RequestOptions(path: uri);
    throw DioException(
      requestOptions: request,
      response: answer < 0
          ? null
          : Response<dynamic>(requestOptions: request, statusCode: answer),
    );
  }
}

class _Harness {
  _Harness({this.consent = true, String? owner = 'acct-1'}) : _owner = owner {
    tracker = build();
    addTearDown(tracker.dispose);
  }

  final api = _Api();
  final store = InMemoryEngagementQueueStore();
  bool consent;
  String? _owner;
  var _ids = 0;
  DateTime now = DateTime.utc(2026, 10, 25, 10);
  late EngagementTracker tracker;

  set owner(String? value) => _owner = value;

  EngagementTracker build() => EngagementTracker(
    repository: EngagementRepositoryImpl(
      remoteDataSource: EngagementRemoteDataSource(apiClient: api),
      store: store,
    ),
    allowed: () async => consent,
    owner: () => _owner,
    newId: () => 'e-${++_ids}',
    clock: () => now,
    // Long enough that only explicit flushes send in these tests.
    flushInterval: const Duration(hours: 1),
  );

  List<Map<String, dynamic>> get sent => [
    for (final batch in api.batches) ...batch,
  ];
}

Reel _reel(String id, {int? seconds}) =>
    fakeReel(id).copyWith(durationSeconds: seconds);

void main() {
  test('a watched reel is a view with dwell and watch fraction, plus a '
      'complete when it played to the end', () async {
    final h = _Harness();
    final id = h.tracker.reelLeft(
      _reel('r-1', seconds: 10),
      const Duration(seconds: 9, milliseconds: 500),
    );
    await pumpEventQueue();
    await h.tracker.flush();

    expect(id, 'e-1');
    expect(h.sent, hasLength(2));
    expect(h.sent[0], {
      'clientEventId': 'e-1',
      'kind': 'view',
      'reelId': 'r-1',
      'dwellMs': 9500,
      'watchFraction': 0.95,
      'occurredUtc': '2026-10-25T10:00:00.000Z',
      'surface': 'feed',
    });
    expect(h.sent[1]['kind'], 'complete');
    expect(h.sent[1]['clientEventId'], 'e-2');
  });

  test('a swipe straight past is a skip, not a view', () async {
    final h = _Harness();
    h.tracker.reelLeft(_reel('r-1'), const Duration(milliseconds: 600));
    await pumpEventQueue();
    await h.tracker.flush();

    expect(h.sent.single['kind'], 'skip');
    expect(h.sent.single.containsKey('dwellMs'), isFalse);
  });

  test('an unknown length: a view with no watch fraction and no complete', () async {
    final h = _Harness();
    h.tracker.reelLeft(_reel('r-1'), const Duration(seconds: 40));
    await pumpEventQueue();
    await h.tracker.flush();

    expect(h.sent.single['kind'], 'view');
    expect(h.sent.single.containsKey('watchFraction'), isFalse);
  });

  test('the queue flushes by itself once 20 events wait', () async {
    final h = _Harness();
    for (var i = 0; i < 20; i++) {
      h.tracker.shared('r-$i');
    }
    await pumpEventQueue();

    expect(h.api.batches, hasLength(1));
    expect(h.api.batches.single, hasLength(20));
    expect(h.store.pending, isNull, reason: 'nothing left to keep');
  });

  test('no consent, nothing collected; consent withdrawn, queue dropped', () async {
    final refused = _Harness(consent: false);
    refused.tracker.shared('r-1');
    await pumpEventQueue();
    expect(refused.tracker.pending, isEmpty);
    expect(refused.store.pending, isNull);

    final h = _Harness();
    h.tracker.shared('r-1');
    await pumpEventQueue();
    h.consent = false;
    await h.tracker.flush();
    expect(h.api.batches, isEmpty);
    expect(h.tracker.pending, isEmpty);
    expect(h.store.pending, isNull);
  });

  test('a guest records nothing', () async {
    final h = _Harness(owner: null);
    h.tracker.tagTapped(reelId: 'r-1', productId: 'p-1');
    await pumpEventQueue();
    expect(h.tracker.pending, isEmpty);
  });

  test('offline: kept on the device and resent later with the same ids', () async {
    final h = _Harness();
    h.api.answers.addAll([-1, 503]);
    h.tracker.saveChanged('r-1', saved: true);
    await pumpEventQueue();

    await h.tracker.flush(); // connection failure
    await h.tracker.flush(); // 503
    expect(h.tracker.pending, hasLength(1));
    expect(h.store.pending?.events.single.clientEventId, 'e-1');

    await h.tracker.flush(); // 204
    expect(h.api.batches, hasLength(3));
    expect({for (final b in h.api.batches) b.single['clientEventId']}, {'e-1'});
    expect(h.tracker.pending, isEmpty);
    expect(h.store.pending, isNull);
  });

  test('a 400 drops the batch instead of resending it forever', () async {
    final h = _Harness();
    h.api.answers.add(400);
    h.tracker.shared('r-1');
    await pumpEventQueue();
    await h.tracker.flush();

    expect(h.tracker.pending, isEmpty);
    await h.tracker.flush();
    expect(h.api.batches, hasLength(1));
  });

  test('a 404 (not deployed) stops batching for the run, quietly', () async {
    final h = _Harness();
    h.api.answers.add(404);
    h.tracker.shared('r-1');
    await pumpEventQueue();
    await h.tracker.flush();

    expect(h.tracker.endpointMissing, isTrue);
    expect(h.tracker.pending, isEmpty);
    expect(h.store.pending, isNull);

    h.tracker.shared('r-2');
    await pumpEventQueue();
    await h.tracker.flush();
    expect(h.api.batches, hasLength(1), reason: 'nothing more is sent');
  });

  test('an earlier run\'s queue is sent for the same account only', () async {
    final h = _Harness();
    h.store.pending = PendingEngagement(
      owner: 'acct-1',
      events: [
        EngagementEvent(
          clientEventId: 'old-1',
          kind: EngagementKind.share,
          reelId: 'r-9',
          occurredUtc: h.now.subtract(const Duration(hours: 2)),
        ),
        EngagementEvent(
          clientEventId: 'stale',
          kind: EngagementKind.share,
          reelId: 'r-8',
          occurredUtc: h.now.subtract(const Duration(days: 8)),
        ),
      ],
    );
    await h.tracker.flush();
    expect([for (final e in h.sent) e['clientEventId']], ['old-1']);

    final other = _Harness(owner: 'acct-2');
    other.store.pending = PendingEngagement(
      owner: 'acct-1',
      events: [
        EngagementEvent(
          clientEventId: 'not-yours',
          kind: EngagementKind.share,
          reelId: 'r-9',
          occurredUtc: other.now,
        ),
      ],
    );
    await other.tracker.flush();
    expect(other.api.batches, isEmpty);
    expect(other.store.pending, isNull, reason: 'deleted unsent');
  });

  test('signing out discards the queue', () async {
    final h = _Harness();
    h.tracker.shared('r-1');
    await pumpEventQueue();
    h.owner = null;
    await h.tracker.flush();

    expect(h.api.batches, isEmpty);
    expect(h.store.pending, isNull);
  });

  test('a product page and a cart add after a tag tap are attributed to the '
      'reel; after the window they are not', () async {
    final h = _Harness();
    h.tracker.tagTapped(reelId: 'r-1', productId: 'p-1');
    final viewId = h.tracker.productViewed('p-1');
    h.tracker.addedToCart('p-1');
    h.now = h.now.add(const Duration(hours: 1));
    h.tracker.addedToCart('p-1');
    h.tracker.addedToCart('p-2', viaReelId: 'r-7');
    await pumpEventQueue();
    await h.tracker.flush();

    expect(viewId, 'e-2');
    final rows = h.sent;
    expect(rows[0], containsPair('kind', 'tag_tap'));
    expect(rows[0], containsPair('productId', 'p-1'));
    expect(rows[1], containsPair('kind', 'product_view'));
    expect(rows[1], containsPair('reelId', 'r-1'));
    expect(rows[2], containsPair('kind', 'add_to_cart'));
    expect(rows[2], containsPair('reelId', 'r-1'));
    expect(rows[3].containsKey('reelId'), isFalse, reason: 'window passed');
    expect(rows[4], containsPair('reelId', 'r-7'));
  });

  test('likes and purchases are not engagement kinds: the server records '
      'them itself', () {
    final wires = {for (final kind in EngagementKind.values) kind.wire};
    expect(wires, isNot(contains('like')));
    expect(wires, isNot(contains('purchase')));
  });

  test('the per-signal call carries the same id and the dwell', () {
    final signal = FeedSignal.forEntity(
      entityId: 'r-1',
      entity: FeedSignalEntity.reel,
      action: FeedSignalAction.watched,
      clientEventId: 'e-1',
      dwellMs: 9000,
    );
    expect(signal.toJson(), {
      'entityId': 'r-1',
      'entityType': 'reel',
      'action': 'watched',
      'clientEventId': 'e-1',
      'dwellMs': 9000,
    });
  });

  test('status codes map to what happens to the batch', () {
    expect(
      EngagementRemoteDataSource.outcomeFor(404),
      EngagementSendOutcome.notDeployed,
    );
    expect(
      EngagementRemoteDataSource.outcomeFor(429),
      EngagementSendOutcome.retry,
    );
    expect(
      EngagementRemoteDataSource.outcomeFor(500),
      EngagementSendOutcome.retry,
    );
    expect(
      EngagementRemoteDataSource.outcomeFor(401),
      EngagementSendOutcome.rejected,
    );
    expect(
      EngagementRemoteDataSource.outcomeFor(null),
      EngagementSendOutcome.retry,
    );
  });

  test('a persisted event survives the JSON round trip', () {
    final event = EngagementEvent(
      clientEventId: 'e-1',
      kind: EngagementKind.view,
      reelId: 'r-1',
      dwellMs: 700000,
      watchFraction: 1.4,
      occurredUtc: DateTime.utc(2026, 10, 25),
      surface: EngagementSurface.reelDetail,
    );
    final json = event.toJson();
    expect(json['dwellMs'], EngagementEvent.maxDwellMs, reason: 'clamped');
    expect(json['watchFraction'], 1.0, reason: 'clamped');
    final back = EngagementEvent.fromJson(json)!;
    expect(back.kind, EngagementKind.view);
    expect(back.surface, EngagementSurface.reelDetail);
    expect(EngagementEvent.fromJson({'kind': 'view'}), isNull);
  });
}
