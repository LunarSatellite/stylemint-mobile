import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/core/usecase/usecase.dart';
import '../entities/reel.dart';
import '../repositories/reels_repository.dart';

/// Use case for fetching the reels feed
class GetReelsFeed implements UseCase<List<Reel>, GetReelsFeedParams> {
  const GetReelsFeed(this._repository);

  final ReelsRepository _repository;

  @override
  Future<Either<Failure, List<Reel>>> call(GetReelsFeedParams params) =>
      _repository.getReelsFeed(
        limit: params.limit,
        cursor: params.cursor,
      );
}

class GetReelsFeedParams {
  const GetReelsFeedParams({
    this.limit = 20,
    this.cursor,
  });

  final int limit;
  final String? cursor;
}
