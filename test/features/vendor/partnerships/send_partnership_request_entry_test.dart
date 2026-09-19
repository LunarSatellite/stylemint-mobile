import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/send_partnership_request_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/vendor_partnerships_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../../smoke/fake_api_client.dart';

/// `/vendor/partnerships/send` posts a real `POST /v1/vendor/partnerships/
/// invite` but no surface reached it, so a brand could only respond to
/// creators, never invite one.
void main() {
  testWidgets('Creator Partnerships opens the invite form', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const VendorPartnershipsScreen()),
        GoRoute(
          path: RouteNames.vendorSendPartnershipRequest,
          builder: (_, _) => const SendPartnershipRequestScreen(),
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
      find.byKey(const Key('vendor-partnerships-send-request')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(SendPartnershipRequestScreen), findsOneWidget);
  });
}
