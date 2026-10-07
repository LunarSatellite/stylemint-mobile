import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/models/feed_post_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/feed_viewer_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/friend_feed_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/shared/providers.dart';

import 'social_feed_fakes.dart';

// Regression: a post created by "Ramesh" appeared as "StyleMint user" until the
// app was reopened, because the create response carried no author name and the
// notifier prepended it into the feed as-is.

const _ramesh = FeedViewer(
  displayName: 'Ramesh',
  avatarUrl: 'https://cdn.test/ramesh.jpg',
);

/// Answers create/comment like the old backend did: no author name or photo.
class _AnonymousResponseFeedRepository extends FakeFeedRepository {
  _AnonymousResponseFeedRepository({super.posts});

  String createdName = unknownFeedAuthorName;
  String createdAvatar = '';

  @override
  Future<Either<NetworkExceptions, FeedPost>> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
    List<UploadedPostMedia>? media,
  }) async => right(
    samplePost(
      id: 'post-new',
      userName: createdName,
      content: content,
      images: const [],
      likeCount: 0,
      commentCount: 0,
    ).copyWith(userAvatarUrl: createdAvatar),
  );

  @override
  Future<Either<NetworkExceptions, FeedComment>> commentOnPost(
    String postId,
    String content,
  ) async => right(
    FeedComment(
      id: 'c-new',
      userId: 'me',
      userName: unknownFeedAuthorName,
      userAvatarUrl: '',
      content: content,
      createdAt: DateTime.now(),
    ),
  );
}

Future<FeedNotifier> _loadedNotifier(
  FakeFeedRepository repository, {
  FeedViewer? viewer = _ramesh,
}) async {
  final notifier = FeedNotifier(repository, readViewer: () => viewer);
  // The constructor starts the first page; let it land.
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

List<FeedPost> _posts(FeedNotifier notifier) => notifier.state.maybeWhen(
  loadSuccess: (posts, _, _) => posts,
  orElse: () => const <FeedPost>[],
);

void main() {
  group('FeedNotifier.createPost', () {
    test('fills a missing author from the viewer, in the result and the '
        'feed', () async {
      final notifier = await _loadedNotifier(
        _AnonymousResponseFeedRepository(posts: [samplePost()]),
      );

      final result = await notifier.createPost(content: 'Hello from Ramesh');

      final created = result.maybeWhen(
        postSuccess: (post) => post,
        orElse: () => null,
      );
      expect(created?.userName, 'Ramesh');
      expect(created?.userAvatarUrl, 'https://cdn.test/ramesh.jpg');

      final posts = _posts(notifier);
      expect(posts, hasLength(2));
      expect(posts.first.id, 'post-new');
      expect(posts.first.userName, 'Ramesh');
      expect(posts.first.userAvatarUrl, 'https://cdn.test/ramesh.jpg');
      // Other authors are untouched.
      expect(posts.last.userName, 'Asha Gurung');
      notifier.dispose();
    });

    test('keeps the name and photo the server sent', () async {
      final repository = _AnonymousResponseFeedRepository()
        ..createdName = 'Ramesh Thapa'
        ..createdAvatar = 'https://cdn.test/server.jpg';
      final notifier = await _loadedNotifier(repository);

      await notifier.createPost(content: 'Hi');

      final post = _posts(notifier).first;
      expect(post.userName, 'Ramesh Thapa');
      expect(post.userAvatarUrl, 'https://cdn.test/server.jpg');
      notifier.dispose();
    });

    test('fills only the missing photo when the name is present', () async {
      final repository = _AnonymousResponseFeedRepository()
        ..createdName = 'Ramesh Thapa';
      final notifier = await _loadedNotifier(repository);

      await notifier.createPost(content: 'Hi');

      final post = _posts(notifier).first;
      expect(post.userName, 'Ramesh Thapa');
      expect(post.userAvatarUrl, 'https://cdn.test/ramesh.jpg');
      notifier.dispose();
    });

    test('without a known viewer the stand-in stays', () async {
      final notifier = await _loadedNotifier(
        _AnonymousResponseFeedRepository(),
        viewer: null,
      );

      await notifier.createPost(content: 'Hi');

      expect(_posts(notifier).first.userName, unknownFeedAuthorName);
      notifier.dispose();
    });
  });

  test('commentOnPost fills a missing author from the viewer', () async {
    final notifier = await _loadedNotifier(
      _AnonymousResponseFeedRepository(posts: [samplePost()]),
    );

    final either = await notifier.commentOnPost('post-1', 'Nice!', 0);

    final comment = either.getOrElse((_) => throw StateError('failed'));
    expect(comment.userName, 'Ramesh');
    expect(comment.userAvatarUrl, 'https://cdn.test/ramesh.jpg');
    notifier.dispose();
  });

  test('a blank author name in the payload reads as the stand-in', () {
    final dto = FeedPostDto.fromPostJson({
      'id': 'post-id',
      'authorAccountId': 'author-id',
      'authorDisplayName': '  ',
      'body': 'Hi',
      'createdUtc': '2026-09-11T04:30:00Z',
    });

    expect(dto.userName, unknownFeedAuthorName);
    expect(isKnownFeedAuthorName(dto.userName), isFalse);
  });

  testWidgets("the viewer's new post shows their name in the feed, not "
      '"StyleMint user"', (tester) async {
    await tester.pumpWidget(
      socialTestScope(
        feed: _AnonymousResponseFeedRepository(),
        viewer: _ramesh,
        child: const MaterialApp(home: FriendFeedScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FriendFeedScreen)),
    );
    await container
        .read(feedNotifierProvider.notifier)
        .createPost(content: 'Hello from Ramesh');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.textContaining('Hello from Ramesh', findRichText: true),
      findsWidgets,
    );
    expect(find.text('Ramesh'), findsWidgets);
    expect(find.text(unknownFeedAuthorName), findsNothing);
  });
}
