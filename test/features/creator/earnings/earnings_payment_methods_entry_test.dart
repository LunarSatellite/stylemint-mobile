import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/earnings_screen.dart';
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/payouts/presentation/screens/payment_methods_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../../smoke/fake_api_client.dart';

/// `/creator/payment-methods` was registered but only "Add Method" was
/// linked, so a creator could add a payout destination and never manage or
/// remove one. The entry mirrors the vendor earnings screen's gear icon.
void main() {
  testWidgets('Creator earnings opens saved payment methods', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const EarningsScreen()),
        GoRoute(
          path: RouteNames.creatorPaymentMethods,
          builder: (_, _) => const PayoutMethodsScreen(role: PayeeKind.creator),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(
      find.byKey(const Key('creator-earnings-payment-methods')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(PayoutMethodsScreen), findsOneWidget);
  });
}
