import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';

/// Rating the StyleMint rider who carried a parcel, and a rider reading what
/// they were rated. One repository for buyer, vendor and rider: the calls
/// differ only by the role in the path.
abstract interface class RiderRatingRepository {
  /// Saves (or replaces) [role]'s rating of the rider on [subOrderId]. Mints
  /// its own Idempotency-Key.
  Future<Either<NetworkExceptions, RiderRating>> rate({
    required RiderRaterRole role,
    required String subOrderId,
    required int stars,
    List<RiderRatingTag> tags = const [],
    String? comment,
  });

  /// [role]'s rating on [subOrderId], or null when none was given.
  Future<Either<NetworkExceptions, RiderRating?>> rating({
    required RiderRaterRole role,
    required String subOrderId,
  });

  /// The signed-in rider's own ratings, or null when the server has none to
  /// report (or does not serve them yet).
  Future<Either<NetworkExceptions, CourierRatingOverview?>> myRating();
}
