import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/community/presentation/screens/community_hub_screen.dart';

void main() {
  testWidgets('exposes every shipped social commerce surface', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CommunityHubScreen()),
    );

    expect(find.text('Friend Feed'), findsOneWidget);
    expect(find.text('Style & Professional Circles'), findsOneWidget);
    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.text('Live Drop Parties'), findsOneWidget);
    expect(find.text('Group Carts'), findsOneWidget);
    expect(find.text('Tips'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Friends'), 200);
    expect(find.text('Friends'), findsOneWidget);
    final safeArea = tester.widget<SafeArea>(
      find.byKey(const Key('community-hub-safe-area')),
    );
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
  });
}
