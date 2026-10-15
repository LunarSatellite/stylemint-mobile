import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/checkout_emi_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../emi/credit_fakes.dart';

CartItem _item({String? variantId = 'v-1', int quantity = 1, String name = 'Pashmina overcoat'}) => CartItem(
  id: 'line-$name',
  productId: 'p-$name',
  productName: name,
  productImageUrl: '',
  variantName: 'M',
  quantity: quantity,
  unitPrice: const Money(amount: 12000, currency: 'NPR'),
  isInStock: true,
  variantId: variantId,
);

Future<void> _pump(WidgetTester tester, List<CartItem> items, {bool offered = true}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planOptionsProvider.overrideWith(
          (ref, variantId) async => offered
              ? readPlanOptions(planOptionsWire)
              : PlanOptions(
                  variantId: variantId,
                  price: const Money(amount: 12000, currency: 'NPR'),
                  options: const [],
                ),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: CheckoutEmiOption(items: items))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('cart line keeps its productVariantId', () {
    final dto = CartItemDto.fromJson(<String, dynamic>{
      'lineId': 'l1',
      'productId': 'p1',
      'productTitleSnapshot': 'Shawl',
      'quantity': 1,
      'unitPriceAmount': 5000,
      'productVariantId': 'v-42',
    });
    expect(dto.toDomain().variantId, 'v-42');
  });

  testWidgets('one eligible item shows Pay with EMI and opens the plan sheet', (tester) async {
    await _pump(tester, [_item()]);
    expect(find.byKey(CheckoutEmiOption.cardKey), findsOneWidget);
    expect(find.text('Pay with EMI'), findsOneWidget);
    await tester.tap(find.byKey(CheckoutEmiOption.cardKey));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('no plan offered draws nothing', (tester) async {
    await _pump(tester, [_item()], offered: false);
    expect(find.byKey(CheckoutEmiOption.cardKey), findsNothing);
    expect(find.byKey(CheckoutEmiOption.noteKey), findsNothing);
  });

  testWidgets('several items: a named EMI card per eligible item, plus the one-item note', (tester) async {
    await _pump(tester, [_item(), _item(variantId: 'v-2', name: 'Silk scarf')]);
    expect(find.byKey(const ValueKey('checkout-emi-card-v-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('checkout-emi-card-v-2')), findsOneWidget);
    expect(find.text('Pay with EMI · Silk scarf'), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.noteKey), findsOneWidget);
  });

  testWidgets('quantity above one still offers EMI', (tester) async {
    await _pump(tester, [_item(quantity: 2)]);
    expect(find.byKey(CheckoutEmiOption.cardKey), findsOneWidget);
  });

  testWidgets('a line without a variant id draws nothing', (tester) async {
    await _pump(tester, [_item(variantId: null)]);
    expect(find.byKey(CheckoutEmiOption.cardKey), findsNothing);
  });
}
