import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/active_filter_chips.dart';

Future<ProductListingQuery?> _pump(
  WidgetTester tester,
  ProductListingQuery query, {
  double width = 390,
  double textScale = 1,
}) async {
  ProductListingQuery? changed;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: ActiveFilterChips(
                query: query,
                onChanged: (next) => changed = next,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return changed;
}

ProductListingQuery _query(Map<String, String> params) =>
    ProductListingQuery.fromQueryParameters(params);

void main() {
  testWidgets('every applied filter shows as a chip', (tester) async {
    await _pump(
      tester,
      _query(const {
        'size': 'M',
        'color': 'Emerald',
        'inStock': 'true',
        'onSale': 'true',
        'minPrice': '500',
        'maxPrice': '2000',
        'minRating': '4',
        'optionValue': 'aa01',
      }),
    );

    expect(find.text('Size: M'), findsOneWidget);
    expect(find.text('Colour: Emerald'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget);
    expect(find.text('On sale'), findsOneWidget);
    expect(find.text('Rs 500–2000'), findsOneWidget);
    expect(find.text('4★ & up'), findsOneWidget);
    expect(find.text('Option 1'), findsOneWidget);
  });

  testWidgets('removing a chip gives back the query without it', (
    tester,
  ) async {
    final query = _query(const {'size': 'M', 'color': 'Emerald'});
    ProductListingQuery? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveFilterChips(
            query: query,
            onChanged: (next) => changed = next,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Size: M'));
    await tester.pump();

    expect(changed!.size, isNull);
    expect(changed!.color, 'Emerald');
    // …and the listing query it produces no longer carries the size.
    expect(changed!.toQueryParameters().containsKey('size'), isFalse);
  });

  testWidgets('a chip is announced as removable', (tester) async {
    await _pump(tester, _query(const {'size': 'M'}));

    expect(find.bySemanticsLabel('Remove filter Size: M'), findsOneWidget);
  });

  testWidgets('nothing renders with no filters applied', (tester) async {
    await _pump(tester, _query(const {'sort': 'newest'}));

    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('no overflow at 320 width with text scale 1.3', (tester) async {
    await _pump(
      tester,
      _query(const {'size': 'Medium', 'color': 'Emerald green'}),
      width: 320,
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });
}
