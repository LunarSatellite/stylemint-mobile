import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reel_comments_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/models/reel_comment_dto.dart';

class ReelCommentsState {
  const ReelCommentsState({
    this.isLoading = true,
    this.isPosting = false,
    this.errorMessage,
    this.comments = const [],
    this.likedCommentIds = const {},
    this.likeCounts = const {},
  });

  final bool isLoading;
  final bool isPosting;
  final String? errorMessage;
  final List<ReelCommentDto> comments;
  final Set<String> likedCommentIds;
  final Map<String, int> likeCounts;

  ReelCommentsState copyWith({
    bool? isLoading,
    bool? isPosting,
    String? errorMessage,
    bool clearError = false,
    List<ReelCommentDto>? comments,
    Set<String>? likedCommentIds,
    Map<String, int>? likeCounts,
  }) {
    return ReelCommentsState(
      isLoading: isLoading ?? this.isLoading,
      isPosting: isPosting ?? this.isPosting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      comments: comments ?? this.comments,
      likedCommentIds: likedCommentIds ?? this.likedCommentIds,
      likeCounts: likeCounts ?? this.likeCounts,
    );
  }
}

class ReelCommentsController extends StateNotifier<ReelCommentsState> {
  ReelCommentsController(this._ds, this._reelId)
    : super(const ReelCommentsState()) {
    load();
  }

  final ReelCommentsRemoteDataSource _ds;
  final String _reelId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final comments = await _ds.list(_reelId);
      // The provider is autoDispose, so the last UI listener may have
      // gone away while the request was in flight. Writing to `state`
      // after `dispose()` throws "Tried to use ReelCommentsController
      // after dispose was called."
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        comments: comments,
        likedCommentIds: comments
            .where((comment) => comment.isLikedByCurrentAccount)
            .map((comment) => comment.id)
            .toSet(),
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        comments: const [],
        errorMessage: 'Could not load comments.',
      );
    }
  }

  /// Returns whether the post succeeded — callers use this instead of
  /// inferring success from [state] (same reasoning as [CartNotifier.addItem]:
  /// re-reading ambient state after an await is racy under rapid taps, and
  /// here it's also the only way for the reel action rail's comment-count
  /// badge to know a post landed, since that badge reads a frozen
  /// [Reel.commentCount] snapshot that nothing else refreshes).
  Future<bool> post(String body) async {
    final text = body.trim();
    if (text.isEmpty) return false;
    state = state.copyWith(isPosting: true, clearError: true);
    try {
      final created = await _ds.post(_reelId, text);
      // See note in load() -- autoDispose means the notifier can be
      // torn down between the post request and our state update.
      if (!mounted) return true;
      state = state.copyWith(
        isPosting: false,
        comments: [created, ...state.comments],
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isPosting: false,
        errorMessage: 'Could not post your comment.',
      );
      return false;
    }
  }

  /// Optimistically persists a comment like/unlike and restores the exact
  /// prior UI state if the authenticated backend mutation fails.
  Future<void> toggleLike(String commentId) async {
    ReelCommentDto? comment;
    for (final item in state.comments) {
      if (item.id == commentId) {
        comment = item;
        break;
      }
    }
    if (comment == null) return;
    final selectedComment = comment;

    final priorLiked = Set<String>.from(state.likedCommentIds);
    final priorCounts = Map<String, int>.from(state.likeCounts);
    final wasLiked = priorLiked.contains(commentId);
    final currentCount = priorCounts[commentId] ?? selectedComment.likeCount;
    final liked = Set<String>.from(priorLiked);
    final counts = Map<String, int>.from(priorCounts);
    if (wasLiked) {
      liked.remove(commentId);
      counts[commentId] = currentCount > 0 ? currentCount - 1 : 0;
    } else {
      liked.add(commentId);
      counts[commentId] = currentCount + 1;
    }
    state = state.copyWith(
      likedCommentIds: liked,
      likeCounts: counts,
      clearError: true,
    );

    try {
      if (wasLiked) {
        await _ds.unlike(_reelId, commentId);
      } else {
        await _ds.like(_reelId, commentId);
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        likedCommentIds: priorLiked,
        likeCounts: priorCounts,
        errorMessage: 'Could not update your like. Please try again.',
      );
    }
  }
}

final _reelCommentsDataSourceProvider = Provider<ReelCommentsRemoteDataSource>(
  (ref) =>
      ReelCommentsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final reelCommentsControllerProvider = StateNotifierProvider.family
    .autoDispose<ReelCommentsController, ReelCommentsState, String>(
      (ref, reelId) => ReelCommentsController(
        ref.watch(_reelCommentsDataSourceProvider),
        reelId,
      ),
    );
