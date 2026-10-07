import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/repositories/feed_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/feed_viewer_provider.dart';
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
  /// [readViewer] returns the signed-in viewer at call time; it fills the
  /// author on posts and comments the viewer just created (see
  /// [_asViewersPost]).
  FeedNotifier(this._repository, {FeedViewer? Function()? readViewer})
    : _readViewer = readViewer ?? _noViewer,
      super(const FeedState.initial()) {
    unawaited(loadFeed());
  }

  final FeedRepository _repository;
  final FeedViewer? Function() _readViewer;

  static FeedViewer? _noViewer() => null;

  /// Posts with a like/unlike request in flight. A like and its unlike must
  /// not race each other to the server, so taps on such a post wait.
  final _likesInFlight = <String>{};

  /// The viewer's own like taps, laid over every page that might predate
  /// them — see [_withLikeOverrides].
  final _likeOverrides = <String, _LikeOverride>{};

  /// Orders feed fetches against settled likes: a page requested before the
  /// server stored a like cannot know about it.
  int _tick = 0;

  Future<void> loadFeed({int limit = 20, String? cursor}) async {
    state = const FeedState.loadInProgress();
    final fetchTick = ++_tick;
    final either = await _repository.getFeed(limit: limit, cursor: cursor);
    state = either.fold(
      FeedState.loadFailure,
      (result) => FeedState.loadSuccess(
        posts: _withLikeOverrides(result.items, fetchTick),
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
    final fetchTick = ++_tick;
    final either = await _repository.getFeed(limit: limit);
    either.fold<void>(
      (_) {},
      (result) => state = FeedState.loadSuccess(
        posts: _withLikeOverrides(result.items, fetchTick),
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
    final fetchTick = ++_tick;
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
            posts: [...posts, ..._withLikeOverrides(result.items, fetchTick)],
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
    List<UploadedPostMedia>? media,
  }) async {
    final either = (await _repository.createPost(
      content: content,
      imagePaths: imagePaths,
      taggedProductIds: taggedProductIds,
      media: media,
    )).map(_asViewersPost);
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

  /// Likes [postId] optimistically: the heart and count flip at once. If the
  /// server refuses, they flip back and the failure is returned so the caller
  /// can say so. Posts are matched by id, not list position — a refresh or a
  /// new post can shift the list while the request is out.
  Future<Either<NetworkExceptions, Unit>> likePost(String postId) =>
      _setLiked(postId, liked: true);

  /// Unlikes [postId]; same optimistic contract as [likePost].
  Future<Either<NetworkExceptions, Unit>> unlikePost(String postId) =>
      _setLiked(postId, liked: false);

  Future<Either<NetworkExceptions, Unit>> _setLiked(
    String postId, {
    required bool liked,
  }) async {
    final post = _postById(postId);
    // Nothing to send for a post not on screen or already in that state. A
    // tap while the previous one is still in flight is dropped rather than
    // racing it: the server could apply the two in either order.
    if (post == null ||
        post.isLiked == liked ||
        _likesInFlight.contains(postId)) {
      return right(unit);
    }

    _likesInFlight.add(postId);
    final override = _LikeOverride(isLiked: liked);
    _likeOverrides[postId] = override;
    _replacePost(postId, (p) => _withLiked(p, liked: liked));

    final either = liked
        ? await _repository.likePost(postId)
        : await _repository.unlikePost(postId);
    _likesInFlight.remove(postId);
    if (!mounted) return either;

    either.fold<void>(
      (_) {
        _likeOverrides.remove(postId);
        _replacePost(postId, (p) => _withLiked(p, liked: !liked));
      },
      (_) => override.settledTick = ++_tick,
    );
    return either;
  }

  FeedPost? _postById(String postId) => state.maybeWhen(
    loadSuccess: (posts, _, _) {
      for (final post in posts) {
        if (post.id == postId) return post;
      }
      return null;
    },
    orElse: () => null,
  );

  void _replacePost(String postId, FeedPost Function(FeedPost) update) {
    state.maybeWhen(
      loadSuccess: (posts, hasMore, nextCursor) {
        state = FeedState.loadSuccess(
          posts: [for (final p in posts) p.id == postId ? update(p) : p],
          hasMore: hasMore,
          nextCursor: nextCursor,
        );
      },
      orElse: () {},
    );
  }

  static FeedPost _withLiked(FeedPost post, {required bool liked}) {
    if (post.isLiked == liked) return post;
    final count = post.likeCount + (liked ? 1 : -1);
    return post.copyWith(isLiked: liked, likeCount: count < 0 ? 0 : count);
  }

  /// Lays the viewer's own like taps over a freshly fetched page. A tap still
  /// in flight, or one the server stored after this page was requested, is
  /// newer than the page and wins — otherwise a refresh landing mid-like
  /// would flip the heart back. Once a page requested after the like was
  /// stored arrives, the server is the truth again and the tap is forgotten.
  List<FeedPost> _withLikeOverrides(List<FeedPost> posts, int fetchTick) {
    if (_likeOverrides.isEmpty) return posts;
    return [for (final post in posts) _overlayLike(post, fetchTick)];
  }

  FeedPost _overlayLike(FeedPost post, int fetchTick) {
    final override = _likeOverrides[post.id];
    if (override == null) return post;
    final settledTick = override.settledTick;
    if (settledTick != null && settledTick < fetchTick) {
      _likeOverrides.remove(post.id);
      return post;
    }
    return _withLiked(post, liked: override.isLiked);
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
    final either = (await _repository.commentOnPost(
      postId,
      content,
    )).map(_asViewersComment);
    either.map((_) => _incrementCommentCount(index));
    return either;
  }

  /// A just-created post is the viewer's own and goes straight into the feed.
  /// If the response came without the author's name or photo, take them from
  /// the signed-in viewer so it never shows as "StyleMint user" until the
  /// next refetch.
  FeedPost _asViewersPost(FeedPost post) {
    final viewer = _readViewer();
    if (viewer == null) return post;
    return post.copyWith(
      userName: _fillName(post.userName, viewer),
      userAvatarUrl: _fillAvatar(post.userAvatarUrl, viewer),
    );
  }

  /// Same as [_asViewersPost] for the comment the viewer just posted.
  FeedComment _asViewersComment(FeedComment comment) {
    final viewer = _readViewer();
    if (viewer == null) return comment;
    return comment.copyWith(
      userName: _fillName(comment.userName, viewer),
      userAvatarUrl: _fillAvatar(comment.userAvatarUrl, viewer),
    );
  }

  /// Null keeps the server's value (copyWith semantics).
  static String? _fillName(String current, FeedViewer viewer) {
    if (isKnownFeedAuthorName(current)) return null;
    final name = viewer.displayName.trim();
    return name.isEmpty ? null : name;
  }

  static String? _fillAvatar(String current, FeedViewer viewer) {
    if (current.trim().isNotEmpty) return null;
    final avatar = viewer.avatarUrl?.trim() ?? '';
    return avatar.isEmpty ? null : avatar;
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

/// One of the viewer's like taps on a post. [settledTick] is set once the
/// server has stored it; pages requested before that predate it.
class _LikeOverride {
  _LikeOverride({required this.isLiked});

  final bool isLiked;
  int? settledTick;
}
