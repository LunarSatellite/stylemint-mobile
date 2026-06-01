import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/repositories/reviews_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

part 'reviews_notifier.freezed.dart';

@freezed
abstract class ReviewsState with _$ReviewsState {
  const ReviewsState._();

  const factory ReviewsState.initial() = _ReviewsInitial;
  const factory ReviewsState.loadInProgress() = _ReviewsLoadInProgress;
  const factory ReviewsState.loadSuccess({
    required List<Review> reviews,
    required ReviewSummary summary,
    required bool hasMore,
    String? nextCursor,
  }) = _ReviewsLoadSuccess;
  const factory ReviewsState.loadFailure(NetworkExceptions failure) = _ReviewsLoadFailure;
}

@freezed
abstract class SubmitReviewState with _$SubmitReviewState {
  const SubmitReviewState._();

  const factory SubmitReviewState.initial() = _SubmitInitial;
  const factory SubmitReviewState.submitting() = _SubmitSubmitting;
  const factory SubmitReviewState.success(Review review) = _SubmitSuccess;
  const factory SubmitReviewState.failure(NetworkExceptions failure) = _SubmitFailure;
}

class ReviewsNotifier extends StateNotifier<ReviewsState> {
  ReviewsNotifier(this._repository) : super(const ReviewsState.initial());

  final ReviewsRepository _repository;

  String? _productId;
  String? _nextCursor;

  Future<void> loadReviews(String productId) async {
    _productId = productId;
    _nextCursor = null;
    state = const ReviewsState.loadInProgress();

    await _fetchPage(productId, isRefresh: true);
  }

  Future<void> loadMore() async {
    final pid = _productId;
    if (pid == null || _nextCursor == null) return;

    state.maybeWhen(
      loadSuccess: (reviews, summary, hasMore, nextCursor) {
        state = ReviewsState.loadSuccess(
          reviews: reviews,
          summary: summary,
          hasMore: hasMore,
          nextCursor: nextCursor,
        );
      },
      orElse: () {},
    );

    await _fetchPage(pid, isRefresh: false);
  }

  Future<void> _fetchPage(String productId, {required bool isRefresh}) async {
    final results = await Future.wait([
      _repository.getReviewSummary(productId),
      _repository.getProductReviews(productId, cursor: _nextCursor),
    ]);

    final summaryEither = results[0] as Either<NetworkExceptions, ReviewSummary>;
    final reviewsEither = results[1] as Either<NetworkExceptions, PagedResult<Review>>;

    if (isRefresh && summaryEither.isRight() && reviewsEither.isRight()) {
      final summary = (summaryEither as Right<NetworkExceptions, ReviewSummary>).value;
      final paged = (reviewsEither as Right<NetworkExceptions, PagedResult<Review>>).value;
      _nextCursor = paged.nextCursor;
      state = ReviewsState.loadSuccess(
        reviews: paged.items,
        summary: summary,
        hasMore: paged.hasMore,
        nextCursor: paged.nextCursor,
      );
    } else if (!isRefresh) {
      final existingReviews = state.maybeWhen(
        loadSuccess: (reviews, summary, _, __) => (reviews, summary),
        orElse: () => (<Review>[], ReviewSummary(averageRating: 0, totalReviews: 0, ratingDistribution: {})),
      );

      if (reviewsEither.isRight()) {
        final paged = (reviewsEither as Right<NetworkExceptions, PagedResult<Review>>).value;
        _nextCursor = paged.nextCursor;
        state = ReviewsState.loadSuccess(
          reviews: [...existingReviews.$1, ...paged.items],
          summary: existingReviews.$2,
          hasMore: paged.hasMore,
          nextCursor: paged.nextCursor,
        );
      }
    } else if (reviewsEither.isLeft()) {
      state = ReviewsState.loadFailure((reviewsEither as Left<NetworkExceptions, PagedResult<Review>>).value);
    }
  }

  Future<void> refresh() {
    final pid = _productId;
    if (pid == null) return Future.value();
    return loadReviews(pid);
  }
}

class SubmitReviewNotifier extends StateNotifier<SubmitReviewState> {
  SubmitReviewNotifier(this._repository) : super(const SubmitReviewState.initial());

  final ReviewsRepository _repository;

  Future<void> submitReview({
    required String productId,
    required int rating,
    required String comment,
    List<String>? imagePaths,
  }) async {
    state = const SubmitReviewState.submitting();
    final either = await _repository.submitReview(
      productId,
      rating,
      comment,
      imagePaths: imagePaths,
    );
    state = either.fold(
      SubmitReviewState.failure,
      SubmitReviewState.success,
    );
  }

  void reset() => state = const SubmitReviewState.initial();
}
