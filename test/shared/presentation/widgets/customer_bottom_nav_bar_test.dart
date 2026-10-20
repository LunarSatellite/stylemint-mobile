import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/customer_bottom_nav_bar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_bottom_nav_bar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_nav_icons.dart';

Widget _host(CustomerBottomNavBar bar) =>
    MaterialApp(home: Scaffold(bottomNavigationBar: bar));

void main() {
  testWidgets('the customer bar reads Home, Discover, Cart, Profile', (
    tester,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      _host(
        CustomerBottomNavBar(
          currentIndex: CustomerBottomNavBar.profileIndex,
          onTap: taps.add,
          cartBadge: 2,
        ),
      ),
    );

    expect(find.byType(SmBottomNavBar), findsOneWidget);
    for (final label in ['Home', 'Discover', 'Cart', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
    // Orders lives in the Profile menu now.
    expect(find.text('Orders'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(SmBottomNavBar.tabKey(CustomerBottomNavBar.cartIndex)),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Cart, 2'), findsOneWidget);
    // A guest (no photo) gets the person icon, not an avatar.
    expect(find.byKey(SmBottomNavBar.avatarKey), findsNothing);
    // No scan callback, no centre action.
    expect(find.byType(SmNavCenterAction), findsNothing);

    await tester.tap(find.text('Cart'));
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(taps, [
      CustomerBottomNavBar.cartIndex,
      CustomerBottomNavBar.profileIndex,
    ]);
  });

  testWidgets('the QR scan action is large and in the true centre', (
    tester,
  ) async {
    final taps = <int>[];
    var scans = 0;
    await tester.pumpWidget(
      _host(
        CustomerBottomNavBar(
          currentIndex: CustomerBottomNavBar.homeIndex,
          onTap: taps.add,
          onScan: () => scans++,
        ),
      ),
    );

    final circle = find.byKey(SmNavCenterAction.circleKey);
    expect(
      tester.getSize(circle),
      const Size.square(CustomerBottomNavBar.scanDiameter),
    );
    final bar = tester.getRect(find.byType(SmBottomNavBar));
    expect(tester.getCenter(circle).dx, moreOrLessEquals(bar.center.dx));
    double tabX(int i) =>
        tester.getCenter(find.byKey(SmBottomNavBar.tabKey(i))).dx;
    expect(
      tester.getCenter(circle).dx,
      greaterThan(tabX(CustomerBottomNavBar.discoverIndex)),
    );
    expect(
      tester.getCenter(circle).dx,
      lessThan(tabX(CustomerBottomNavBar.cartIndex)),
    );
    final icon = tester.widget<ReelRailIcon>(
      find.descendant(of: circle, matching: find.byType(ReelRailIcon)),
    );
    expect(icon.svg, SmNavIcons.qr);
    expect(icon.size, CustomerBottomNavBar.scanIconSize);
    expect(find.bySemanticsLabel('Scan QR code'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(circle);
    await tester.pumpAndSettle();
    expect(scans, 1);
    expect(taps, isEmpty);
  });

  testWidgets('an empty cart hides the Cart badge', (tester) async {
    await tester.pumpWidget(
      _host(
        CustomerBottomNavBar(
          currentIndex: CustomerBottomNavBar.homeIndex,
          onTap: (_) {},
        ),
      ),
    );

    expect(find.byKey(SmBottomNavBar.badgeKey), findsNothing);
    expect(find.bySemanticsLabel('Cart'), findsOneWidget);
  });
}
