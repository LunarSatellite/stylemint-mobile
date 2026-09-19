import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';

void main() {
  testWidgets('success snackbar can continue the current journey', (
    tester,
  ) async {
    var acted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => SmSnackbar.success(
                context,
                'Added to your shared cart',
                actionLabel: 'View cart',
                onAction: () => acted = true,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Added to your shared cart'), findsOneWidget);
    expect(find.text('View cart'), findsOneWidget);
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    expect(acted, isTrue);
  });
}
