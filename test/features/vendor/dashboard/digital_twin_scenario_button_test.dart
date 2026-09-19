import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/widgets/digital_twin_scenario_button.dart';

void main() {
  testWidgets('opens bounded calibrated scenario controls', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: DigitalTwinScenarioButton()),
        ),
      ),
    );

    await tester.tap(find.byKey(DigitalTwinScenarioButton.runKey));
    await tester.pumpAndSettle();

    expect(find.text('Stress-test your store'), findsOneWidget);
    expect(find.text('Demand surge'), findsOneWidget);
    expect(find.text('Inventory loss'), findsOneWidget);
    expect(find.text('Capacity loss'), findsOneWidget);
    expect(find.text('Run calibrated scenario'), findsOneWidget);
  });
}
