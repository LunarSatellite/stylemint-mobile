import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/create_post_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/friend_feed_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/stories_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../../smoke/fake_api_client.dart';

/// The feed could be read but not posted to through a route, and `/stories`
/// had no caller anywhere — both now hang off the Friend Feed surface.
Widget _feedApp() {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const FriendFeedScreen()),
      GoRoute(
        path: RouteNames.feedCreatePost,
        builder: (_, _) => const CreatePostScreen(),
      ),
      GoRoute(
        path: RouteNames.stories,
        builder: (_, _) => const StoriesScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('Post enables only after entering non-whitespace content', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreatePostScreen()));

    ElevatedButton button() =>
        tester.widget(find.widgetWithText(ElevatedButton, 'Post'));

    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextFormField), 'QA post');
    await tester.pump();
    expect(button().onPressed, isNotNull);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pump();
    expect(button().onPressed, isNull);
  });

  testWidgets('Friend Feed opens the post composer', (tester) async {
    await tester.pumpWidget(_feedApp());
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('friend-feed-create-post')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CreatePostScreen), findsOneWidget);
  });

  testWidgets('Friend Feed opens Stories', (tester) async {
    await tester.pumpWidget(_feedApp());
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('friend-feed-stories')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(StoriesScreen), findsOneWidget);
  });
}
