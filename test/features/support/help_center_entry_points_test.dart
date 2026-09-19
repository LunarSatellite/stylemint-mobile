import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/help_center_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/my_tickets_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../smoke/fake_api_client.dart';

/// `/support/tickets` was registered but nothing navigated to it, so a
/// customer who filed a ticket could never read the agent's reply.
Widget _app(Widget parent) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => parent),
      GoRoute(
        path: RouteNames.supportTickets,
        builder: (_, _) => const MyTicketsScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('Help Center opens My Tickets', (tester) async {
    await tester.pumpWidget(_app(const HelpCenterScreen()));
    await tester.pump(const Duration(milliseconds: 50));

    final entry = find.byKey(const Key('help-center-my-tickets'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(MyTicketsScreen), findsOneWidget);
  });

  testWidgets('Contact Support opens My Tickets from "View all"', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ContactSupportScreen()));
    await tester.pump(const Duration(milliseconds: 50));

    final entry = find.byKey(const Key('contact-support-view-all-tickets'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(MyTicketsScreen), findsOneWidget);
  });
}
