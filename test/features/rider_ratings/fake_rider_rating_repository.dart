import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/repositories/rider_rating_repository.dart';

/// Answers from fields and records what was sent.
class FakeRiderRatingRepository implements RiderRatingRepository {
  Either<NetworkExceptions, RiderRating>? rateResult;
  Either<NetworkExceptions, RiderRating?> saved = right(null);
  Either<NetworkExceptions, CourierRatingOverview?> mine = right(null);

  final List<
    ({
      RiderRaterRole role,
      String subOrderId,
      int stars,
      List<RiderRatingTag> tags,
      String? comment,
    })
  >
  rated = [];

  @override
  Future<Either<NetworkExceptions, RiderRating>> rate({
    required RiderRaterRole role,
    required String subOrderId,
    required int stars,
    List<RiderRatingTag> tags = const [],
    String? comment,
  }) async {
    rated.add((
      role: role,
      subOrderId: subOrderId,
      stars: stars,
      tags: tags,
      comment: comment,
    ));
    return rateResult ??
        right(
          RiderRating(
            subOrderId: subOrderId,
            stars: stars,
            tags: tags,
            comment: comment == null || comment.trim().isEmpty
                ? null
                : comment.trim(),
            editableUntilUtc: DateTime.now().toUtc().add(
              const Duration(days: 7),
            ),
          ),
        );
  }

  @override
  Future<Either<NetworkExceptions, RiderRating?>> rating({
    required RiderRaterRole role,
    required String subOrderId,
  }) async => saved;

  @override
  Future<Either<NetworkExceptions, CourierRatingOverview?>> myRating() async =>
      mine;
}
