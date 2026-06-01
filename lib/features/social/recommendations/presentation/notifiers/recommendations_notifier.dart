import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/domain/entities/recommendation.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/domain/repositories/recommendations_repository.dart';

part 'recommendations_notifier.freezed.dart';

@freezed
abstract class RecommendationsState with _$RecommendationsState {
  const RecommendationsState._();

  const factory RecommendationsState.initial() = _Initial;

  const factory RecommendationsState.requestsLoadInProgress() =
      _RequestsLoadInProgress;

  const factory RecommendationsState.requestsLoadSuccess({
    required List<RecommendationRequest> requests,
    @Default(false) bool hasMore,
    String? nextCursor,
  }) = _RequestsLoadSuccess;

  const factory RecommendationsState.requestsLoadFailure(NetworkExceptions failure) =
      _RequestsLoadFailure;

  const factory RecommendationsState.threadLoadInProgress({
    required List<RecommendationRequest> requests,
    @Default(false) bool hasMore,
    String? nextCursor,
  }) = _ThreadLoadInProgress;

  const factory RecommendationsState.threadLoadSuccess({
    required List<RecommendationRequest> requests,
    @Default(false) bool hasMore,
    String? nextCursor,
    required RecommendationRequest currentRequest,
    required List<RecommendationReply> replies,
  }) = _ThreadLoadSuccess;

  const factory RecommendationsState.threadLoadFailure({
    required List<RecommendationRequest> requests,
    @Default(false) bool hasMore,
    String? nextCursor,
    required NetworkExceptions failure,
  }) = _ThreadLoadFailure;
}

class RecommendationsNotifier extends StateNotifier<RecommendationsState> {
  RecommendationsNotifier(this._repository)
    : super(const RecommendationsState.initial()) {
    unawaited(loadRequests());
  }

  final RecommendationsRepository _repository;

  Future<void> loadRequests({int limit = 20, String? cursor}) async {
    state = const RecommendationsState.requestsLoadInProgress();
    final either = await _repository.getRequests(limit: limit, cursor: cursor);
    state = either.fold(
      RecommendationsState.requestsLoadFailure,
      (result) => RecommendationsState.requestsLoadSuccess(
        requests: result.items,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
      ),
    );
  }

  Future<void> loadThread(String requestId) async {
    final currentState = state;
    final requests =
        currentState.maybeWhen(
          requestsLoadSuccess: (r, _, __) => r,
          threadLoadSuccess: (r, _, __, ___, ____) => r,
          threadLoadInProgress: (r, _, __) => r,
          threadLoadFailure: (r, _, __, _) => r,
          orElse: () => <RecommendationRequest>[],
        );
    final hasMore =
        currentState.maybeWhen(
          requestsLoadSuccess: (_, h, __) => h,
          threadLoadSuccess: (_, h, __, ___, ____) => h,
          orElse: () => false,
        );
    final nextCursor =
        currentState.maybeWhen(
          requestsLoadSuccess: (_, __, n) => n,
          threadLoadSuccess: (_, __, n, ___, ____) => n,
          orElse: () => null,
        );

    state = RecommendationsState.threadLoadInProgress(
      requests: requests,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );

    final either = await _repository.getThread(requestId);

    state = either.fold(
      (f) => RecommendationsState.threadLoadFailure(
        requests: requests,
        hasMore: hasMore,
        nextCursor: nextCursor,
        failure: f,
      ),
      (replies) {
        final request = requests.firstWhere(
          (r) => r.id == requestId,
          orElse: () => RecommendationRequest(
            id: requestId,
            userId: '',
            userName: '',
            userAvatarUrl: '',
            question: '',
            taggedCategories: const [],
            taggedProducts: const [],
            replyCount: replies.length,
            createdAt: DateTime.now(),
          ),
        );
        return RecommendationsState.threadLoadSuccess(
          requests: requests,
          hasMore: hasMore,
          nextCursor: nextCursor,
          currentRequest: request,
          replies: replies,
        );
      },
    );
  }

  Future<void> createRequest({
    required String question,
    String? context,
    List<String>? taggedProducts,
    List<String>? categories,
  }) async {
    final either = await _repository.createRequest(
      question: question,
      context: context,
      taggedProducts: taggedProducts,
      categories: categories,
    );
    either.fold(
      (_) {},
      (_) => loadRequests(),
    );
  }

  Future<void> reply({
    required String requestId,
    required String content,
    String? suggestedProduct,
  }) async {
    final either = await _repository.replyToRequest(
      requestId: requestId,
      content: content,
      suggestedProduct: suggestedProduct,
    );
    either.fold(
      (_) {},
      (_) => loadThread(requestId),
    );
  }

  Future<void> likeReply(String replyId) async {
    await _repository.likeReply(replyId);
    state.maybeWhen(
      threadLoadSuccess: (requests, hasMore, nextCursor, request, replies) {
        final updatedReplies = replies.map((r) {
          if (r.id == replyId) {
            return r.copyWith(likeCount: r.likeCount + 1);
          }
          return r;
        }).toList();
        state = RecommendationsState.threadLoadSuccess(
          requests: requests,
          hasMore: hasMore,
          nextCursor: nextCursor,
          currentRequest: request,
          replies: updatedReplies,
        );
      },
      orElse: () {},
    );
  }
}
