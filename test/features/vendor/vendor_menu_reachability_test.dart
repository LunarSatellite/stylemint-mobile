import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/screens/vendor_dashboard_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/vendor_orders_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/screens/vendor_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/presentation/screens/vendor_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_menu_button.dart';

import '../../smoke/fake_api_client.dart';

/// The 14 destinations behind the vendor more-menu (Creator Partnerships,
/// Brand Studio, Payouts & Earnings, Analytics, …) were reachable from the
/// Home tab's app bar and nowhere else, so a vendor on Orders/Products/
/// Profile could not open any of them. These pump each vendor tab for real
/// and assert the affordance is in the rendered tree and opens the sheet.
void main() {
  Widget wrap(Widget screen) {
    // Every vendor tab reads GoRouter from context (back arrows, bottom nav),
    // so a bare MaterialApp is not enough to pump them.
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => screen)],
    );
    return ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  /// Settles the screen's in-flight providers without `pumpAndSettle`, which
  /// would spin forever on the loading shimmers.
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(wrap(screen));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(VendorMenuButton));
    await tester.pump();
    // Long enough for the modal sheet's entry transition.
    await tester.pump(const Duration(milliseconds: 500));
  }

  final tabs = <String, Widget Function()>{
    'Home': VendorDashboardScreen.new,
    'Orders': VendorOrdersScreen.new,
    'Products': VendorProductsScreen.new,
    'Profile': VendorProfileScreen.new,
  };

  for (final tab in tabs.entries) {
    testWidgets('the ${tab.key} tab can open the vendor store tools', (
      tester,
    ) async {
      await pumpScreen(tester, tab.value());

      expect(find.byType(VendorMenuButton), findsOneWidget);
      expect(find.byTooltip(VendorMenuButton.label), findsOneWidget);

      await openMenu(tester);

      expect(find.text('Creator Partnerships'), findsOneWidget);
      expect(find.text('Brand Studio'), findsOneWidget);
      expect(find.text('Payouts & Earnings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the store tools button names itself to a screen reader', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, const VendorProfileScreen());

    expect(
      find.bySemanticsLabel(VendorMenuButton.label),
      findsOneWidget,
      reason: 'an unlabelled hamburger says nothing about what is behind it',
    );
    semantics.dispose();
  });
}
