import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/data/datasources/ai_rails_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/data/repositories/ai_rails_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/entities/ai_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/presentation/widgets/collab_product_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/presentation/widgets/product_matched_reels_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_reels_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';

import 'ai_rails_test_support.dart';

AiRailsRepositoryImpl _repo(RailsApi api) => AiRailsRepositoryImpl(
  remoteDataSource: AiRailsRemoteDataSource(
    apiClient: api,
    readReel: ReelsRemoteDataSource(apiClient: api).reelFromDetailJson,
    readProduct: DiscoveryRemoteDataSource(
      apiClient: api,
    ).relatedProductFromJson,
  ),
);

final String _together = AiRailsRemoteDataSource.boughtTogetherPath('p-1');
final String _viewed = AiRailsRemoteDataSource.alsoViewedPath('p-1');
final String _reels = AiRailsRemoteDataSource.productReelsPath('p-1');

Map<String, dynamic> _rail(
  String relation,
  List<Map<String, dynamic>> products, {
  String status = 'ok',
}) => {
  'relation': relation,
  'status': status,
  'computedUtc': '2026-10-25T02:00:00Z',
  'items': [
    for (final p in products) {'score': 0.4, 'product': p},
  ],
};

void main() {
  group('collaborative product rails — data', () {
    test('ok: cards map, the anchor and malformed cards are dropped', () async {
      final api = RailsApi({
        _together: _rail('boughtTogether', [
          productCard('p-2', 'Matching dupatta'),
          productCard('p-1', 'The anchor itself'),
          {'name': 'no id'},
        ]),
      });

      final rail = await _repo(api).boughtTogether('p-1');

      expect(rail.status, AiRailStatus.ok);
      expect(rail.items.map((p) => p.id), ['p-2']);
      expect(rail.items.single.price.amount, 1200);
    });

    test('a 404 is an empty rail, never an error', () async {
      final rail = await _repo(RailsApi({})).alsoViewed('p-1');

      expect(rail.items, isEmpty);
      expect(rail.status, AiRailStatus.notDeployed);
    });

    test('notEnoughData and an unknown status stay empty', () async {
      final api = RailsApi({
        _together: _rail('boughtTogether', const [], status: 'notEnoughData'),
        _viewed: _rail('alsoViewed', [
          productCard('p-3', 'x'),
        ], status: 'somethingNew'),
      });

      expect(
        (await _repo(api).boughtTogether('p-1')).status,
        AiRailStatus.notEnoughData,
      );
      expect(
        (await _repo(api).alsoViewed('p-1')).status,
        AiRailStatus.unavailable,
      );
    });
  });

  group('CollabProductRail', () {
    testWidgets('draws its title and products when other shoppers produced '
        'neighbours', (tester) async {
      final api = RailsApi({
        _together: _rail('boughtTogether', [
          productCard('p-2', 'Matching dupatta'),
        ]),
      });
      await pumpWithApi(
        tester,
        api,
        const CollabProductRail(
          productId: 'p-1',
          relation: CollabProductRelation.boughtTogether,
        ),
      );

      expect(find.text('Frequently bought together'), findsOneWidget);
      expect(find.text('Matching dupatta'), findsOneWidget);
    });

    testWidgets('draws nothing on a 404 — the page as it was', (tester) async {
      await pumpWithApi(
        tester,
        RailsApi({}),
        const CollabProductRail(
          productId: 'p-1',
          relation: CollabProductRelation.alsoViewed,
        ),
      );

      expect(find.text('People also viewed'), findsNothing);
      expect(
        find.byKey(CollabProductRail.railKey(CollabProductRelation.alsoViewed)),
        findsNothing,
      );
    });

    testWidgets('draws nothing when there is not enough data', (tester) async {
      await pumpWithApi(
        tester,
        RailsApi({
          _viewed: _rail('alsoViewed', const [], status: 'notEnoughData'),
        }),
        const CollabProductRail(
          productId: 'p-1',
          relation: CollabProductRelation.alsoViewed,
        ),
      );

      expect(find.text('People also viewed'), findsNothing);
    });
  });

  group('ProductMatchedReelsRail', () {
    Map<String, dynamic> answer({required bool aiApplied}) => {
      'items': [
        {
          'reel': reelCard('r-1', caption: 'Tagged it'),
          'matchType': 'featured',
          'score': 1.0,
          'reason': 'Features this product',
        },
        {
          'reel': reelCard('r-2', caption: 'Looks alike'),
          'matchType': 'meaning',
          'score': 0.84,
          'reason': 'Similar in meaning',
        },
      ],
      'aiApplied': aiApplied,
      'degradedReason': null,
    };

    testWidgets('featured and meaning reels sit in their own rails', (
      tester,
    ) async {
      await pumpWithApi(
        tester,
        RailsApi({_reels: answer(aiApplied: true)}),
        const ProductMatchedReelsRail(productId: 'p-1'),
      );

      expect(find.text(ProductMatchedReelsRail.featuredTitle), findsOneWidget);
      expect(find.text(ProductMatchedReelsRail.meaningTitle), findsOneWidget);
      expect(find.text('Matched by meaning'), findsOneWidget);
      // Never as a percentage or a number.
      expect(find.textContaining('84'), findsNothing);
    });

    testWidgets('no meaning rail when meaning matching did not run', (
      tester,
    ) async {
      await pumpWithApi(
        tester,
        RailsApi({_reels: answer(aiApplied: false)}),
        const ProductMatchedReelsRail(productId: 'p-1'),
      );

      expect(find.text(ProductMatchedReelsRail.featuredTitle), findsOneWidget);
      expect(find.text(ProductMatchedReelsRail.meaningTitle), findsNothing);
    });

    testWidgets('a 404 falls back to the tagged-reels rail', (tester) async {
      await pumpWithApi(
        tester,
        RailsApi({}),
        const ProductMatchedReelsRail(productId: 'p-1'),
      );

      expect(find.byType(ProductReelsRail), findsOneWidget);
      expect(find.text(ProductMatchedReelsRail.featuredTitle), findsNothing);
    });

    testWidgets('an empty answer draws nothing', (tester) async {
      await pumpWithApi(
        tester,
        RailsApi({
          _reels: const {'items': <dynamic>[], 'aiApplied': false},
        }),
        const ProductMatchedReelsRail(productId: 'p-1'),
      );

      expect(find.byType(ProductReelsRail), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
