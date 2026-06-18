import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/models/creator_dto.dart';

abstract interface class OnboardingRepository {
  Future<Either<Failure, void>> saveInterests(List<String> categoryIds);
  Future<Either<Failure, List<CreatorDto>>> fetchCreators();
  Future<Either<Failure, void>> followCreators(List<String> creatorIds);
}
