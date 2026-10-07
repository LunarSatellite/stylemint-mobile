import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/community/presentation/screens/community_hub_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_post_card.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/stories_tray.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../feed/social_feed_fakes.dart';

/// Every destination the hub can open, each as a labelled stand-in page.
const _destinations = <String>[
  RouteNames.feedCreatePost,
  RouteNames.friends,
  RouteNames.groups,
  RouteNames.liveSessions,
  RouteNames.dropPartiesList,
  RouteNames.coWatch,
  RouteNames.groupCartsList,
  RouteNames.recommendations,
  RouteNames.referrals,
  RouteNames.tips,
];

Widget _hub({FakeFeedRepository? feed, EmptyStoriesRepository? stories}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CommunityHubScreen()),
      for (final path in _destinations)
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('page:$path')),
        ),
    ],
  );
  return socialTestScope(
    feed: feed,
    stories: stories,
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Lays the hub out on a phone-sized screen rather than the 800x600 default.
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Finder _feedScrollable() => find
    .descendant(
      of: find.byKey(const Key('community-hub-scroll')),
      matching: find.byType(Scrollable),
    )
    .first;

Finder _shortcutScrollable() => find.descendant(
  of: find.byKey(const Key('community-hub-shortcuts')),
  matching: find.byType(Scrollable),
);

void main() {
  testWidgets('opens on stories, the composer and the shortcut row', (
    tester,
  ) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_hub());
    await _settle(tester);

    expect(find.text('Community'), findsOneWidget);
    expect(find.byType(StoriesTray), findsOneWidget);
    expect(find.text("What's new, Sam?"), findsOneWidget);
    expect(find.byKey(const Key('community-hub-create-post')), findsOneWidget);
    expect(find.byKey(const Key('community-hub-friends')), findsOneWidget);

    final safeArea = tester.widget<SafeArea>(
      find.byKey(const Key('community-hub-safe-area')),
    );
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
  });

  testWidgets('keeps every community surface one tap away', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_hub());
    await _settle(tester);

    for (final label in const [
      'Circles',
      'Live Shopping',
      'Drop Parties',
      'Co-Watch',
      'Group Carts',
      'Recommendations',
      'Friends',
      'Invite Friends',
      'Tips',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        120,
        scrollable: _shortcutScrollable(),
      );
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('each shortcut opens its surface', (tester) async {
    _usePhoneSize(tester);
    const routes = {
      'circles': RouteNames.groups,
      'live': RouteNames.liveSessions,
      'drops': RouteNames.dropPartiesList,
      'co-watch': RouteNames.coWatch,
      'group-carts': RouteNames.groupCartsList,
      'recommendations': RouteNames.recommendations,
      'friends': RouteNames.friends,
      'invite': RouteNames.referrals,
      'tips': RouteNames.tips,
    };
    for (final entry in routes.entries) {
      await tester.pumpWidget(_hub());
      await _settle(tester);

      final chip = find.byKey(Key('community-shortcut-${entry.key}'));
      await tester.scrollUntilVisible(
        chip,
        120,
        scrollable: _shortcutScrollable(),
      );
      await tester.ensureVisible(chip);
      await _settle(tester);
      await tester.tap(chip);
      await _settle(tester);

      expect(find.text('page:${entry.value}'), findsOneWidget);
      // A fresh tree for the next shortcut.
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('the composer opens the post composer', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_hub());
    await _settle(tester);

    await tester.tap(find.byKey(const Key('community-hub-composer')));
    await _settle(tester);

    expect(find.text('page:${RouteNames.feedCreatePost}'), findsOneWidget);
  });

  testWidgets('a new member gets a friendly empty feed with next steps', (
    tester,
  ) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_hub());
    await _settle(tester);

    final findFriends = find.text('Find friends');
    await tester.scrollUntilVisible(
      findFriends,
      200,
      scrollable: _feedScrollable(),
    );
    expect(
      find.text('Follow friends and creators to see their posts'),
      findsOneWidget,
    );
    expect(find.text('Create your first post'), findsOneWidget);

    await tester.tap(findFriends);
    await _settle(tester);
    expect(find.text('page:${RouteNames.friends}'), findsOneWidget);
  });

  testWidgets('"Create your first post" opens the composer', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_hub());
    await _settle(tester);

    final create = find.byKey(const Key('community-hub-empty-create-post'));
    await tester.scrollUntilVisible(create, 200, scrollable: _feedScrollable());
    await tester.tap(create);
    await _settle(tester);

    expect(find.text('page:${RouteNames.feedCreatePost}'), findsOneWidget);
  });

  testWidgets('shows the friend feed inline under the shortcuts', (
    tester,
  ) async {
    final feed = FakeFeedRepository(
      posts: [
        samplePost(),
        samplePost(id: 'post-2', userName: 'Bikash Thapa', likeCount: 1),
      ],
    );
    _usePhoneSize(tester);
    await tester.pumpWidget(_hub(feed: feed));
    await _settle(tester);

    await tester.scrollUntilVisible(
      find.text('12 likes'),
      200,
      scrollable: _feedScrollable(),
    );
    expect(find.text('Asha Gurung'), findsOneWidget);
    expect(find.text('View all 3 comments'), findsOneWidget);
    expect(find.byKey(const Key('feed-post-card-post-1')), findsOneWidget);
    expect(find.byKey(const Key('community-hub-empty')), findsNothing);

    await tester.scrollUntilVisible(
      find.text('1 like'),
      200,
      scrollable: _feedScrollable(),
    );
    expect(find.text('Bikash Thapa'), findsOneWidget);
    expect(find.byType(FeedPostCard), findsWidgets);
    // Each post is its own card.
    expect(find.byKey(const Key('feed-post-card-post-2')), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads both the feed and the stories', (
    tester,
  ) async {
    final feed = FakeFeedRepository(posts: [samplePost()]);
    final stories = EmptyStoriesRepository();
    _usePhoneSize(tester);
    await tester.pumpWidget(_hub(feed: feed, stories: stories));
    await _settle(tester);
    final feedCallsBefore = feed.getFeedCalls;

    await tester.fling(_feedScrollable(), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(feed.getFeedCalls, greaterThan(feedCallsBefore));
    expect(stories.getStoryGroupsCalls, greaterThanOrEqualTo(1));
  });
}
