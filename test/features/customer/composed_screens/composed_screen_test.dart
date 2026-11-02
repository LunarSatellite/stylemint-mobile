import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/data/composed_screen_parser.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/data/composed_screen_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/domain/composed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/composed_sections_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/why_strings.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_queue_store.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/repositories/engagement_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/presentation/engagement_tracker.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';

const _rid = '0f7c2f7e-6f0b-4a3a-9d55-1c2d3e4f5a6b';

Map<String, dynamic> _product(String id) => {
  'id': id,
  'name': 'Kurta $id',
  'price': {'amount': 1200, 'currency': 'NPR'},
};

Map<String, dynamic> get _body => {
  'requestId': _rid,
  'screen': 'mall_home',
  'fallback': false,
  'sections': [
    {
      'sectionId': 'festival_tihar',
      'kind': 'products',
      'title': 'Ready for Tihar',
      'titleKey': 'screen.section.festival',
      'titleParams': {'festival': 'tihar'},
      'reasonKey': 'why.declared_festival',
      'source': 'needs:festival',
      'items': [
        {
          'id': 'p-1',
          'kind': 'product',
          'position': 0,
          'score': 0.83,
          'reasonKey': 'why.matches_style',
          'reasonParams': {'dimension': 'fashion.embroidery'},
          'card': _product('p-1'),
        },
        // No embedded card: cannot be drawn, so dropped.
        {'id': 'p-2', 'kind': 'product', 'position': 1},
        {
          'id': 'p-3',
          'kind': 'product',
          'position': 2,
          'card': _product('p-3'),
        },
      ],
    },
    {
      'sectionId': 'holograms',
      'kind': 'holograms',
      'items': [
        {'id': 'h-1', 'card': <String, Object?>{}},
      ],
    },
    {
      'sectionId': 'creators_rail',
      'kind': 'creators',
      'items': [
        {
          'id': 'c-1',
          'position': 0,
          'card': {'displayName': 'Asha'},
        },
      ],
    },
    {
      'sectionId': 'shops',
      'kind': 'vendors',
      'items': [
        {
          'id': 'v-1',
          'card': {'vendorAccountId': 'v-1', 'name': 'Thamel Threads'},
        },
      ],
    },
    {'sectionId': 'empty', 'kind': 'reels', 'items': <Object>[]},
    'not a section',
  ],
  'nextCursor': null,
};

class _Api extends ApiClient {
  _Api({this.body, this.status}) : super(dio: Dio());

  final Map<String, dynamic>? body;
  final int? status;
  final List<String> gets = [];
  final List<Map<String, dynamic>> sent = [];

  Future<dynamic> _answer(String uri, Map<String, dynamic>? query) async {
    gets.add(uri);
    if (status != null) {
      final options = RequestOptions(path: uri);
      throw DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: status),
      );
    }
    return body;
  }

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _answer(uri, queryParameters);

  @override
  Future<dynamic> authGet(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? data,
  }) => _answer(uri, queryParameters);

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
}

void main() {
  group('composer parsing', () {
    test('reads sections, items, reasons and the requestId', () {
      final screen = parseComposedScreen(_body);
      expect(screen.requestId, _rid);
      expect(screen.screen, 'mall_home');
      expect(screen.fallback, isFalse);
      final first = screen.sections.first;
      expect(first.sectionId, 'festival_tihar');
      expect(first.kind, ComposedSectionKind.products);
      expect(first.reasonKey, 'why.declared_festival');
      expect(first.titleParams, {'festival': 'tihar'});
      expect(first.items.map((i) => i.id), ['p-1', 'p-3']);
      expect(first.items.first.card, isA<HomeProduct>());
      expect(first.items.first.reasonKey, 'why.matches_style');
      expect(first.items.last.position, 2);
    });

    test('unknown section kinds, empty and malformed sections are ignored', () {
      final ids = parseComposedScreen(
        _body,
      ).sections.map((s) => s.sectionId).toList();
      expect(ids, ['festival_tihar', 'creators_rail', 'shops']);
    });

    test('a card without its own id takes the item id', () {
      final sections = parseComposedScreen(_body).sections;
      final creator = sections[1].items.single.card as HomeCreator;
      expect(creator.accountId, 'c-1');
      expect(sections[2].items.single.card, isA<HomeBrand>());
    });

    test('the optional question is read, and tolerated when absent', () {
      expect(parseComposedScreen(_body).question, isNull);
      final q = parseComposedScreen({
        ..._body,
        'question': {
          'key': 'culture.festival',
          'department': 'fashion',
          'label': 'Which festivals do you celebrate?',
          'values': ['dashain', 'tihar'],
        },
      }).question!;
      expect(q.key, 'culture.festival');
      expect(q.department, 'fashion');
      expect(q.values, ['dashain', 'tihar']);
      expect(
        parseComposedScreen({
          ..._body,
          'question': {'key': 'x'},
        }).question,
        isNull,
      );
    });
  });

  group('fallback', () {
    test('404 is null and the composer is not asked again this run', () async {
      final api = _Api(status: 404);
      final repo = ComposedScreenRepository(apiClient: api);
      const req = ComposedScreenRequest(ComposedScreenName.mallHome);
      expect(await repo.load(req, signedIn: true), isNull);
      expect(await repo.load(req, signedIn: true), isNull);
      expect(api.gets, hasLength(1));
      expect(repo.notDeployed, isTrue);
    });

    test('a server error is null but asked again', () async {
      final api = _Api(status: 500);
      final repo = ComposedScreenRepository(apiClient: api);
      const req = ComposedScreenRequest(ComposedScreenName.discovery);
      expect(await repo.load(req, signedIn: false), isNull);
      expect(await repo.load(req, signedIn: false), isNull);
      expect(api.gets, hasLength(2));
    });

    test('a non-object or empty body is null', () async {
      final repo = ComposedScreenRepository(apiClient: _Api());
      expect(
        await repo.load(
          const ComposedScreenRequest(ComposedScreenName.mallHome),
          signedIn: true,
        ),
        isNull,
      );
    });

    test('signed in uses customer, guests use public', () async {
      final api = _Api(body: _body);
      final repo = ComposedScreenRepository(apiClient: api);
      const req = ComposedScreenRequest(ComposedScreenName.shopsForYou);
      expect(await repo.load(req, signedIn: true), isNotNull);
      await repo.load(req, signedIn: false);
      expect(api.gets, [
        '/v1/customer/screens/shops_for_you',
        '/v1/public/screens/shops_for_you',
      ]);
    });
  });

  group('slot', () {
    Future<void> pumpSlot(WidgetTester tester, _Api api) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            composedScreenRepositoryProvider.overrideWithValue(
              ComposedScreenRepository(apiClient: api),
            ),
            mallViewerSignedInProvider.overrideWithValue(false),
            composerEnabledProvider.overrideWithValue(true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Text('today'),
                    ComposedScreenSlot(
                      request: ComposedScreenRequest(
                        ComposedScreenName.discovery,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('on 404 the host screen is drawn unchanged', (tester) async {
      await pumpSlot(tester, _Api(status: 404));
      expect(find.text('today'), findsOneWidget);
      expect(find.byKey(const ValueKey('composed-sections')), findsNothing);
    });

    testWidgets('a live composer draws its sections with why icons', (
      tester,
    ) async {
      await pumpSlot(tester, _Api(body: _body));
      expect(find.text('Ready for Tihar'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('why-festival_tihar')));
      await tester.pumpAndSettle();
      expect(
        find.text(WhyStrings.table('en')['why.declared_festival']!),
        findsOneWidget,
      );
    });
  });

  group('interaction payload', () {
    test('a screen item tap echoes surface, requestId, position and '
        'sectionId on the product view', () async {
      final api = _Api();
      var ids = 0;
      final tracker = EngagementTracker(
        repository: EngagementRepositoryImpl(
          remoteDataSource: EngagementRemoteDataSource(apiClient: api),
          store: InMemoryEngagementQueueStore(),
        ),
        allowed: () async => true,
        owner: () => 'acct-1',
        newId: () => 'e-${++ids}',
        clock: () => DateTime.utc(2026, 11, 2, 10),
        flushInterval: const Duration(hours: 1),
      );
      addTearDown(tracker.dispose);
      tracker
        ..screenItemOpened(
          productId: 'p-1',
          screen: 'mall_home',
          requestId: _rid,
          position: 3,
          sectionId: 'festival_tihar',
        )
        ..productViewed('p-1');
      await pumpEventQueue();
      await tracker.flush();
      final event = api.sent.single;
      expect(event['kind'], 'product_view');
      expect(event['productId'], 'p-1');
      expect(event['surface'], 'screen:mall_home');
      expect(event['requestId'], _rid);
      expect(event['position'], 3);
      expect(event['sectionId'], 'festival_tihar');
    });

    test('a screen event survives the persisted round trip', () {
      final event = EngagementEvent(
        clientEventId: 'e-1',
        kind: EngagementKind.productView,
        productId: 'p-1',
        occurredUtc: DateTime.utc(2026, 11, 2),
        surface: EngagementSurface.screen,
        screen: 'cart_cross_sell',
        sectionId: 's-1',
        requestId: _rid,
        position: 0,
      );
      final back = EngagementEvent.fromJson(event.toJson())!;
      expect(back.toJson(), event.toJson());
      expect(back.toJson()['surface'], 'screen:cart_cross_sell');
    });

    test('other surfaces are unchanged and carry no sectionId', () {
      final json = EngagementEvent(
        clientEventId: 'e-1',
        kind: EngagementKind.productView,
        productId: 'p-1',
        occurredUtc: DateTime.utc(2026, 11, 2),
        surface: EngagementSurface.search,
      ).toJson();
      expect(json['surface'], 'search');
      expect(json.containsKey('sectionId'), isFalse);
    });
  });

  group('why strings', () {
    test('every reason key and UI key has a string in every language', () {
      expect(WhyStrings.locales, containsAll(['en', 'ne', 'hi', 'es', 'zh']));
      for (final locale in WhyStrings.locales) {
        final table = WhyStrings.table(locale);
        for (final key in [...WhyStrings.reasonKeys, ...WhyStrings.uiKeys]) {
          expect(
            table[key]?.trim(),
            isNotEmpty,
            reason: '$locale is missing $key',
          );
        }
      }
    });

    test('the contract has exactly 18 reason keys', () {
      expect(WhyStrings.reasonKeys.toSet(), hasLength(18));
    });

    test('unknown locale falls back to English; unknown key is null', () {
      expect(
        WhyStrings.resolve('why.trending', const Locale('fr')),
        WhyStrings.table('en')['why.trending'],
      );
      expect(WhyStrings.resolve('why.nope', const Locale('en')), isNull);
    });
  });
}
