import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// In-app notices (a rider's "new delivery request", "Added to cart" without a
/// colour of its own, every push banner) used Material's default: the dark
/// scheme's inverse surface, which is white. They are StyleMint cards now.
void main() {
  for (final (name, theme) in [('dark', AppTheme.dark), ('light', AppTheme.light)]) {
    test('$name theme: notices are a dark StyleMint card, never white', () {
      final snack = theme.snackBarTheme;
      expect(snack.backgroundColor, isNot(DesignTokens.textWhite));
      expect(snack.backgroundColor, isNot(Colors.white));
      expect(snack.contentTextStyle?.color, DesignTokens.textWhite);
      expect(snack.contentTextStyle?.fontFamily, DesignTokens.fontFamily);
      expect(snack.actionTextColor, DesignTokens.primaryGreen);
      expect(snack.behavior, SnackBarBehavior.floating);
    });
  }

  testWidgets('a plain snack bar paints in the StyleMint card colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New delivery request nearby')),
              ),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(Material),
      ).first,
    );
    expect(material.color, DesignTokens.surfaceRaised);
  });
}
