import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';

abstract interface class OnboardingRepository {
  Future<Either<Failure, void>> saveInterests(List<String> categoryIds);
}
