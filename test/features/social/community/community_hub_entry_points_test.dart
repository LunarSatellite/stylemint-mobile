import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/screens/co_watch_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/community/presentation/screens/community_hub_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/create_post_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/stories_tray.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../feed/social_feed_fakes.dart';

/// `/stories` and `/co-watch` were registered but the hub listed neither, so
/// nothing in the app ever opened them. Stories now lead the hub as a tray
/// (which opens the viewer itself); Co-Watch is a shortcut chip.
Widget _app() {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CommunityHubScreen()),
      GoRoute(
        path: RouteNames.coWatch,
        builder: (_, _) => const CoWatchScreen(),
      ),
      GoRoute(
        path: RouteNames.feedCreatePost,
        builder: (_, _) => const CreatePostScreen(),
      ),
    ],
  );
  return socialTestScope(child: MaterialApp.router(routerConfig: router));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('Community hub leads with the stories tray', (tester) async {
    await tester.pumpWidget(_app());
    await _settle(tester);

    final tray = tester.widget<StoriesTray>(find.byType(StoriesTray));
    expect(tray.style, StoriesTrayStyle.surface);
    expect(tray.hideWhenEmpty, isFalse);
  });

  testWidgets('Community hub opens Co-Watch', (tester) async {
    await tester.pumpWidget(_app());
    await _settle(tester);

    final chip = find.byKey(const Key('community-shortcut-co-watch'));
    await tester.scrollUntilVisible(
      chip,
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('community-hub-shortcuts')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(chip);
    await _settle(tester);

    expect(find.byType(CoWatchScreen), findsOneWidget);
  });

  testWidgets('Community hub opens the post composer', (tester) async {
    await tester.pumpWidget(_app());
    await _settle(tester);

    await tester.tap(find.byKey(const Key('community-hub-create-post')));
    await _settle(tester);

    expect(find.byType(CreatePostScreen), findsOneWidget);
  });
}
