import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/repositories/reviews_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/notifiers/reviews_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/shared/mock_reviews_repository.dart';

// ponytail: using mock — swap MockReviewsRepository with ReviewsRepositoryImpl when API is ready
final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (_) => MockReviewsRepository(),
);

final reviewsNotifierProvider =
    StateNotifierProvider.autoDispose.family<ReviewsNotifier, ReviewsState, String>(
  (ref, productId) => ReviewsNotifier(ref.watch(reviewsRepositoryProvider))
    ..loadReviews(productId),
);

final submitReviewNotifierProvider =
    StateNotifierProvider<SubmitReviewNotifier, SubmitReviewState>(
  (ref) => SubmitReviewNotifier(ref.watch(reviewsRepositoryProvider)),
);
