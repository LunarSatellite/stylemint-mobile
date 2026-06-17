import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/core/usecase/usecase.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/domain/repositories/onboarding_repository.dart';

class SaveInterests implements UseCase<void, SaveInterestsParams> {
  const SaveInterests(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, void>> call(SaveInterestsParams params) =>
      _repository.saveInterests(params.categoryIds);
}

class SaveInterestsParams {
  const SaveInterestsParams({required this.categoryIds});
  final List<String> categoryIds;
}
