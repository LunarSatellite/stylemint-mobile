import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/collection_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../mall_test_support.dart';

final _route = GoRoute(
  path: RouteNames.collection,
  builder: (_, state) => CollectionScreen(slug: state.pathParameters['slug']!),
);

CollectionItem _item(String id, {double? x, double? y, String? note}) =>
    CollectionItem(
      product: catalogProduct(id, name: 'Piece $id'),
      positionX: x,
      positionY: y,
      note: note,
    );

CollectionDetail _detail(
  CollectionKind kind,
  List<CollectionItem> items, {
  String? cursor,
}) => CollectionDetail(
  id: 'col-1',
  slug: 'monsoon',
  title: 'Monsoon layers',
  subtitle: 'Rain-ready layers',
  description: 'Layers that shrug off the rain.',
  kind: kind,
  itemCount: items.length,
  items: CatalogPage(items: items, nextCursor: cursor),
);

Future<FakeMallCatalogRepository> _pump(
  WidgetTester tester,
  Either<NetworkExceptions, CollectionDetail> Function(CollectionCall call)
  onCollection, {
  double width = 390,
  double textScale = 1,
}) async {
  final repo = FakeMallCatalogRepository(onCollection: onCollection);
  await pumpMallApp(
    tester,
    location: '/collections/monsoon',
    routes: [_route],
    overrides: [mallCatalogRepositoryProvider.overrideWithValue(repo)],
    width: width,
    textScale: textScale,
  );
  return repo;
}

void main() {
  testWidgets('editorial header and product grid', (tester) async {
    await _pump(
      tester,
      (_) => right(
        _detail(CollectionKind.editorial, [_item('a'), _item('b'), _item('c')]),
      ),
    );

    expect(find.text('EDITORIAL'), findsOneWidget);
    expect(find.text('Monsoon layers'), findsOneWidget);
    expect(find.text('Layers that shrug off the rain.'), findsOneWidget);
    expect(find.byType(MallSliverProductGrid), findsOneWidget);
    expect(find.text('Shop the look'), findsNothing);

    await tester.ensureVisible(find.text('Piece a'));
    await tester.pump();
    await tester.tap(find.text('Piece a'), warnIfMissed: false);
    await settleTransition(tester);
    expect(find.text('product:a'), findsOneWidget);
  });

  testWidgets('a look pins numbered markers and lists the pieces', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      (_) => right(
        _detail(CollectionKind.look, [
          _item('a', x: 0.3, y: 0.4, note: 'The hero piece'),
          _item('b'),
        ]),
      ),
    );

    expect(find.text('THE LOOK'), findsOneWidget);
    expect(find.bySemanticsLabel('Piece 1, Piece a'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Piece 2,')), findsNothing);

    await tester.ensureVisible(find.text('Shop the look'));
    await tester.pump();
    expect(find.text('The hero piece'), findsOneWidget);
    expect(find.text('Piece b'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Piece 1, Piece a'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.bySemanticsLabel('Piece 1, Piece a'));
    await settleTransition(tester);
    expect(find.text('product:a'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('pages items in as the viewer scrolls, once each', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      (call) => right(
        call.cursor == null
            ? _detail(
                CollectionKind.editorial,
                [for (var i = 0; i < 20; i++) _item('p$i')],
                cursor: 'next',
              )
            : _detail(CollectionKind.editorial, [_item('p19'), _item('p20')]),
      ),
    );

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pump();
    }
    await tester.pump();

    expect(repo.collectionCalls.map((c) => c.cursor), [null, 'next']);
    expect(find.text('Piece p20'), findsOneWidget);
    expect(find.text('Piece p19'), findsOneWidget);
  });

  testWidgets('not found has no retry', (tester) async {
    await _pump(tester, (_) => left(const NetworkExceptions.notFound()));
    expect(
      find.text('This collection is no longer available.'),
      findsOneWidget,
    );
    expect(find.text('Tap to retry'), findsNothing);
  });

  testWidgets('an error retries', (tester) async {
    var fail = true;
    final repo = await _pump(
      tester,
      (_) => fail
          ? left(const NetworkExceptions.serverUnavailable())
          : right(_detail(CollectionKind.editorial, [_item('a')])),
    );
    fail = false;
    await tester.tap(find.text('Tap to retry'));
    await tester.pump();
    await tester.pump();
    expect(repo.collectionCalls, hasLength(2));
    expect(find.text('Monsoon layers'), findsOneWidget);
  });

  testWidgets('an empty collection says so', (tester) async {
    await _pump(tester, (_) => right(_detail(CollectionKind.editorial, [])));
    await tester.ensureVisible(find.text('Nothing here yet'));
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  for (final width in [320.0, 390.0]) {
    for (final kind in [CollectionKind.editorial, CollectionKind.look]) {
      testWidgets('${kind.name} fits at ${width.toInt()}dp, text ×1.3', (
        tester,
      ) async {
        await _pump(
          tester,
          (_) => right(
            _detail(kind, [
              _item('a', x: 0.98, y: 0.02, note: 'A long curator note here'),
              _item('b', x: 0.5, y: 0.9),
              _item('c'),
            ]),
          ),
          width: width,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 4; i++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -400),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
