import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

/// A downloadable product, cleared for quick add in every other respect — so
/// a missing buy control can only be the digital-goods gate.
const MallProductVm digitalProduct = MallProductVm(
  id: 'p-digital',
  name: 'Lightroom preset pack',
  price: Money(amount: 900, currency: npr),
  requiresOptionSelection: false,
  defaultVariantId: defaultVariantId,
  isInStock: true,
  productKind: ProductKinds.digital,
);

/// A recurring-access product, likewise addable but for its kind.
const MallProductVm subscriptionProduct = MallProductVm(
  id: 'p-subscription',
  name: 'Styling club membership',
  price: Money(amount: 1500, currency: npr),
  requiresOptionSelection: false,
  defaultVariantId: defaultVariantId,
  isInStock: true,
  productKind: ProductKinds.subscription,
);

/// A physical product with its kind stated, as the control.
const MallProductVm physicalProduct = MallProductVm(
  id: 'p-physical',
  name: 'Canvas tote',
  price: Money(amount: 1800, currency: npr),
  requiresOptionSelection: false,
  defaultVariantId: defaultVariantId,
  isInStock: true,
  productKind: ProductKinds.physical,
);

const DigitalGoodsPolicy _blocked = DigitalGoodsPolicy.blockedBy(
  StoreBillingRule.googlePlay,
);
const DigitalGoodsPolicy _allowed = DigitalGoodsPolicy.allowed();

Future<void> _pumpCard(
  WidgetTester tester,
  MallProductVm product, {
  required DigitalGoodsPolicy policy,
}) => pumpMall(
  tester,
  DigitalGoodsScope(
    policy: policy,
    child: MallProductCard(
      product: product,
      onTap: () {},
      onQuickAdd: () async => true,
    ),
  ),
);

Finder _buyControl() => find.byType(MallQuickAdd);

void main() {
  group('with digital goods blocked', () {
    testWidgets('a kind-2 card offers no buy control', (tester) async {
      await _pumpCard(tester, digitalProduct, policy: _blocked);

      expect(_buyControl(), findsNothing);
      // The card itself still renders — it is the purchase path that goes.
      expect(find.text(digitalProduct.name), findsOneWidget);
    });

    testWidgets('a kind-4 card offers no buy control', (tester) async {
      await _pumpCard(tester, subscriptionProduct, policy: _blocked);

      expect(_buyControl(), findsNothing);
    });

    testWidgets('a physical card still buys', (tester) async {
      await _pumpCard(tester, physicalProduct, policy: _blocked);

      expect(_buyControl(), findsOneWidget);
    });

    testWidgets('a card with no stated kind still buys', (tester) async {
      await _pumpCard(tester, plainAddableProduct, policy: _blocked);

      expect(_buyControl(), findsOneWidget);
    });

    testWidgets('no add or choose affordance is spoken', (tester) async {
      await _pumpCard(tester, digitalProduct, policy: _blocked);

      // Hidden, not greyed out: neither the add control nor the "choose
      // options" fallback is announced, so there is nothing to press.
      const strings = MallStrings();
      expect(
        find.bySemanticsLabel(strings.addItem(digitalProduct.name)),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(strings.chooseItem(digitalProduct.name)),
        findsNothing,
      );
    });
  });

  group('with digital goods allowed', () {
    testWidgets('a kind-2 card buys as before', (tester) async {
      await _pumpCard(tester, digitalProduct, policy: _allowed);

      expect(_buyControl(), findsOneWidget);
    });

    testWidgets('a kind-4 card buys as before', (tester) async {
      await _pumpCard(tester, subscriptionProduct, policy: _allowed);

      expect(_buyControl(), findsOneWidget);
    });

    testWidgets('the control still adds', (tester) async {
      var added = 0;
      await pumpMall(
        tester,
        DigitalGoodsScope(
          policy: _allowed,
          child: MallProductCard(
            product: digitalProduct,
            onTap: () {},
            onQuickAdd: () async {
              added++;
              return true;
            },
          ),
        ),
      );

      await tester.tap(_buyControl());
      await tester.pump();

      expect(added, 1);
    });
  });

  group('MallProductVm', () {
    test('isDigitalGood follows the stated kind', () {
      expect(digitalProduct.isDigitalGood, isTrue);
      expect(subscriptionProduct.isDigitalGood, isTrue);
      expect(physicalProduct.isDigitalGood, isFalse);
      expect(plainAddableProduct.isDigitalGood, isFalse);
    });

    test('withSaved keeps the kind', () {
      // A field-by-field copy is exactly where a new field goes missing, and
      // a dropped kind would re-open the purchase path on the saved-items
      // surfaces.
      expect(
        digitalProduct.withSaved(saved: true).productKind,
        ProductKinds.digital,
      );
    });
  });
}
