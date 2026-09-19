import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/datasources/assistant_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/models/companion_recommendation_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_recommendation.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/widgets/companion_recommendations_shelf.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/shared/providers.dart';

/// Phrasings that would turn a globally popular item into a personal claim.
const List<String> _personalPhrases = [
  'for you',
  'based on your',
  'we thought',
  'matches your',
  'your preferences',
  'picked for',
];

class _ListApiClient extends ApiClient {
  _ListApiClient(this.body) : super(dio: Dio());

  final Object? body;
  String? uri;
  Map<String, dynamic>? query;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.uri = uri;
    query = queryParameters;
    return body;
  }
}

const CompanionRecommendation _shopped = CompanionRecommendation(
  entityId: 'p1',
  entityType: 'product',
  title: 'Trail Runner 2',
  friendMessage: 'This pairs with the one you saved 👟',
  basis: RecommendationBasis.shoppedCategory,
  reason: 'Popular in the same category as Runner X, which you saved',
);

const CompanionRecommendation _popular = CompanionRecommendation(
  entityId: 'p2',
  entityType: 'product',
  title: 'Everyday Tote',
  friendMessage: 'Lots of shoppers are into this one right now 🔥',
  basis: RecommendationBasis.popularNow,
  reason: 'Popular with shoppers right now',
);

Widget _host(
  List<CompanionRecommendation> recommendations, {
  double width = 320,
  double textScale = 1,
}) => ProviderScope(
  overrides: [
    companionRecommendationsProvider.overrideWith(
      (ref) async => recommendations,
    ),
  ],
  child: MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 640),
        textScaler: TextScaler.linear(textScale),
      ),
      child: const Scaffold(
        body: SingleChildScrollView(child: CompanionRecommendationsShelf()),
      ),
    ),
  ),
);

void main() {
  group('RecommendationBasis.parse', () {
    test('reads names and ordinals', () {
      expect(
        RecommendationBasis.parse('ShoppedCategory'),
        RecommendationBasis.shoppedCategory,
      );
      expect(
        RecommendationBasis.parse('PopularNow'),
        RecommendationBasis.popularNow,
      );
      expect(
        RecommendationBasis.parse(1),
        RecommendationBasis.shoppedCategory,
      );
      expect(RecommendationBasis.parse(2), RecommendationBasis.popularNow);
    });

    test('an unknown basis degrades, never to the personal one', () {
      for (final raw in <Object?>['Sponsored', 7, null, '', true]) {
        expect(RecommendationBasis.parse(raw), RecommendationBasis.unknown);
        expect(RecommendationBasis.parse(raw).isPersonal, isFalse);
      }
    });

    test('generic basis labels carry no personalisation phrasing', () {
      for (final basis in [
        RecommendationBasis.popularNow,
        RecommendationBasis.unknown,
      ]) {
        final label = basis.label.toLowerCase();
        for (final phrase in _personalPhrases) {
          expect(label, isNot(contains(phrase)));
        }
      }
    });
  });

  group('CompanionRecommendationListDto', () {
    test('parses the array the endpoint sends, with no score present', () {
      final parsed = CompanionRecommendationListDto.fromJson([
        {
          'entityId': 'p1',
          'entityType': 'product',
          'title': 'Trail Runner 2',
          'thumbnailUrl': 'https://cdn.test/p1.jpg',
          'friendMessage': 'Nice with your saved pair',
          'basis': 'ShoppedCategory',
          'reason': 'Popular in the same category as Runner X, which you saved',
        },
      ]).toDomain();

      expect(parsed, hasLength(1));
      expect(parsed.single.basis, RecommendationBasis.shoppedCategory);
      expect(
        parsed.single.reason,
        'Popular in the same category as Runner X, which you saved',
      );
    });

    test('the removed Score field breaks nothing, present or absent', () {
      Map<String, dynamic> payload({bool withScore = false}) => {
        'entityId': 'p2',
        'entityType': 'product',
        'title': 'Everyday Tote',
        'friendMessage': 'Doing the rounds',
        'basis': 'PopularNow',
        'reason': 'Popular with shoppers right now',
        if (withScore) 'score': 0.75,
      };

      final without = CompanionRecommendationListDto.fromJson([
        payload(),
      ]).toDomain();
      final withLegacyScore = CompanionRecommendationListDto.fromJson([
        payload(withScore: true),
      ]).toDomain();

      // A stale server or cached body that still carries the old field parses
      // to exactly the same thing: the number is not read, so it cannot be
      // rendered.
      expect(without, withLegacyScore);
      expect(without.single.basis, RecommendationBasis.popularNow);
    });

    test('entries with no id or no title are dropped', () {
      final parsed = CompanionRecommendationListDto.fromJson([
        {'entityId': '', 'title': 'No id'},
        {'entityId': 'p3', 'title': ''},
        {'entityId': 'p4', 'title': 'Kept', 'basis': 'PopularNow'},
      ]).toDomain();

      expect(parsed.map((r) => r.entityId), ['p4']);
      expect(parsed.single.basis, RecommendationBasis.popularNow);
    });

    test('a non-list body yields nothing rather than throwing', () {
      expect(
        CompanionRecommendationListDto.fromJson(null).toDomain(),
        isEmpty,
      );
    });
  });

  group('repository', () {
    test('asks the recommendations endpoint and maps the array', () async {
      final client = _ListApiClient([
        {
          'entityId': 'r1',
          'entityType': 'reel',
          'title': 'Winter layering',
          'basis': 'PopularNow',
          'reason': 'Trending on StyleMint right now',
        },
      ]);
      final repository = AssistantRepositoryImpl(
        remoteDataSource: AssistantRemoteDataSource(apiClient: client),
      );

      final result = await repository.getRecommendations(limit: 5);

      expect(client.uri, '/v1/customer/companion/recommendations');
      expect(client.query?['limit'], 5);
      expect(
        result.getOrElse((_) => const []).single.reason,
        'Trending on StyleMint right now',
      );
    });
  });

  group('CompanionRecommendationsShelf', () {
    testWidgets('renders the server reason verbatim', (tester) async {
      await tester.pumpWidget(_host(const [_shopped, _popular]));
      await tester.pumpAndSettle();

      expect(
        find.text('Popular in the same category as Runner X, which you saved'),
        findsOneWidget,
      );
      expect(find.text('Popular with shoppers right now'), findsOneWidget);
    });

    testWidgets('a popular item is never framed as personal', (tester) async {
      await tester.pumpWidget(_host(const [_popular]));
      await tester.pumpAndSettle();

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      for (final phrase in _personalPhrases) {
        expect(rendered, isNot(contains(phrase)));
      }
      expect(find.text(RecommendationBasis.popularNow.label), findsOneWidget);
    });

    testWidgets('no score, percentage or bar is drawn', (tester) async {
      await tester.pumpWidget(_host(const [_shopped, _popular]));
      await tester.pumpAndSettle();

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(rendered, isNot(contains('%')));
      expect(rendered, isNot(contains('0.7')));
      expect(rendered, isNot(contains('0.8')));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('draws no product photograph', (tester) async {
      await tester.pumpWidget(_host(const [_shopped, _popular]));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('an empty list renders nothing at all', (tester) async {
      await tester.pumpWidget(_host(const []));
      await tester.pumpAndSettle();

      expect(find.byKey(CompanionRecommendationsShelf.shelfKey), findsNothing);
    });

    testWidgets('every card is a labelled control', (tester) async {
      await tester.pumpWidget(_host(const [_shopped]));
      await tester.pumpAndSettle();
      final handle = tester.ensureSemantics();

      expect(
        find.bySemanticsLabel(
          RegExp('Open Trail Runner 2', caseSensitive: false),
        ),
        findsOneWidget,
      );
      // The spoken form keeps the server's sentence.
      expect(
        find.bySemanticsLabel(RegExp('which you saved')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(const [_shopped, _popular], textScale: 1.3),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
