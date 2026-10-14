import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/presentation/widgets/size_chart_editor.dart';

void main() {
  late SizeChart latest;

  Future<void> pump(
    WidgetTester tester, {
    bool showErrors = false,
    SizeChart? initial,
  }) async {
    latest = initial ?? SizeChartEditor.blank(GarmentType.top);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizeChartEditor(
              initial: latest,
              showErrors: showErrors,
              onChanged: (c) => latest = c,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('starts with S/M/L and the required chest column', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('Chest *'), findsNWidgets(3));
  });

  testWidgets('typing fills the chart; add and remove rows', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('chart-row-0-chest')), '92');
    expect(latest.rows.first[SizeMeasure.chest], 92);

    await tester.tap(find.byKey(const Key('chart-add-row')));
    await tester.pump();
    expect(latest.rows, hasLength(4));

    await tester.tap(find.byKey(const Key('chart-row-0-remove')));
    await tester.pump();
    expect(latest.rows, hasLength(3));
    expect(latest.rows.first.sizeLabel, 'M');
  });

  testWidgets('shows the validation problems once asked to', (tester) async {
    await pump(
      tester,
      showErrors: true,
      initial: const SizeChart(
        garmentType: GarmentType.top,
        unit: MeasurementUnit.cm,
        rows: [
          SizeChartRow(sizeLabel: 'M'),
          SizeChartRow(sizeLabel: 'm', values: {SizeMeasure.chest: 400}),
        ],
      ),
    );
    expect(find.text('Chest is required for tops.'), findsOneWidget);
    expect(find.text('Size "m" is listed twice.'), findsOneWidget);
    expect(
      find.text('Chest must be more than 0 and at most 300 cm.'),
      findsOneWidget,
    );
  });

  testWidgets('switching to footwear changes the columns', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('chart-garment-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Footwear').last);
    await tester.pumpAndSettle();
    expect(latest.garmentType, GarmentType.footwear);
    expect(find.text('Foot length *'), findsNWidgets(3));
  });
}
