import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/presentation/widgets/request_create_sheet.dart';

void main() {
  testWidgets('Ask enables only after entering a valid question', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RequestCreateSheet(onSubmit: (_, _, _) async => null),
        ),
      ),
    );

    ElevatedButton button() =>
        tester.widget(find.byKey(const Key('recommendation-submit-button')));

    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, 'Four');
    await tester.pump();
    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, 'What should I wear?');
    await tester.pump();
    expect(button().onPressed, isNotNull);
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump();
    expect(button().onPressed, isNull);
  });

  testWidgets('failed submission stays open and explains the failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RequestCreateSheet(
            onSubmit: (_, _, _) async => 'Could not ask right now.',
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField).first,
      'What should I wear?',
    );
    await tester.pump();
    final submit = find.byKey(const Key('recommendation-submit-button'));
    await tester.ensureVisible(submit);
    tester.widget<ElevatedButton>(submit).onPressed!();
    await tester.pumpAndSettle();

    expect(find.byType(RequestCreateSheet), findsOneWidget);
    expect(find.text('Could not ask right now.'), findsOneWidget);
    expect(find.text('What should I wear?'), findsOneWidget);
  });
}
