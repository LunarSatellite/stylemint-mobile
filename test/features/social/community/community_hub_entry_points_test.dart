import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/screens/co_watch_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/community/presentation/screens/community_hub_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/stories_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../../smoke/fake_api_client.dart';

/// `/stories` and `/co-watch` were registered but the hub listed neither, so
/// nothing in the app ever opened them.
Widget _app() {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CommunityHubScreen()),
      GoRoute(
        path: RouteNames.stories,
        builder: (_, _) => const StoriesScreen(),
      ),
      GoRoute(
        path: RouteNames.coWatch,
        builder: (_, _) => const CoWatchScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _tapDestination(WidgetTester tester, String title) async {
  final row = find.text(title);
  await tester.scrollUntilVisible(row, 200);
  await tester.tap(row);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('Community hub opens Stories', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 50));

    await _tapDestination(tester, 'Stories');

    expect(find.byType(StoriesScreen), findsOneWidget);
  });

  testWidgets('Community hub opens Co-Watch', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 50));

    await _tapDestination(tester, 'Co-Watch');

    expect(find.byType(CoWatchScreen), findsOneWidget);
  });
}
