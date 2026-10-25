import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/shared/providers.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/models/reel_journey_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_journey.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/journey/journey_indicator.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/journey/journey_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/journey/journey_step_pager.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reel_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reels_pager.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import '../../../ai_rails/fake_ai_rails_repository.dart';

/// An Instagram reel with no media URL: it shows its poster, so no video or
/// WebView platform is needed.
Reel _reel(String id, {ReelJourney? journey}) => Reel(
  id: id,
  sourceUrl: 'https://www.instagram.com/reel/$id/',
  thumbnailUrl: '',
  creatorId: 'creator-$id',
  creatorName: 'Creator $id',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: const [],
  likeCount: 0,
  commentCount: 0,
  shareCount: 0,
  createdAt: DateTime(2026, 10, 23),
  journey: journey,
);

const _journeyId = '7b0c0000-0000-4000-8000-000000000001';

ReelJourney _journey({int at = 0, String? title = 'Pokhara weekend'}) =>
    ReelJourney(
      journeyId: _journeyId,
      title: title,
      city: 'Pokhara',
      stepIndex: 0,
      steps: const [
        ReelJourneyStep(
          stepId: 's-a',
          index: 0,
          vendorAccountId: 'v-a',
          vendorName: 'Greenline Tours',
          reelId: 'a',
        ),
        ReelJourneyStep(
          stepId: 's-b',
          index: 1,
          vendorAccountId: 'v-b',
          vendorName: 'Hotel Barahi',
          reelId: 'b',
        ),
        ReelJourneyStep(
          stepId: 's-c',
          index: 2,
          vendorAccountId: 'v-c',
          vendorName: 'Sunrise Paragliding',
          reelId: 'c',
        ),
      ],
    ).atStep(at);

Map<String, Reel> _stepReels() => {
  for (final (i, id) in ['a', 'b', 'c'].indexed)
    id: _reel(id, journey: _journey(at: i)),
};

class _MockCartRepository extends Mock implements CartRepository {}

class _FakeFollowApi implements FollowApi {
  @override
  Future<void> follow(String followeeAccountId) async {}

  @override
  Future<void> unfollow(String followeeAccountId) async {}

  @override
  Future<List<String>> followingIds({int pageSize = 200}) async =>
      const <String>[];

  @override
  Future<FollowStats> stats(String accountId) => throw UnimplementedError();
}

const _zero = Money(amount: 0, currency: 'NPR');

const _emptyCart = Cart(
  id: 'cart-1',
  items: [],
  subtotal: _zero,
  shippingTotal: _zero,
  taxTotal: _zero,
  total: _zero,
);

/// What every reel page's rail reads: an empty cart and nobody followed.
List<Override> _railOverrides() {
  final cart = _MockCartRepository();
  when(() => cart.getCart()).thenAnswer((_) async => right(_emptyCart));
  return [
    cartRepositoryProvider.overrideWithValue(cart),
    followApiProvider.overrideWithValue(_FakeFollowApi()),
    aiRailsRepositoryProvider.overrideWithValue(FakeAiRailsRepository()),
  ];
}

class _FakeReelsRepository implements ReelsRepository {
  _FakeReelsRepository(this.detail);

  final Reel detail;

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async =>
      right(detail);

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getRelatedReels(
    String reelId, {
    int limit = 10,
    String? cursor,
  }) async => right(const ReelsFeedPage(reels: [], nextCursor: null));

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getReelsFeed({
    int limit = 20,
    String? cursor,
  }) async => right(const ReelsFeedPage(reels: [], nextCursor: null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _JsonApiClient extends ApiClient {
  _JsonApiClient(this.body) : super(dio: Dio());

  final Map<String, dynamic> body;
  String? lastUri;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastUri = uri;
    return body;
  }
}

void main() {
  setUp(() {
    ReelsPager.debugHostEmbedPlayers = false;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => ReelsPager.debugHostEmbedPlayers = true);

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  late List<(String, Duration)> dwells;
  late DateTime now;

  Future<void> pumpFeed(WidgetTester tester, List<Reel> reels) async {
    phone(tester);
    dwells = [];
    now = DateTime(2026, 10, 23, 12);
    final controller = ReelsPagerController();
    addTearDown(controller.dispose);
    final steps = _stepReels();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._railOverrides(),
          journeyStepReelProvider.overrideWith(
            (ref, key) async => steps[key.reelId],
          ),
        ],
        child: MaterialApp(
          home: ReelsPager(
            controller: controller,
            reels: reels,
            clock: () => now,
            onReelDwell: (reel, dwell) => dwells.add((reel.id, dwell)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  String activeReelId(WidgetTester tester) {
    final active = tester
        .widgetList<ReelCard>(find.byType(ReelCard, skipOffstage: false))
        .where((card) => card.isActive)
        .map((card) => card.reel.id)
        .toList();
    expect(active, hasLength(1), reason: 'exactly one reel plays');
    return active.single;
  }

  Finder stepPager() => find.byKey(JourneyStepPager.pagerKey).first;

  group('feed', () {
    testWidgets('a reel without a journey is the plain reel page it always was', (
      tester,
    ) async {
      await pumpFeed(tester, [_reel('p1'), _reel('p2')]);

      expect(find.byType(JourneyStepPager), findsNothing);
      expect(find.byType(JourneyIndicator), findsNothing);
      expect(activeReelId(tester), 'p1');

      // Sideways does nothing to a plain reel; up still moves the feed.
      await tester.drag(find.byType(ReelCard).first, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'p1');
      await tester.drag(find.byType(ReelCard).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'p2');
    });

    testWidgets('swiping towards the next step opens it, and back returns', (
      tester,
    ) async {
      await pumpFeed(tester, [_reel('a', journey: _journey()), _reel('p2')]);

      expect(activeReelId(tester), 'a');
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Next: Greenline Tours'), findsNothing);
      expect(find.text('Next: Hotel Barahi'), findsOneWidget);

      // Next: the finger moves right-to-left, the next business slides in
      // from the right.
      await tester.drag(stepPager(), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'b');
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Next: Sunrise Paragliding'), findsOneWidget);

      await tester.drag(stepPager(), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'c');
      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.byKey(JourneyIndicator.nextKey), findsNothing);

      // Back, left-to-right.
      await tester.drag(stepPager(), const Offset(300, 0));
      await tester.pumpAndSettle();
      await tester.drag(stepPager(), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'a');
      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets('up and down still move the feed from a journey reel, and '
        'each step watched counts as its own reel', (tester) async {
      await pumpFeed(tester, [_reel('a', journey: _journey()), _reel('p2')]);

      now = now.add(const Duration(seconds: 4));
      await tester.drag(stepPager(), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'b');
      expect(dwells, [('a', const Duration(seconds: 4))]);

      now = now.add(const Duration(seconds: 6));
      await tester.drag(stepPager(), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'p2');
      expect(dwells.last, ('b', const Duration(seconds: 6)));

      // Coming back up finds the page still on the step it was left on.
      await tester.drag(find.byType(ReelsPager), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'b');
      expect(find.text('Step 2 of 3'), findsOneWidget);
    });

    testWidgets('tapping the next business moves to its step', (tester) async {
      await pumpFeed(tester, [_reel('a', journey: _journey())]);

      await tester.tap(find.byKey(JourneyIndicator.nextKey));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'b');
    });

    testWidgets('no title: the journey is named after its first business', (
      tester,
    ) async {
      await pumpFeed(tester, [_reel('a', journey: _journey(title: null))]);
      expect(find.text('Greenline Tours journey · Pokhara'), findsOneWidget);
    });
  });

  group('swipe hint', () {
    testWidgets('shows on a journey reel until dismissed, and the dismissal '
        'is remembered', (tester) async {
      await pumpFeed(tester, [_reel('a', journey: _journey())]);
      expect(find.byKey(JourneyIndicator.hintKey), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(find.byKey(JourneyIndicator.hintKey), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(JourneyHintNotifier.dismissedKey), isTrue);
    });

    testWidgets('never shows once dismissed on this device', (tester) async {
      SharedPreferences.setMockInitialValues({
        JourneyHintNotifier.dismissedKey: true,
      });
      await pumpFeed(tester, [_reel('a', journey: _journey())]);
      expect(find.byKey(JourneyIndicator.nextKey), findsOneWidget);
      expect(find.byKey(JourneyIndicator.hintKey), findsNothing);
    });

    testWidgets('stops by itself after the first few journey reels', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        JourneyHintNotifier.seenKey: JourneyHintNotifier.timesShown,
      });
      await pumpFeed(tester, [_reel('a', journey: _journey())]);
      expect(find.byKey(JourneyIndicator.hintKey), findsNothing);
    });
  });

  group('deep link', () {
    Future<void> pumpLink(WidgetTester tester, String location) async {
      phone(tester);
      final steps = _stepReels();
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(path: RouteNames.home, builder: (_, _) => const Text('Home')),
          GoRoute(
            path: RouteNames.reelDetail,
            builder: (_, state) => ReelDetailScreen(
              reelId: state.pathParameters['reelId']!,
              journeyId: state.uri.queryParameters['journey'],
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._railOverrides(),
            // The landed reel on its own does not say it is in the journey.
            reelsRepositoryProvider.overrideWithValue(
              _FakeReelsRepository(_reel('b')),
            ),
            publicJourneyProvider.overrideWith(
              (ref, id) async => PublicJourney(
                journey: _journey(),
                reels: steps,
              ),
            ),
            journeyStepReelProvider.overrideWith(
              (ref, key) async => steps[key.reelId],
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }
    }

    testWidgets('/reels/{id}?journey= opens the reel at its step', (
      tester,
    ) async {
      await pumpLink(tester, '/reels/b?journey=$_journeyId');

      expect(activeReelId(tester), 'b');
      expect(find.text('Step 2 of 3'), findsOneWidget);

      await tester.drag(stepPager(), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(activeReelId(tester), 'a');
    });

    testWidgets('without ?journey= the reel opens as it always has', (
      tester,
    ) async {
      await pumpLink(tester, '/reels/b');

      expect(activeReelId(tester), 'b');
      expect(find.byType(JourneyStepPager), findsNothing);
    });
  });

  group('wire', () {
    test('journeys absent, empty or with one step: an ordinary reel', () {
      expect(readFirstReelJourney(null), isNull);
      expect(readFirstReelJourney(const <Object>[]), isNull);
      expect(
        readFirstReelJourney([
          {
            'journeyId': _journeyId,
            'stepIndex': 0,
            'steps': [
              {'stepId': 's', 'index': 0, 'reelId': 'a', 'vendorName': 'X'},
            ],
          },
        ]),
        isNull,
      );
    });

    test('ReelJourneyDto reads in step order', () {
      final journey = readFirstReelJourney([
        {
          'journeyId': _journeyId,
          'title': 'Kathmandu → Pokhara weekend',
          'city': 'Pokhara',
          'stepIndex': 1,
          'stepCount': 2,
          'prevReelId': 'a',
          'nextReelId': null,
          'steps': [
            {
              'stepId': 's-b',
              'index': 1,
              'vendorAccountId': 'v-b',
              'vendorName': 'Hotel Barahi',
              'vendorLogoUrl': null,
              'reelId': 'b',
            },
            {
              'stepId': 's-a',
              'index': 0,
              'vendorAccountId': 'v-a',
              'vendorName': 'Greenline Tours',
              'reelId': 'a',
            },
          ],
        },
      ])!;
      expect(journey.journeyId, _journeyId);
      expect(journey.stepIndex, 1);
      expect(journey.stepCount, 2);
      expect([for (final s in journey.steps) s.reelId], ['a', 'b']);
      expect(journey.displayTitle, 'Kathmandu → Pokhara weekend');
      expect(journey.stepAfter(1), isNull);
    });

    test('a feed card carries its journey; one without stays plain', () async {
      final step = {
        'stepId': 's',
        'index': 0,
        'vendorName': 'Greenline Tours',
        'vendorAccountId': 'v',
      };
      final api = _JsonApiClient({
        'items': [
          {
            'kind': 'reel',
            'reel': {
              'reelId': 'a',
              'journeys': [
                {
                  'journeyId': _journeyId,
                  'stepIndex': 0,
                  'stepCount': 2,
                  'steps': [
                    {...step, 'reelId': 'a'},
                    {...step, 'index': 1, 'reelId': 'b', 'vendorName': 'Hotel'},
                  ],
                },
              ],
            },
          },
          {
            'kind': 'reel',
            'reel': {'reelId': 'p'},
          },
        ],
      });
      final page = await ReelsRemoteDataSource(
        apiClient: api,
      ).getReelsFeed(limit: 10);
      expect(page.reels[0].journey?.journeyId, _journeyId);
      expect(page.reels[0].journey?.stepAfter(0)?.vendorName, 'Hotel');
      expect(page.reels[1].journey, isNull);
    });

    test('GET /v1/journeys/{id} gives each step its reel at its step', () async {
      final api = _JsonApiClient({
        'id': _journeyId,
        'title': 'Pokhara weekend',
        'stepCount': 2,
        'steps': [
          {
            'stepId': 's-a',
            'index': 0,
            'vendorName': 'Greenline Tours',
            'reelId': 'a',
            'reel': {'id': 'a', 'caption': 'Bus', 'journeys': <Object>[]},
          },
          {
            'stepId': 's-b',
            'index': 1,
            'vendorName': 'Hotel Barahi',
            'reelId': 'b',
            'reel': {'id': 'b', 'caption': 'Hotel'},
          },
        ],
      });
      final journey = await ReelsRemoteDataSource(
        apiClient: api,
      ).getJourney(_journeyId);
      expect(api.lastUri, '/v1/journeys/$_journeyId');
      expect(journey.reels['b']?.journey?.stepIndex, 1);
      expect(journey.reels['b']?.journey?.prevReelId, 'a');
      expect(journey.reels['a']?.journey?.nextReelId, 'b');
    });
  });
}
