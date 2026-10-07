import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/providers/current_user_avatar_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/repositories/feed_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/feed_viewer_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/repositories/stories_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

import '../../../smoke/fake_api_client.dart';

// Network-free fakes shared by the Community home and Friend Feed widget
// tests. Not a test file itself (no `_test` suffix).

FeedPost samplePost({
  String id = 'post-1',
  String userName = 'Asha Gurung',
  String content = 'Loving this jacket from the weekend drop!',
  List<String> images = const [''],
  List<FeedTaggedProduct> taggedProducts = const [],
  int likeCount = 12,
  int commentCount = 3,
  bool isLiked = false,
}) {
  return FeedPost(
    id: id,
    userId: 'user-$id',
    userName: userName,
    userAvatarUrl: '',
    content: content,
    images: images,
    taggedProducts: taggedProducts,
    likeCount: likeCount,
    commentCount: commentCount,
    shareCount: 0,
    isLiked: isLiked,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

const sampleProduct = FeedTaggedProduct(
  productId: 'prod-42',
  productName: 'Denim Jacket',
  imageUrl: '',
  price: Money(amount: 3499, currency: 'NPR'),
);

class FakeFeedRepository implements FeedRepository {
  FakeFeedRepository({this.posts = const [], this.hasMore = false});

  List<FeedPost> posts;
  bool hasMore;
  int getFeedCalls = 0;
  final likedIds = <String>[];
  final unlikedIds = <String>[];

  @override
  Future<Either<NetworkExceptions, PagedResult<FeedPost>>> getFeed({
    int limit = 20,
    String? cursor,
  }) async {
    getFeedCalls++;
    return right(
      PagedResult<FeedPost>(
        items: cursor == null ? posts : const <FeedPost>[],
        totalCount: posts.length,
        pageSize: limit,
        nextCursor: hasMore ? 'next' : null,
        hasMore: cursor == null && hasMore,
      ),
    );
  }

  @override
  Future<Either<NetworkExceptions, FeedPost>> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, Unit>> likePost(String postId) async {
    likedIds.add(postId);
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> unlikePost(String postId) async {
    unlikedIds.add(postId);
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, FeedComment>> commentOnPost(
    String postId,
    String content,
  ) async => right(
    FeedComment(
      id: 'c-new',
      userId: 'me',
      userName: 'Sam Rai',
      userAvatarUrl: '',
      content: content,
      createdAt: DateTime.now(),
    ),
  );

  @override
  Future<Either<NetworkExceptions, PagedResult<FeedComment>>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async => right(
    PagedResult<FeedComment>(
      items: [
        FeedComment(
          id: 'c-1',
          userId: 'u-2',
          userName: 'Bikash',
          userAvatarUrl: '',
          content: 'Where is it from?',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
      totalCount: 1,
      pageSize: limit,
      hasMore: false,
    ),
  );

  @override
  Future<Either<NetworkExceptions, Unit>> sharePost(String postId) async =>
      right(unit);
}

class EmptyStoriesRepository implements StoriesRepository {
  int getStoryGroupsCalls = 0;

  @override
  Future<Either<NetworkExceptions, List<StoryGroup>>> getStoryGroups() async {
    getStoryGroupsCalls++;
    return right(const <StoryGroup>[]);
  }

  @override
  Future<Either<NetworkExceptions, List<Story>>> getStories(
    String userId,
  ) async => right(const <Story>[]);

  @override
  Future<Either<NetworkExceptions, Story>> createStory({
    required String mediaFile,
    String? caption,
    List<String>? taggedProductIds,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, Unit>> deleteStory(String storyId) async =>
      right(unit);

  @override
  Future<Either<NetworkExceptions, Unit>> viewStory(String storyId) async =>
      right(unit);
}

/// A [ProviderScope] with the feed, stories and signed-in viewer faked, so the
/// social surfaces render without network, storage or a session.
Widget socialTestScope({
  required Widget child,
  FakeFeedRepository? feed,
  EmptyStoriesRepository? stories,
  FeedViewer? viewer = const FeedViewer(displayName: 'Sam Rai'),
}) {
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(FakeApiClient()),
      feedRepositoryProvider.overrideWithValue(feed ?? FakeFeedRepository()),
      storiesRepositoryProvider.overrideWithValue(
        stories ?? EmptyStoriesRepository(),
      ),
      feedViewerProvider.overrideWithValue(viewer),
      currentUserAvatarUrlProvider.overrideWithValue(null),
    ],
    child: child,
  );
}
