import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_comparison_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';

/// The comparison endpoint used to emit filler — "A popular choice in its
/// category.", "Another option in this category." — claims resting on
/// nothing. They are deleted, the three fields are nullable, and the endpoint
/// answers 204 when it has nothing grounded to say. None of that may reach a
/// customer as a label with an empty value after it.
Widget _host(
  ProductComparison? comparison, {
  double width = 320,
  double textScale = 1,
}) => ProviderScope(
  overrides: [
    productComparisonProvider('p1').overrideWith((ref) async => comparison),
  ],
  child: MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 640),
        textScaler: TextScaler.linear(textScale),
      ),
      child: const Scaffold(
        body: SingleChildScrollView(
          child: ProductComparisonCard(productId: 'p1'),
        ),
      ),
    ),
  ),
);

ProductComparison _comparison({
  String? bestForTag,
  String? recommendation,
  List<ProductComparisonPoint> alternatives = const [],
}) => ProductComparison(
  bestForTag: bestForTag,
  recommendation: recommendation,
  alternatives: alternatives,
);

const _alternative = ProductComparisonPoint(
  productId: 'p2',
  productName: 'Wide-mouth flask',
);

void main() {
  testWidgets('a 204 renders no card and raises no error', (tester) async {
    await tester.pumpWidget(_host(null));
    await tester.pumpAndSettle();

    expect(find.byType(Container), findsNothing);
    expect(find.textContaining('Best for'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an absent bestForTag renders no "Best for:" prefix', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _comparison(
          recommendation: 'Pick the wider one if you cycle.',
          alternatives: const [_alternative],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The dangling prefix is the exact defect: "Best for: " with nothing
    // after it. Absent means the row does not appear at all.
    expect(find.textContaining('Best for'), findsNothing);
    expect(find.byIcon(Icons.compare_arrows), findsNothing);
    // The rest of the card still renders what it does have.
    expect(find.text('Pick the wider one if you cycle.'), findsOneWidget);
  });

  testWidgets('an absent recommendation renders nothing in its place', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _comparison(
          bestForTag: 'everyday carry',
          alternatives: const [_alternative],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Best for: everyday carry'), findsOneWidget);
    // No empty paragraph stands in for the missing sentence.
    expect(find.text(''), findsNothing);
  });

  testWidgets('an absent howItDiffers drops the colon with it', (tester) async {
    await tester.pumpWidget(
      _host(
        _comparison(
          bestForTag: 'everyday carry',
          alternatives: const [_alternative],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final richText = tester.widget<RichText>(find.byType(RichText).last);
    final rendered = richText.text.toPlainText();
    // The name stands alone rather than trailing a separator into an empty
    // span: "Wide-mouth flask", never "Wide-mouth flask: ".
    expect(rendered, 'Wide-mouth flask');
    expect(rendered.endsWith(': '), isFalse);
  });

  testWidgets('a present howItDiffers keeps the name, colon and text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _comparison(
          alternatives: const [
            ProductComparisonPoint(
              productId: 'p2',
              productName: 'Wide-mouth flask',
              howItDiffers: 'Holds 4L more.',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final richText = tester.widget<RichText>(find.byType(RichText).last);
    expect(richText.text.toPlainText(), 'Wide-mouth flask: Holds 4L more.');
  });

  testWidgets('all three absent and no alternatives shows no card', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_comparison()));
    await tester.pumpAndSettle();

    // Nothing true to say. A card containing only an icon is not an
    // improvement on no card.
    expect(find.byIcon(Icons.compare_arrows), findsNothing);
    expect(find.byType(RichText), findsNothing);
  });

  testWidgets('every alternative is a named control', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        _comparison(
          bestForTag: 'everyday carry',
          alternatives: const [
            ProductComparisonPoint(
              productId: 'p2',
              productName: 'Wide-mouth flask',
              howItDiffers: 'Holds 4L more.',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('View Wide-mouth flask. Holds 4L more.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Best for: everyday carry'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an alternative with no explanation is still named', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(_comparison(alternatives: const [_alternative])),
    );
    await tester.pumpAndSettle();

    // No trailing full stop with nothing before it.
    expect(find.bySemanticsLabel('View Wide-mouth flask'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        _comparison(
          bestForTag: 'everyday carry on long commutes',
          recommendation:
              'Pick the wider one if you cycle, since it clears a bottle cage.',
          alternatives: const [
            ProductComparisonPoint(
              productId: 'p2',
              productName: 'Wide-mouth insulated flask',
              howItDiffers: 'Holds 4L more and fits a standard cage.',
            ),
          ],
        ),
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
