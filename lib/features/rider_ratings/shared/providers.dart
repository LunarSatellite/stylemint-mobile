import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/data/rider_rating_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/data/rider_rating_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/repositories/rider_rating_repository.dart';

final riderRatingRepositoryProvider = Provider<RiderRatingRepository>(
  (ref) => RiderRatingRepositoryImpl(
    remoteDataSource: RiderRatingRemoteDataSource(
      apiClient: ref.watch(apiClientProvider),
    ),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// The signed-in rider's own rating summary. Best-effort, like the other
/// supplementary cards: null (no card) on a 404 or any failure, swallowed
/// here so Riverpod's automatic retry never hammers an endpoint the backend
/// may not serve yet.
final courierMyRatingProvider = FutureProvider.autoDispose<
  CourierRatingOverview?
>((ref) async {
  final result = await ref.watch(riderRatingRepositoryProvider).myRating();
  return result.fold((_) => null, (overview) => overview);
});

/// The full saved rating (comment, edit window) behind the `{ stars, tags }`
/// an order carries. Null when it cannot be read; the card then shows the
/// brief it already has.
final savedRiderRatingProvider = FutureProvider.autoDispose
    .family<RiderRating?, ({RiderRaterRole role, String subOrderId})>((
      ref,
      key,
    ) async {
      final result = await ref
          .watch(riderRatingRepositoryProvider)
          .rating(role: key.role, subOrderId: key.subOrderId);
      return result.fold((_) => null, (rating) => rating);
    });
