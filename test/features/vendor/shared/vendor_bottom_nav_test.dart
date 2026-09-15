import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/providers/current_user_avatar_provider.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_bottom_nav.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_bottom_nav_bar.dart';

void main() {
  testWidgets('the vendor bar keeps its four tabs in the studio bar look', (
    tester,
  ) async {
    final taps = <int>[];
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserAvatarUrlProvider.overrideWithValue(null)],
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: VendorBottomNav(
              selectedIndex: 2,
              onTap: taps.add,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SmBottomNavBar), findsOneWidget);
    for (final label in ['Home', 'Orders', 'Products', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Products')),
      isSemantics(isButton: true, isSelected: true),
    );
    expect(find.byKey(SmBottomNavBar.avatarKey), findsNothing);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(taps, [1]);
    semantics.dispose();
  });
}
