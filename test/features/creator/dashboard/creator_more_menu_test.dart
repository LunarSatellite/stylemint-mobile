import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/widgets/creator_more_menu_sheet.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/rate_card_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../../smoke/fake_api_client.dart';

/// `/creator/rate-card` was registered but no surface linked to it, so a
/// creator could not publish the rates brands read before inviting them.
void main() {
  testWidgets('the creator More menu opens the Rate Card', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Consumer(
              builder: (ctx, ref, _) => TextButton(
                onPressed: () => showCreatorMoreMenu(ctx, ref),
                child: const Text('open menu'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.creatorRateCard,
          builder: (_, _) => const RateCardScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('open menu'));
    await tester.pumpAndSettle();

    final entry = find.text('Rate Card');
    await tester.scrollUntilVisible(entry, 200);
    await tester.tap(entry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(RateCardScreen), findsOneWidget);
  });
}
