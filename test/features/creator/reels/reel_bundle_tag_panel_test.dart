import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/datasources/reel_bundle_tags_api.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/widgets/add_tagged_product_sheet.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/widgets/reel_bundle_tag_panel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/shared/reel_bundle_tag_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundle_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundles_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';

import '../../customer/reels/fake_reels_repository.dart';

BundleCard _card(String id) => readBundleCard({
  'id': id,
  'title': 'Kit $id',
  'discountPercent': 10,
  'totals': {'listTotal': 2000, 'bundleTotal': 1800},
  'shopCount': 2,
});

ReelTaggedBundle _tag(String tagId, String bundleId) => ReelTaggedBundle(
  taggedBundleId: tagId,
  bundle: _card(bundleId),
);

class _FakeTagsApi implements ReelBundleTagsApi {
  _FakeTagsApi(this.mine);

  final Either<BundleFailure, List<BundleCard>> mine;
  Either<BundleFailure, Unit> tagResult = right(unit);
  final tagged = <String>[];
  final untagged = <String>[];

  @override
  Future<Either<BundleFailure, List<BundleCard>>> myLiveBundles() async => mine;

  @override
  Future<Either<BundleFailure, Unit>> tag(
    String reelId, {
    required String bundleId,
    double x = 0.5,
    double y = 0.8,
  }) async {
    tagged.add(bundleId);
    return tagResult;
  }

  @override
  Future<Either<BundleFailure, Unit>> untag(
    String reelId,
    String taggedBundleId,
  ) async {
    untagged.add(taggedBundleId);
    return right(unit);
  }
}

class _FakeBundlesApi implements BundlesApi {
  _FakeBundlesApi(this.onReel);

  List<ReelTaggedBundle> onReel;

  @override
  Future<Either<BundleFailure, List<ReelTaggedBundle>>> reelBundles(
    String reelId,
  ) async => right(onReel);

  @override
  Future<Either<BundleFailure, BundleDetail>> getBundle(String bundleId) =>
      throw UnimplementedError();

  @override
  Future<Either<BundleFailure, List<BundleCard>>> list(BundleListKey key) =>
      throw UnimplementedError();

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

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required _FakeTagsApi tags,
  List<ReelTaggedBundle> onReel = const [],
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reelBundleTagsApiProvider.overrideWithValue(tags),
        bundlesApiProvider.overrideWithValue(_FakeBundlesApi(onReel)),
        reelsRepositoryProvider.overrideWithValue(FakeReelsRepository()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the tag sheet offers "Bundle" once the creator has bundles', (
    tester,
  ) async {
    await _pump(
      tester,
      const AddTaggedProductSheet(reelId: 'r-1'),
      tags: _FakeTagsApi(right([_card('b-1')])),
    );

    expect(find.byKey(AddTaggedProductSheet.bundleModeKey), findsOneWidget);
    await tester.tap(find.byKey(AddTaggedProductSheet.bundleModeKey));
    await tester.pumpAndSettle();
    expect(find.text('Tag a bundle'), findsOneWidget);
    expect(find.text('Kit b-1'), findsOneWidget);
  });

  testWidgets('a bare 404 keeps the sheet products-only', (tester) async {
    await _pump(
      tester,
      const AddTaggedProductSheet(reelId: 'r-1'),
      tags: _FakeTagsApi(left(const BundleFailure(BundleFailureKind.notFound))),
    );

    expect(find.byKey(AddTaggedProductSheet.bundleModeKey), findsNothing);
    expect(find.text('Tag a product'), findsOneWidget);
  });

  testWidgets('tapping a bundle tags it on the reel', (tester) async {
    final tags = _FakeTagsApi(right([_card('b-1'), _card('b-2')]));
    await _pump(
      tester,
      const ReelBundleTagPanel(reelId: 'r-1'),
      tags: tags,
      onReel: [_tag('tb-1', 'b-1')],
    );

    // Already on the reel: shown above, not offered again.
    expect(find.text('On this reel (1 of 3)'), findsOneWidget);
    expect(find.byKey(ReelBundleTagPanel.tagKey('b-1')), findsNothing);

    await tester.tap(find.byKey(ReelBundleTagPanel.tagKey('b-2')));
    await tester.pumpAndSettle();
    expect(tags.tagged, ['b-2']);

    await tester.tap(find.byKey(ReelBundleTagPanel.untagKey('tb-1')));
    await tester.pumpAndSettle();
    expect(tags.untagged, ['tb-1']);
  });

  testWidgets('three bundles on a reel is the limit', (tester) async {
    final tags = _FakeTagsApi(right([_card('b-4')]));
    await _pump(
      tester,
      const ReelBundleTagPanel(reelId: 'r-1'),
      tags: tags,
      onReel: [_tag('t1', 'b-1'), _tag('t2', 'b-2'), _tag('t3', 'b-3')],
    );

    expect(find.byKey(ReelBundleTagPanel.limitKey), findsOneWidget);
    await tester.tap(find.byKey(ReelBundleTagPanel.tagKey('b-4')));
    await tester.pumpAndSettle();
    expect(tags.tagged, isEmpty);
  });

  testWidgets('a refusal is shown as the server said it', (tester) async {
    final tags = _FakeTagsApi(right([_card('b-1')]))
      ..tagResult = left(
        const BundleFailure(
          BundleFailureKind.rejected,
          code: 'bundle_item_not_partner',
        ),
      );
    await _pump(tester, const ReelBundleTagPanel(reelId: 'r-1'), tags: tags);

    await tester.tap(find.byKey(ReelBundleTagPanel.tagKey('b-1')));
    await tester.pumpAndSettle();
    expect(
      find.text('You need an active partnership with every shop in this bundle.'),
      findsOneWidget,
    );
  });
}
