import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/repositories/feed_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

part 'feed_notifier.freezed.dart';

@freezed
sealed class FeedState with _$FeedState {
  const FeedState._();

  const factory FeedState.initial() = _FeedInitial;
  const factory FeedState.loadInProgress() = _FeedLoadInProgress;
  const factory FeedState.loadSuccess({
    required List<FeedPost> posts,
    required bool hasMore,
    String? nextCursor,
  }) = _FeedLoadSuccess;
  const factory FeedState.loadFailure(NetworkExceptions failure) =
      _FeedLoadFailure;
}

@freezed
sealed class PostState with _$PostState {
  const PostState._();

  const factory PostState.initial() = _PostInitial;
  const factory PostState.posting() = _Posting;
  const factory PostState.postSuccess(FeedPost post) = _PostSuccess;
  const factory PostState.postFailure(NetworkExceptions failure) = _PostFailure;
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier(this._repository) : super(const FeedState.initial()) {
    unawaited(loadFeed());
  }

  final FeedRepository _repository;

  Future<void> loadFeed({int limit = 20, String? cursor}) async {
    state = const FeedState.loadInProgress();
    final either = await _repository.getFeed(limit: limit, cursor: cursor);
    state = either.fold(
      FeedState.loadFailure,
      (result) => FeedState.loadSuccess(
        posts: result.items,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
      ),
    );
  }

  /// Re-fetches the first page for pull-to-refresh. Unlike [loadFeed] it keeps
  /// the current posts on screen until the new page arrives, and a failed
  /// refresh leaves them in place instead of blanking the feed.
  Future<void> refresh({int limit = 20}) async {
    final hasPosts = state.maybeWhen(
      loadSuccess: (_, _, _) => true,
      orElse: () => false,
    );
    if (!hasPosts) return loadFeed(limit: limit);
    final either = await _repository.getFeed(limit: limit);
    either.fold<void>(
      (_) {},
      (result) => state = FeedState.loadSuccess(
        posts: result.items,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
      ),
    );
  }

  /// True while a next page is in flight. Scroll listeners fire on every frame
  /// near the end of the list, so without this one page is requested many
  /// times over.
  bool _loadingMore = false;

  Future<void> loadMore() async {
    if (_loadingMore) return;
    final cursor = state.maybeWhen(
      loadSuccess: (_, hasMore, nextCursor) => hasMore ? nextCursor : null,
      orElse: () => null,
    );
    final canLoad = state.maybeWhen(
      loadSuccess: (_, hasMore, _) => hasMore,
      orElse: () => false,
    );
    if (!canLoad) return;
    _loadingMore = true;
    try {
      await _loadMoreInternal(cursor);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _loadMoreInternal(String? cursor) async {
    final either = await _repository.getFeed(cursor: cursor);
    // Append to whatever is on screen now (likes may have changed it while the
    // page loaded). A refresh in the meantime moved the cursor, so this page
    // no longer follows on and is dropped. A failed page keeps the posts; the
    // next scroll to the end retries.
    either.fold<void>(
      (_) {},
      (result) => state.maybeWhen<void>(
        loadSuccess: (posts, _, nextCursor) {
          if (nextCursor != cursor) return;
          state = FeedState.loadSuccess(
            posts: [...posts, ...result.items],
            hasMore: result.hasMore,
            nextCursor: result.nextCursor,
          );
        },
        orElse: () {},
      ),
    );
  }

  Future<PostState> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
  }) async {
    final either = await _repository.createPost(
      content: content,
      imagePaths: imagePaths,
      taggedProductIds: taggedProductIds,
    );
    final result = either.fold(
      PostState.postFailure,
      PostState.postSuccess,
    );
    either.map((post) {
      state.maybeWhen(
        loadSuccess: (posts, hasMore, nextCursor) {
          state = FeedState.loadSuccess(
            posts: [post, ...posts],
            hasMore: hasMore,
            nextCursor: nextCursor,
          );
        },
        orElse: () {},
      );
    });
    return result;
  }

  void _optimisticLikeToggle(int index) {
    state.maybeWhen(
      loadSuccess: (posts, hasMore, nextCursor) {
        final updated = posts.toList();
        final post = updated[index];
        final wasLiked = post.isLiked;
        updated[index] = post.copyWith(
          isLiked: !wasLiked,
          likeCount: post.likeCount + (wasLiked ? -1 : 1),
        );
        state = FeedState.loadSuccess(
          posts: updated,
          hasMore: hasMore,
          nextCursor: nextCursor,
        );
      },
      orElse: () {},
    );
  }

  Future<void> likePost(String postId, int index) async {
    _optimisticLikeToggle(index);
    await _repository.likePost(postId);
  }

  Future<void> unlikePost(String postId, int index) async {
    _optimisticLikeToggle(index);
    await _repository.unlikePost(postId);
  }

  void _incrementCommentCount(int index) {
    state.maybeWhen(
      loadSuccess: (posts, hasMore, nextCursor) {
        final updated = posts.toList();
        final post = updated[index];
        updated[index] = post.copyWith(commentCount: post.commentCount + 1);
        state = FeedState.loadSuccess(
          posts: updated,
          hasMore: hasMore,
          nextCursor: nextCursor,
        );
      },
      orElse: () {},
    );
  }

  Future<Either<NetworkExceptions, FeedComment>> commentOnPost(
    String postId,
    String content,
    int index,
  ) async {
    final either = await _repository.commentOnPost(postId, content);
    either.map((_) => _incrementCommentCount(index));
    return either;
  }

  Future<void> sharePost(String postId, int index) async {
    state.maybeWhen(
      loadSuccess: (posts, hasMore, nextCursor) {
        final updated = posts.toList();
        final post = updated[index];
        updated[index] = post.copyWith(shareCount: post.shareCount + 1);
        state = FeedState.loadSuccess(
          posts: updated,
          hasMore: hasMore,
          nextCursor: nextCursor,
        );
      },
      orElse: () {},
    );
    await _repository.sharePost(postId);
  }

  Future<Either<NetworkExceptions, PagedResult<FeedComment>>> loadComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    return _repository.getComments(postId, limit: limit, cursor: cursor);
  }
}
