import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/widgets/cart_item_tile.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

Money _npr(double a) => Money(amount: a, currency: 'NPR');

final _item = CartItem(
  id: 'line-1',
  productId: 'prod-1',
  productName: 'Hand-loomed pashmina overcoat, undyed',
  productImageUrl: 'https://example.test/coat.jpg',
  variantName: 'L / Charcoal',
  quantity: 2,
  unitPrice: _npr(62250),
  isInStock: true,
  creatorHandle: 'aasha.weaves',
  commissionRate: 0.12,
);

Widget _host(Widget child) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(
      size: Size(320, 800),
      textScaler: TextScaler.linear(1.3),
    ),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  Widget tile() => CartItemTile(
    item: _item,
    onIncrement: () {},
    onDecrement: () {},
    onDelete: () {},
    onSaveForLater: () {},
  );

  testWidgets('lays out without overflow at 320dp and text scale 1.3', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(tile()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('quantity controls meet the 44dp minimum touch target', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_host(tile()));
    await tester.pump();

    for (final icon in [Icons.remove, Icons.add]) {
      final target = tester.getSize(
        find
            .ancestor(
              of: find.byIcon(icon),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(
        target.width,
        greaterThanOrEqualTo(DesignTokens.minTouchTarget),
        reason: '$icon stepper button is narrower than 44dp',
      );
      expect(
        target.height,
        greaterThanOrEqualTo(DesignTokens.minTouchTarget),
        reason: '$icon stepper button is shorter than 44dp',
      );
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('save for later is an inked button, not a bare label', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var saved = false;
    await tester.pumpWidget(
      _host(
        CartItemTile(
          item: _item,
          onIncrement: () {},
          onDecrement: () {},
          onDelete: () {},
          onSaveForLater: () => saved = true,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Save for later'));
    expect(saved, isTrue);
    expect(
      find.ancestor(
        of: find.text('Save for later'),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
