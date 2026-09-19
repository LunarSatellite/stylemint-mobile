import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_badges_row.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../../../../shared/presentation/mall/mall_harness.dart';

ProductDetail _product({
  double rating = 0,
  int reviewCount = 0,
  Money? compareAtPrice,
  DateTime? flashSaleEndsAt,
  ProductDelivery? delivery,
}) => ProductDetail(
  id: 'p-1',
  name: 'Linen shirt',
  description: '',
  images: const [],
  price: const Money(amount: 1000, currency: 'NPR'),
  compareAtPrice: compareAtPrice,
  rating: rating,
  reviewCount: reviewCount,
  vendorId: 'v-1',
  vendorName: 'Kathmandu Atelier',
  vendorAvatarUrl: '',
  isInStock: true,
  variants: const [],
  specifications: const {},
  shippingInfo: '',
  isSaved: false,
  isInCart: false,
  flashSaleEndsAt: flashSaleEndsAt,
  delivery: delivery,
);

void main() {
  group('ProductBadgesRow', () {
    testWidgets('an unreviewed product wears no rating badge', (tester) async {
      await pumpMall(tester, ProductBadgesRow(product: _product()));

      // The regression: this used to render "0.0 Stars" for every product
      // the catalogue had never reviewed.
      expect(find.text('0.0'), findsNothing);
      expect(find.textContaining('Stars'), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('a rating with reviews behind it is drawn and spoken', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpMall(
        tester,
        ProductBadgesRow(product: _product(rating: 4.6, reviewCount: 22)),
      );

      expect(find.text('4.6'), findsOneWidget);
      expect(find.bySemanticsLabel('Rated 4.6 out of 5'), findsOneWidget);

      semantics.dispose();
    });

    testWidgets('a rating with no reviews behind it is not drawn', (
      tester,
    ) async {
      await pumpMall(
        tester,
        ProductBadgesRow(product: _product(rating: 4.6)),
      );

      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('the discount is floored, like the tile that opened it', (
      tester,
    ) async {
      // 1000 off 1244 is 19.61%: the tile floors it to 19, so this page
      // must not round it up to 20.
      const was = Money(amount: 1244, currency: 'NPR');
      await pumpMall(
        tester,
        ProductBadgesRow(product: _product(compareAtPrice: was)),
      );

      expect(find.text('19% Off'), findsOneWidget);
      expect(find.text('20% Off'), findsNothing);

      const vm = MallProductVm(
        id: 'p-1',
        name: 'Linen shirt',
        price: Money(amount: 1000, currency: 'NPR'),
        compareAtPrice: was,
      );
      expect(vm.discountPercent, 19);
    });

    testWidgets('a compare-at price below the price claims no saving', (
      tester,
    ) async {
      await pumpMall(
        tester,
        ProductBadgesRow(
          product: _product(
            compareAtPrice: const Money(amount: 900, currency: 'NPR'),
          ),
        ),
      );

      expect(find.textContaining('Off'), findsNothing);
    });

    testWidgets('the flash-sale badge counts down and stops at zero', (
      tester,
    ) async {
      var now = DateTime.utc(2026, 9, 19, 12);
      await pumpMall(
        tester,
        ProductBadgesRow(
          product: _product(flashSaleEndsAt: now.add(const Duration(hours: 2))),
          now: () => now,
        ),
      );

      expect(find.textContaining('Flash Sale'), findsOneWidget);
      expect(find.textContaining('2h'), findsOneWidget);

      // Once the deadline passes the badge is gone, rather than frozen on
      // the last figure it happened to be built with.
      now = DateTime.utc(2026, 9, 19, 15);
      await tester.pump(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      expect(find.textContaining('Flash Sale'), findsNothing);
    });

    testWidgets('free delivery is claimed only when an option really is', (
      tester,
    ) async {
      await pumpMall(tester, ProductBadgesRow(product: _product()));
      expect(find.text('Free Delivery'), findsNothing);
    });

    testMallLayouts('lays out without overflow', (
      tester,
      width,
      textScale,
    ) async {
      await pumpMall(
        tester,
        ProductBadgesRow(
          product: _product(
            rating: 4.6,
            reviewCount: 22,
            compareAtPrice: const Money(amount: 4999, currency: 'NPR'),
            flashSaleEndsAt: DateTime.now().toUtc().add(
              const Duration(hours: 4),
            ),
          ),
        ),
        width: width,
        textScale: textScale,
      );

      expectNoLayoutErrors(tester);
    });
  });
}
