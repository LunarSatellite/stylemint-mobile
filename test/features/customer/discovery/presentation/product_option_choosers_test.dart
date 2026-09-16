import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_option_chooser.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_option_choosers.dart';

import 'product_option_fixtures.dart';

Future<ProductOptionChooser> _pump(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ProductOptionChooser? chooser,
}) async {
  final picker = chooser ?? ProductOptionChooser.forProduct(optionedProduct());
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(
                child: ProductOptionChoosers(chooser: picker),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return picker;
}

void main() {
  testWidgets('one row per option, sizes as pills, colours as swatches', (
    tester,
  ) async {
    await _pump(tester);

    // Row headers name the option and the current pick.
    expect(find.text('Size: M'), findsOneWidget);
    expect(find.text('Colour: Emerald'), findsOneWidget);
    // Every value is offered.
    expect(find.text('M'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('Ink'), findsOneWidget);
    expect(find.text('Sand'), findsOneWidget);
  });

  testWidgets('a colour is never conveyed by the swatch alone', (tester) async {
    await _pump(tester);

    // The name is printed under the swatch and spoken as the label.
    expect(find.text('Emerald'), findsOneWidget);
    expect(find.bySemanticsLabel('Colour Emerald'), findsOneWidget);
    expect(find.bySemanticsLabel('Size M'), findsOneWidget);
  });

  testWidgets('tapping a pill selects it and moves the variant', (
    tester,
  ) async {
    final chooser = await _pump(tester);

    await tester.tap(find.text('L'));
    await tester.pump();

    expect(chooser.value.picked['opt-size'], 'size-l');
    expect(chooser.value.resolvedVariant?.variantId, 'var-l-emerald');
    expect(find.text('Size: L'), findsOneWidget);
  });

  testWidgets('an unsold combination greys out and cannot be picked', (
    tester,
  ) async {
    final chooser = await _pump(tester);

    await tester.tap(find.text('Sand'));
    await tester.pump();

    // Sand is M-only: L is now unselectable, with the reason spoken.
    expect(find.bySemanticsLabel('Size L, Not available'), findsOneWidget);
    await tester.tap(find.text('L'));
    await tester.pump();
    expect(chooser.value.picked['opt-size'], 'size-m');
  });

  testWidgets('an out-of-stock value greys out with its own reason', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Ink'));
    await tester.pump();

    expect(find.bySemanticsLabel('Size L, Out of stock'), findsOneWidget);
  });

  testWidgets('a picked out-of-stock combination explains itself', (
    tester,
  ) async {
    final chooser = ProductOptionChooser.forProduct(optionedProduct())
      ..select('opt-colour', 'col-ink')
      ..select('opt-size', 'size-l');
    await _pump(tester, chooser: chooser);

    expect(find.text('This combination is out of stock'), findsOneWidget);
  });

  testWidgets('a product with no options renders nothing', (tester) async {
    final chooser = ProductOptionChooser(
      ProductOptionSelection.initial(
        const <ProductOption>[],
        const <ProductVariantOption>[],
      ),
    );
    await _pump(tester, chooser: chooser);

    expect(find.byType(Wrap), findsNothing);
    expect(find.text('M'), findsNothing);
  });

  testWidgets('no overflow at 320 width with text scale 1.3', (tester) async {
    await _pump(tester, width: 320, textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(find.text('Sand'), findsOneWidget);
  });
}
