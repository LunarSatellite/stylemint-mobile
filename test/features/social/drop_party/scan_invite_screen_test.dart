import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/drop_party_list_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/scan_invite_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../../smoke/fake_api_client.dart';

void main() {
  testWidgets('invite field keeps horizontal space from screen edges', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ScanInviteScreen()),
      ),
    );

    expect(tester.takeException(), isNull);
    final field = find.byKey(const Key('drop-party-invite-field'));
    expect(field, findsOneWidget);
    expect(tester.getTopLeft(field).dx, greaterThanOrEqualTo(16));
    final logicalWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(tester.getTopRight(field).dx, lessThanOrEqualTo(logicalWidth - 16));
  });

  testWidgets('Live Drop Parties opens the invite scanner by route', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DropPartyListScreen()),
        GoRoute(
          path: RouteNames.dropPartyScan,
          builder: (_, _) => const ScanInviteScreen(),
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

    await tester.tap(find.byKey(const Key('drop-parties-scan-invite')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ScanInviteScreen), findsOneWidget);
  });
}
