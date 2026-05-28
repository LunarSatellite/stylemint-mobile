import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/core/usecase/usecase.dart';
import '../repositories/reels_repository.dart';

/// Use case for liking a reel
class LikeReel implements UseCase<bool, LikeReelParams> {
  const LikeReel(this._repository);

  final ReelsRepository _repository;

  @override
  Future<Either<Failure, bool>> call(LikeReelParams params) =>
      _repository.likeReel(params.reelId);
}

class LikeReelParams {
  const LikeReelParams({
    required this.reelId,
    String? idempotencyKey,
  }) : idempotencyKey = idempotencyKey ?? const Uuid().v4();

  final String reelId;
  final String idempotencyKey;
}
