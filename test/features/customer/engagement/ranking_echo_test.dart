import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/feed_provenance.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_queue_store.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/repositories/engagement_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/presentation/engagement_tracker.dart';

import '../reels/fake_reels_repository.dart';

/// Ranking-model training (lead360 PR #14): feed items and search responses
/// carry a `requestId` (and feed items a 0-based `position`), and the
/// interaction events echo them back — only when they are known.
class _Api extends ApiClient {
  _Api({this.searchBody}) : super(dio: Dio());

  final Map<String, dynamic>? searchBody;
  final List<Map<String, dynamic>> sent = [];

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    sent.addAll(((data as Map)['events'] as List).cast<Map<String, dynamic>>());
    return null;
  }

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => searchBody;

  @override
  Future<dynamic> authGet(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? data,
  }) async =>
      uri == CustomerSearchRemoteDataSource.aiSearchPath ? null : searchBody;
}

const _rid = '7b1d6a64-2f0e-4c55-9d7e-1a2b3c4d5e6f';

void main() {
  group('parsing', () {
    test('a feed item reads requestId and position', () {
      final p = FeedProvenance.fromJson(const {
        'slotKind': 'Personalized',
        'score': 0.9,
        'requestId': _rid,
        'position': 3,
      });
      expect(p.requestId, _rid);
      expect(p.position, 3);
      // Survives ranking across the page.
      final ranked = FeedProvenance.rankAll([p]).single;
      expect(ranked.requestId, _rid);
      expect(ranked.position, 3);
    });

    test('a feed item without them, or with junk, reads null', () {
      final absent = FeedProvenance.fromJson(const {'slotKind': 'Popular'});
      expect(absent.requestId, isNull);
      expect(absent.position, isNull);
      final junk = FeedProvenance.fromJson(const {
        'requestId': '  ',
        'position': -1,
      });
      expect(junk.requestId, isNull);
      expect(junk.position, isNull);
      expect(FeedProvenance.fromJson(const {'position': 0}).position, 0);
      expect(FeedProvenance.fromJson(const {'position': 1.5}).position, isNull);
    });

    test('a search response reads its top-level requestId', () async {
      final ds = CustomerSearchRemoteDataSource(
        apiClient: _Api(
          searchBody: {
            'products': <dynamic>[],
            'aiApplied': false,
            'requestId': _rid,
          },
        ),
      );
      expect((await ds.search('dress')).requestId, _rid);
    });

    test('a search response without a requestId reads null', () async {
      final ds = CustomerSearchRemoteDataSource(
        apiClient: _Api(
          searchBody: {'products': <dynamic>[], 'aiApplied': false},
        ),
      );
      expect((await ds.search('dress')).requestId, isNull);
    });
  });

  group('event payload', () {
    final at = DateTime.utc(2026, 10, 28);

    test('includes requestId and position when known, and round-trips', () {
      final json = EngagementEvent(
        clientEventId: 'e-1',
        kind: EngagementKind.view,
        reelId: 'r-1',
        occurredUtc: at,
        surface: EngagementSurface.feed,
        requestId: _rid,
        position: 0,
      ).toJson();
      expect(json['requestId'], _rid);
      expect(json['position'], 0);
      final back = EngagementEvent.fromJson(json)!;
      expect(back.requestId, _rid);
      expect(back.position, 0);
    });

    test('omits both keys when unknown', () {
      final json = EngagementEvent(
        clientEventId: 'e-1',
        kind: EngagementKind.view,
        reelId: 'r-1',
        occurredUtc: at,
      ).toJson();
      expect(json.containsKey('requestId'), isFalse);
      expect(json.containsKey('position'), isFalse);
    });
  });

  group('tracker', () {
    late _Api api;
    late EngagementTracker tracker;
    var ids = 0;

    setUp(() {
      api = _Api();
      tracker = EngagementTracker(
        repository: EngagementRepositoryImpl(
          remoteDataSource: EngagementRemoteDataSource(apiClient: api),
          store: InMemoryEngagementQueueStore(),
        ),
        allowed: () async => true,
        owner: () => 'acct-1',
        newId: () => 'e-${++ids}',
        clock: () => DateTime.utc(2026, 10, 28, 10),
        flushInterval: const Duration(hours: 1),
      );
      addTearDown(tracker.dispose);
    });

    Future<List<Map<String, dynamic>>> sent() async {
      await pumpEventQueue();
      await tracker.flush();
      return api.sent;
    }

    test('a feed reel echoes its requestId and position on the view', () async {
      final reel = fakeReel('r-1').copyWith(
        provenance: const FeedProvenance(
          kind: FeedSlotKind.personalized,
          requestId: _rid,
          position: 4,
        ),
      );
      tracker.reelLeft(reel, const Duration(seconds: 5));
      final view = (await sent()).single;
      expect(view['surface'], 'feed');
      expect(view['requestId'], _rid);
      expect(view['position'], 4);
    });

    test('a reel without provenance sends neither field', () async {
      tracker.reelLeft(fakeReel('r-1'), const Duration(seconds: 5));
      final view = (await sent()).single;
      expect(view.containsKey('requestId'), isFalse);
      expect(view.containsKey('position'), isFalse);
    });

    test('a feed tag tap carries the echo to the product view', () async {
      tracker
        ..tagTapped(
          reelId: 'r-1',
          productId: 'p-1',
          requestId: _rid,
          position: 2,
        )
        ..productViewed('p-1');
      final events = await sent();
      expect(events, hasLength(2));
      for (final e in events) {
        expect(e['requestId'], _rid);
        expect(e['position'], 2);
      }
      expect(events.last['surface'], 'product');
    });

    test(
      'an opened search hit makes the product view a search event',
      () async {
        tracker
          ..searchResultOpened(productId: 'p-9', requestId: _rid, position: 0)
          ..productViewed('p-9')
          ..productViewed('p-other');
        final events = await sent();
        expect(events.first['surface'], 'search');
        expect(events.first['requestId'], _rid);
        expect(events.first['position'], 0);
        expect(events.last['surface'], 'product');
        expect(events.last.containsKey('requestId'), isFalse);
        expect(events.last.containsKey('position'), isFalse);
      },
    );

    test(
      'a search hit without a requestId still sends its position only',
      () async {
        tracker
          ..searchResultOpened(productId: 'p-9', position: 5)
          ..productViewed('p-9');
        final e = (await sent()).single;
        expect(e['surface'], 'search');
        expect(e.containsKey('requestId'), isFalse);
        expect(e['position'], 5);
      },
    );
  });
}
