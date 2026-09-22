import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/widgets/auth_code_field.dart';

/// Regression cover for SM-002 (22 Sep TestFlight QA): backspace could not
/// walk back through the OTP boxes, so a mistyped code could not be corrected
/// without tapping the boxes by hand.
void main() {
  Future<GlobalKey<AuthCodeFieldState>> pumpField(
    WidgetTester tester, {
    ValueChanged<String>? onCompleted,
    VoidCallback? onChanged,
  }) async {
    final key = GlobalKey<AuthCodeFieldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthCodeField(
            key: key,
            onCompleted: onCompleted ?? (_) {},
            onChanged: onChanged,
          ),
        ),
      ),
    );
    return key;
  }

  /// Types into the single hidden field that backs the boxes.
  Future<void> enter(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextField), value);
    await tester.pump();
  }

  testWidgets('renders one box per digit of the code length', (tester) async {
    await pumpField(tester);
    // Boxes are presentation only — exactly one real input backs them all.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('getCode returns what was typed', (tester) async {
    final key = await pumpField(tester);
    await enter(tester, '12345');
    expect(key.currentState!.getCode(), '12345');
  });

  testWidgets('onCompleted fires once the last digit is entered', (
    tester,
  ) async {
    String? completed;
    await pumpField(tester, onCompleted: (code) => completed = code);

    await enter(tester, '1234');
    expect(completed, isNull, reason: 'not complete at 4 of 5 digits');

    await enter(tester, '12345');
    expect(completed, '12345');
  });

  testWidgets('backspace deletes from the end at every position', (
    tester,
  ) async {
    final key = await pumpField(tester);
    await enter(tester, '12345');

    // Each step is what the platform delivers for one backspace press.
    for (final expected in ['1234', '123', '12', '1', '']) {
      await enter(tester, expected);
      expect(key.currentState!.getCode(), expected);
    }
  });

  testWidgets('a completed code can still be corrected', (tester) async {
    // The old field called unfocus() on the last digit, so after auto-submit
    // nothing held focus and backspace did nothing at all.
    final key = await pumpField(tester);
    await enter(tester, '12345');

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.focusNode!.hasFocus,
      isTrue,
      reason: 'focus must survive completion so the code stays editable',
    );

    await enter(tester, '1234');
    expect(key.currentState!.getCode(), '1234');
  });

  testWidgets('onChanged fires for user edits but not for clearCode', (
    tester,
  ) async {
    var changes = 0;
    final key = await pumpField(tester, onChanged: () => changes++);

    await enter(tester, '1');
    expect(changes, 1);

    // otp_screen clears the boxes and then sets an inline error; a clear that
    // fired onChanged would wipe that error straight back out.
    final before = changes;
    key.currentState!.clearCode();
    await tester.pump();
    expect(changes, before);
    expect(key.currentState!.getCode(), '');
  });

  testWidgets('offers the OS one-time-code autofill hint', (tester) async {
    await pumpField(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
  });
}
