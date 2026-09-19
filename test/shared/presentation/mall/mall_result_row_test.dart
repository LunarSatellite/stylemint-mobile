import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

const MallProductVm _rated = MallProductVm(
  id: 'p-rated',
  brandName: 'Kathmandu Atelier',
  name: longProductName,
  price: Money(amount: 3499, currency: npr),
  compareAtPrice: Money(amount: 4999, currency: npr),
  rating: 4.6,
  reviewCount: 22,
);

const MallProductVm _unrated = MallProductVm(
  id: 'p-unrated',
  name: 'Canvas tote',
  price: Money(amount: 1800, currency: npr),
);

Set<String> _loadedImageUrls(WidgetTester tester) => tester
    .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
    .map((image) => image.imageUrl)
    .toSet();

void main() {
  group('MallResultRow', () {
    testWidgets('sets brand, name and both prices, and never a photo', (
      tester,
    ) async {
      await pumpMall(
        tester,
        MallResultRow(product: photoOnlyProduct, onTap: () {}),
      );

      expect(find.text(photoOnlyProduct.name), findsOneWidget);
      // The directive: a product photo is never built outside product
      // detail, so the row draws the type ground instead.
      expect(_loadedImageUrls(tester), isNot(contains(productPhotoUrl)));
      expect(find.byType(MallTypeGround), findsOneWidget);
    });

    testWidgets('a reel-backed product carries the play mark', (tester) async {
      await pumpMall(tester, MallResultRow(product: reelProduct, onTap: () {}));

      expect(find.byType(MallPlayMark), findsOneWidget);
    });

    testWidgets('a product with no reel carries no play mark', (tester) async {
      await pumpMall(tester, MallResultRow(product: _unrated, onTap: () {}));

      expect(find.byType(MallPlayMark), findsNothing);
    });

    testWidgets('a rank is drawn only when the list is ranked', (tester) async {
      await pumpMall(
        tester,
        MallResultRow(product: _unrated, rank: 3, onTap: () {}),
      );
      expect(find.text('3'), findsOneWidget);

      await pumpMall(tester, MallResultRow(product: _unrated, onTap: () {}));
      expect(find.text('3'), findsNothing);
    });

    testWidgets('the whole row is one labelled button', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await pumpMall(
        tester,
        MallResultRow(product: _rated, onTap: () => taps++),
      );

      final label = tester.getSemantics(find.byType(MallResultRow)).label;
      expect(label, contains('Kathmandu Atelier'));
      expect(label, contains(longProductName));
      expect(label, contains('Rated 4.6 out of 5'));
      // The saving is said, not only coloured.
      expect(label, contains('30% off'));

      await tester.tap(find.byType(MallResultRow));
      expect(taps, 1);

      semantics.dispose();
    });

    testWidgets('an unrated product says no rating at all', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMall(tester, MallResultRow(product: _unrated, onTap: () {}));

      expect(
        tester.getSemantics(find.byType(MallResultRow)).label,
        isNot(contains('Rated')),
      );

      semantics.dispose();
    });

    testMallLayouts('lays out without overflow', (
      tester,
      width,
      textScale,
    ) async {
      await pumpMall(
        tester,
        Column(
          children: [
            MallResultRow(product: _rated, rank: 1, onTap: () {}),
            MallResultRow(
              product: photoOnlyProduct,
              rank: 2,
              onTap: () {},
              footer: const Text('Styled with the wide-leg trouser'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            MallResultRow(product: _unrated, onTap: () {}),
          ],
        ),
        width: width,
        textScale: textScale,
      );

      expectNoLayoutErrors(tester);
    });

    testWidgets('mirrors in RTL without overflow', (tester) async {
      await pumpMall(
        tester,
        MallResultRow(product: _rated, rank: 1, onTap: () {}),
        width: 320,
        textScale: 1.3,
        textDirection: TextDirection.rtl,
      );

      expectNoLayoutErrors(tester);
    });
  });
}
