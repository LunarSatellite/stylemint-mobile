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
  });

  final bool isLoading;
  final bool isPosting;
  final String? errorMessage;
  final List<ReelCommentDto> comments;

  ReelCommentsState copyWith({
    bool? isLoading,
    bool? isPosting,
    String? errorMessage,
    bool clearError = false,
    List<ReelCommentDto>? comments,
  }) {
    return ReelCommentsState(
      isLoading: isLoading ?? this.isLoading,
      isPosting: isPosting ?? this.isPosting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      comments: comments ?? this.comments,
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
      state = state.copyWith(
        isLoading: false,
        comments: comments.isEmpty ? _mockComments() : comments,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, comments: _mockComments());
    }
  }

  static List<ReelCommentDto> _mockComments() {
    final now = DateTime.now();
    return [
      ReelCommentDto(
        id: 'mc1',
        body: 'This should come with a warning 😤',
        likeCount: 234,
        parentCommentId: null,
        createdUtc: now.subtract(const Duration(minutes: 3)),
        authorDisplayName: 'Shree Teen',
        authorAvatarUrl: '',
      ),
      ReelCommentDto(
        id: 'mc2',
        body: 'The texture, the richness, the way this cake looks so soft and indulgent… this is the kind of dessert you think about all day 😋🍰',
        likeCount: 2100,
        parentCommentId: null,
        createdUtc: now.subtract(const Duration(minutes: 47)),
        authorDisplayName: 'lucasSins',
        authorAvatarUrl: '',
      ),
      ReelCommentDto(
        id: 'mc3',
        body: 'I can literally taste this through the screen',
        likeCount: 0,
        parentCommentId: null,
        createdUtc: now.subtract(const Duration(hours: 5)),
        authorDisplayName: 'steviewonders',
        authorAvatarUrl: '',
      ),
      ReelCommentDto(
        id: 'mc4',
        body: 'That slice pull tho 😮',
        likeCount: 3,
        parentCommentId: null,
        createdUtc: now.subtract(const Duration(days: 2)),
        authorDisplayName: 'madmax',
        authorAvatarUrl: '',
      ),
      ReelCommentDto(
        id: 'mc5',
        body: 'Perfect layers, silky frosting, and a finish that looks melt-in-your-mouth good. This is cake done right',
        likeCount: 456,
        parentCommentId: null,
        createdUtc: now.subtract(const Duration(days: 21)),
        authorDisplayName: 'robinsparkles',
        authorAvatarUrl: '',
      ),
    ];
  }

  Future<void> post(String body) async {
    final text = body.trim();
    if (text.isEmpty) return;
    state = state.copyWith(isPosting: true, clearError: true);
    try {
      final created = await _ds.post(_reelId, text);
      state = state.copyWith(
        isPosting: false,
        comments: [created, ...state.comments],
      );
    } catch (_) {
      state = state.copyWith(
          isPosting: false, errorMessage: 'Could not post your comment.');
    }
  }
}

final _reelCommentsDataSourceProvider =
    Provider<ReelCommentsRemoteDataSource>(
  (ref) => ReelCommentsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final reelCommentsControllerProvider = StateNotifierProvider.family
    .autoDispose<ReelCommentsController, ReelCommentsState, String>(
  (ref, reelId) => ReelCommentsController(
      ref.watch(_reelCommentsDataSourceProvider), reelId),
);
