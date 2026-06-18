import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/core/usecase/usecase.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/models/creator_dto.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/domain/repositories/onboarding_repository.dart';

class FetchCreators implements UseCase<List<CreatorDto>, NoParams> {
  const FetchCreators(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, List<CreatorDto>>> call(NoParams params) =>
      _repository.fetchCreators();
}
