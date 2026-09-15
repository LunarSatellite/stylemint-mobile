import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

List<MallProductVm> _products(int count) => [
  for (var i = 0; i < count; i++)
    MallProductVm(
      id: 'p-$i',
      brandName: 'Brand $i',
      name: 'Product number $i with a name long enough to wrap',
      price: Money(amount: 1000.0 + i, currency: npr),
      compareAtPrice: i.isEven
          ? Money(amount: 2000.0 + i, currency: npr)
          : null,
    ),
];

int _columnCount(WidgetTester tester) => find
    .byType(MallProductCard)
    .evaluate()
    .map(
      (element) =>
          (element.renderObject! as RenderBox).localToGlobal(Offset.zero).dx,
    )
    .toSet()
    .length;

void main() {
  test('columns: 2 on phones, 3 from 600dp, 4 from 900dp', () {
    expect(MallProductGrid.columnsFor(320), 2);
    expect(MallProductGrid.columnsFor(599), 2);
    expect(MallProductGrid.columnsFor(600), 3);
    expect(MallProductGrid.columnsFor(899), 3);
    expect(MallProductGrid.columnsFor(900), 4);
  });

  testMallLayouts('grid fits with responsive columns', (
    tester,
    width,
    scale,
  ) async {
    await pumpMall(
      tester,
      MallProductGrid(
        products: _products(6),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onProductTap: (_) {},
        onSaveTap: (_) {},
      ),
      width: width,
      textScale: scale,
    );
    expectNoLayoutErrors(tester);
    expect(_columnCount(tester), MallProductGrid.columnsFor(width));
  });

  testWidgets('four columns at 900dp and above', (tester) async {
    await pumpMall(
      tester,
      MallProductGrid(
        products: _products(8),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      ),
      width: 1024,
    );
    expectNoLayoutErrors(tester);
    expect(_columnCount(tester), 4);
  });

  testWidgets('loading shows product skeletons and announces loading', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(
      tester,
      const MallProductGrid(
        products: [],
        isLoading: true,
        skeletonCount: 4,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
      ),
      textScale: 1.3,
    );
    expectNoLayoutErrors(tester);
    expect(find.byType(SmSkeletonProductCard), findsNWidgets(4));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('empty shows the empty-state slot', (tester) async {
    await pumpMall(
      tester,
      const MallProductGrid(
        products: [],
        emptyState: MallEmptyState(title: 'Nothing saved yet'),
      ),
    );
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('sliver grid lays out inside a CustomScrollView', (tester) async {
    Object? tapped;
    await pumpMall(
      tester,
      CustomScrollView(
        slivers: [
          MallSliverProductGrid(
            products: _products(4),
            onProductTap: (product) => tapped = product.id,
          ),
        ],
      ),
      inList: false,
      textScale: 1.3,
    );
    expectNoLayoutErrors(tester);
    expect(_columnCount(tester), 2);
    await tester.tap(find.byType(MallProductCard).first);
    expect(tapped, 'p-0');
  });
}
