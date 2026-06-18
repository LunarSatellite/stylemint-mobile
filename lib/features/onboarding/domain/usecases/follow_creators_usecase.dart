import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/core/usecase/usecase.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/domain/repositories/onboarding_repository.dart';

class FollowCreatorsUsecase implements UseCase<void, FollowCreatorsParams> {
  const FollowCreatorsUsecase(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, void>> call(FollowCreatorsParams params) =>
      _repository.followCreators(params.creatorIds);
}

class FollowCreatorsParams {
  const FollowCreatorsParams({required this.creatorIds});
  final List<String> creatorIds;
}
