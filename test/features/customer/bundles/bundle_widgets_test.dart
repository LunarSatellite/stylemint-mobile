import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundle_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundles_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';

class _FakeBundlesApi implements BundlesApi {
  _FakeBundlesApi(this.listResult);

  final Either<BundleFailure, List<BundleCard>> listResult;
  final keys = <BundleListKey>[];

  @override
  Future<Either<BundleFailure, BundleDetail>> getBundle(String bundleId) =>
      throw UnimplementedError();

  @override
  Future<Either<BundleFailure, List<BundleCard>>> list(BundleListKey key) async {
    keys.add(key);
    return listResult;
  }

  @override
  Future<Either<BundleFailure, List<ReelTaggedBundle>>> reelBundles(
    String reelId,
  ) async => right(const []);

  @override
  Future<Either<BundleFailure, Cart>> addToCart({
    required String bundleId,
    required int termsVersion,
    required Map<String, String> variants,
    required String idempotencyKey,
    int quantity = 1,
    String? taggedBundleId,
    String? affiliateCode,
  }) => throw UnimplementedError();
}

BundleCard _card(String id, String title) => readBundleCard({
  'id': id,
  'title': title,
  'discountPercent': 10,
  'totals': {'listTotal': 20000, 'bundleTotal': 18000},
  'itemCount': 4,
  'shopCount': 2,
});

Future<GoRouter> _pump(WidgetTester tester, Widget child, {_FakeBundlesApi? api}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: child)),
      GoRoute(
        path: '/bundles/:bundleId',
        builder: (_, state) => Text('Bundle ${state.uri}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (api != null) bundlesApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

const _vendorKey = (vendorAccountId: 'v-1', creatorAccountId: null);

void main() {
  testWidgets('a storefront rail lists the shop\'s bundles', (tester) async {
    final api = _FakeBundlesApi(right([_card('b-1', 'Trekking kit')]));
    await _pump(
      tester,
      const CustomScrollView(slivers: [BundleRailSliver(listKey: _vendorKey)]),
      api: api,
    );

    expect(find.byKey(BundleRailSliver.railKey), findsOneWidget);
    expect(find.text('Trekking kit'), findsOneWidget);
    expect(find.text('10% off'), findsOneWidget);
    expect(find.text('4 items from 2 shops'), findsOneWidget);
    expect(api.keys.single.vendorAccountId, 'v-1');

    await tester.tap(find.byKey(BundleCardTile.tileKey('b-1')));
    await tester.pumpAndSettle();
    expect(find.text('Bundle /bundles/b-1'), findsOneWidget);
  });

  testWidgets('a bare 404 or no bundles draws nothing', (tester) async {
    await _pump(
      tester,
      const CustomScrollView(slivers: [BundleRailSliver(listKey: _vendorKey)]),
      api: _FakeBundlesApi(left(const BundleFailure(BundleFailureKind.notFound))),
    );
    expect(find.byKey(BundleRailSliver.railKey), findsNothing);
  });

  testWidgets('a reel bundle tag opens the bundle with its tag', (tester) async {
    final tags = readReelTaggedBundles([
      {
        'taggedBundleId': 'tb-1',
        'bundle': {
          'id': 'b-1',
          'title': 'Trekking kit',
          'totals': {'listTotal': 20000, 'bundleTotal': 18000},
        },
      },
    ]);
    await _pump(tester, ReelBundleTags(bundles: tags));

    expect(find.text('Rs 18,000 · save Rs 2,000'), findsOneWidget);
    await tester.tap(find.byKey(ReelBundleTags.chipKey('tb-1')));
    await tester.pumpAndSettle();
    expect(find.text('Bundle /bundles/b-1?t=tb-1'), findsOneWidget);
  });
}
