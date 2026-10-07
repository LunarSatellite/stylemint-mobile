import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/friend_feed_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_comments_sheet.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/stories_tray.dart';

import 'social_feed_fakes.dart';

Widget _app(FakeFeedRepository feed) => socialTestScope(
  feed: feed,
  child: const MaterialApp(home: FriendFeedScreen()),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('stories sit above the posts', (tester) async {
    await tester.pumpWidget(_app(FakeFeedRepository(posts: [samplePost()])));
    await _settle(tester);

    expect(find.byType(StoriesTray), findsOneWidget);
    expect(find.text('Asha Gurung'), findsOneWidget);
  });

  testWidgets('the like button toggles optimistically through the feed', (
    tester,
  ) async {
    final feed = FakeFeedRepository(posts: [samplePost()]);
    await tester.pumpWidget(_app(feed));
    await _settle(tester);

    await tester.ensureVisible(find.byKey(const Key('post-action-like')));
    await tester.tap(find.byKey(const Key('post-action-like')));
    await _settle(tester);

    expect(find.text('13 likes'), findsOneWidget);
    expect(feed.likedIds, ['post-1']);

    await tester.tap(find.byKey(const Key('post-action-like')));
    await _settle(tester);

    expect(find.text('12 likes'), findsOneWidget);
    expect(feed.unlikedIds, ['post-1']);
  });

  testWidgets('comments open in a sheet and a new comment posts', (
    tester,
  ) async {
    final feed = FakeFeedRepository(posts: [samplePost()]);
    await tester.pumpWidget(_app(feed));
    await _settle(tester);

    final viewComments = find.text('View all 3 comments');
    await tester.ensureVisible(viewComments);
    await tester.tap(viewComments);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(FeedCommentsSheet), findsOneWidget);
    expect(find.text('Comments'), findsOneWidget);
    expect(find.text('Bikash'), findsOneWidget);
    expect(find.text('Where is it from?'), findsOneWidget);

    TextButton post() =>
        tester.widget(find.byKey(const Key('feed-comments-post')));
    expect(post().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('feed-comments-input')),
      'Thamel, I think',
    );
    await tester.pump();
    expect(post().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('feed-comments-post')));
    await _settle(tester);

    expect(find.text('Thamel, I think'), findsOneWidget);
    // The post behind the sheet counts the new comment.
    expect(
      find.text('View all 4 comments', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('an empty friend feed says so', (tester) async {
    await tester.pumpWidget(_app(FakeFeedRepository()));
    await _settle(tester);

    expect(
      find.text('No posts yet. Follow friends to see their posts here.'),
      findsOneWidget,
    );
  });
}
