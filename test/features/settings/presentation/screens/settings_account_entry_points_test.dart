import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/account_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/devices_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/mfa_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/sessions_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../../../smoke/fake_api_client.dart';

/// The account security hub (`/account`, `/account/sessions`) had no GoRoute
/// and no caller at all, so MFA, trusted devices, session revocation, blocked
/// accounts, marketing consents and pause/resume were unreachable.
Widget _app() {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: RouteNames.accountSettings,
        builder: (_, _) => const AccountScreen(),
      ),
      GoRoute(
        path: RouteNames.sessions,
        builder: (_, _) => const SessionsScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _tapRow(WidgetTester tester, String label) async {
  final row = find.text(label);
  await tester.scrollUntilVisible(row, 200);
  await tester.tap(row);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('Settings opens the Account & Security hub', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 50));

    await _tapRow(tester, 'Account & Security');

    expect(find.byType(AccountScreen), findsOneWidget);
  });

  testWidgets('the Account hub reaches the security screens', (tester) async {
    Future<void> pumpHub() async {
      final router = GoRouter(
        initialLocation: RouteNames.accountSettings,
        routes: [
          GoRoute(
            path: RouteNames.accountSettings,
            builder: (_, _) => const AccountScreen(),
          ),
          GoRoute(
            path: RouteNames.mfaSetup,
            builder: (_, _) => const MfaSetupScreen(),
          ),
          GoRoute(
            path: RouteNames.devices,
            builder: (_, _) => const DevicesScreen(),
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
    }

    await pumpHub();
    await _tapRow(tester, 'Two-Factor Authentication');
    expect(find.byType(MfaSetupScreen), findsOneWidget);

    await pumpHub();
    await _tapRow(tester, 'Trusted Devices');
    expect(find.byType(DevicesScreen), findsOneWidget);
  });

  testWidgets('Settings opens Devices & Sessions', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 50));

    await _tapRow(tester, 'Devices & Sessions');

    expect(find.byType(SessionsScreen), findsOneWidget);
  });
}
