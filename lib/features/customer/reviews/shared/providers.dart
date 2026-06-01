import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/data/datasources/reviews_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/data/repositories/reviews_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/repositories/reviews_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/notifiers/reviews_notifier.dart';

final reviewsRemoteDataSourceProvider = Provider<ReviewsRemoteDataSource>(
  (ref) => ReviewsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepositoryImpl(
    remoteDataSource: ref.watch(reviewsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
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
