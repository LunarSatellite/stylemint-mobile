import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/friend_feed_screen.dart';

import 'social_feed_fakes.dart';

/// A feed whose server refuses every like.
class _RefusingFeedRepository extends FakeFeedRepository {
  _RefusingFeedRepository({super.posts});

  @override
  Future<Either<NetworkExceptions, Unit>> likePost(String postId) async {
    likedIds.add(postId);
    return left(const NetworkExceptions.unexpectedError());
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('a like the server refuses is undone and the user is told', (
    tester,
  ) async {
    final feed = _RefusingFeedRepository(posts: [samplePost()]);
    await tester.pumpWidget(
      socialTestScope(
        feed: feed,
        child: const MaterialApp(home: FriendFeedScreen()),
      ),
    );
    await _settle(tester);

    await tester.ensureVisible(find.byKey(const Key('post-action-like')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('post-action-like')));
    await _settle(tester);

    expect(feed.likedIds, ['post-1']);
    expect(find.text('12 likes'), findsOneWidget);
    expect(find.text('13 likes'), findsNothing);
    expect(
      find.text('Could not like the post. Please try again.'),
      findsOneWidget,
    );
  });
}
