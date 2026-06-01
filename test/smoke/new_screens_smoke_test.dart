import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/screens/reel_details_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/follow_creators_discovery_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/cancel_order_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reel_comments_screen.dart';
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/payouts/presentation/screens/payment_methods_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/about_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/screens/creator_performance_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/presentation/screens/vendor_inquiries_screen.dart';

import 'fake_api_client.dart';

/// Smoke tests: pump each new PDF-gap screen with a network-free ApiClient and
/// assert it builds its first frames without throwing. Validates rendering,
/// AsyncValue.when branches, list builders and null-safety — beyond `analyze`.
void main() {
  Widget wrap(Widget child) => ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
        child: MaterialApp(home: child),
      );

  Future<void> pumpAndCheck(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(wrap(screen));
    // Resolve in-flight providers (fake returns immediately), avoiding
    // pumpAndSettle which would spin forever on a loading indicator.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  }

  testWidgets('AboutScreen renders', (t) async {
    await pumpAndCheck(t, const AboutScreen());
    expect(find.text('Discover. Shop. Earn'), findsOneWidget);
  });

  testWidgets('PayoutMethodsScreen (creator) renders', (t) async {
    await pumpAndCheck(t, const PayoutMethodsScreen(role: PayeeKind.creator));
  });

  testWidgets('PayoutMethodsScreen (vendor) renders', (t) async {
    await pumpAndCheck(t, const PayoutMethodsScreen(role: PayeeKind.vendor));
  });

  testWidgets('CancelOrderScreen renders', (t) async {
    await pumpAndCheck(t, const CancelOrderScreen(orderId: 'o1'));
  });

  testWidgets('ReelCommentsScreen renders', (t) async {
    await pumpAndCheck(t, const ReelCommentsScreen(reelId: 'r1'));
  });

  testWidgets('VendorInquiriesScreen renders', (t) async {
    await pumpAndCheck(t, const VendorInquiriesScreen());
  });

  testWidgets('ReelDetailsScreen renders', (t) async {
    await pumpAndCheck(t, const ReelDetailsScreen(reelId: 'r1'));
  });

  testWidgets('BrandDetailScreen renders', (t) async {
    await pumpAndCheck(t, const BrandDetailScreen(partnershipId: 'p1'));
  });

  testWidgets('FollowCreatorsDiscoveryScreen renders', (t) async {
    await pumpAndCheck(t, const FollowCreatorsDiscoveryScreen());
  });

  testWidgets('CreatorPerformanceScreen renders', (t) async {
    await pumpAndCheck(t, const CreatorPerformanceScreen());
  });
}
