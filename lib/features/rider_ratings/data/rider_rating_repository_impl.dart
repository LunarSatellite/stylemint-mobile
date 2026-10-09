import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/data/rider_rating_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/repositories/rider_rating_repository.dart';

class RiderRatingRepositoryImpl implements RiderRatingRepository {
  RiderRatingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final RiderRatingRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, RiderRating>> rate({
    required RiderRaterRole role,
    required String subOrderId,
    required int stars,
    List<RiderRatingTag> tags = const [],
    String? comment,
  }) => guardedNetworkCall(networkInfo, () async {
    final note = comment?.trim() ?? '';
    final json = await remoteDataSource.putRating(
      role: role,
      subOrderId: subOrderId,
      body: {
        'stars': stars,
        'tags': [for (final tag in tags) tag.wire],
        'comment': note.isEmpty ? null : note,
      },
      idempotencyKey: _uuid.v4(),
    );
    // A 200 whose body is not a rating still saved one: echo what was sent
    // rather than report a failure the buyer would retry.
    return RiderRating.fromJson(json) ??
        RiderRating(
          subOrderId: subOrderId,
          stars: stars,
          tags: tags,
          comment: note.isEmpty ? null : note,
        );
  });

  @override
  Future<Either<NetworkExceptions, RiderRating?>> rating({
    required RiderRaterRole role,
    required String subOrderId,
  }) => guardedNetworkCall(networkInfo, () async {
    final json = await remoteDataSource.getRating(
      role: role,
      subOrderId: subOrderId,
    );
    return json == null ? null : RiderRating.fromJson(json);
  });

  @override
  Future<Either<NetworkExceptions, CourierRatingOverview?>> myRating() =>
      guardedNetworkCall(networkInfo, () async {
        final json = await remoteDataSource.getMyRating();
        return json == null ? null : CourierRatingOverview.fromJson(json);
      });
}
