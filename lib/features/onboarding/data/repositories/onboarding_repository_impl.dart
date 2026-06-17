import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._datasource);
  final OnboardingRemoteDatasource _datasource;

  @override
  Future<Either<Failure, void>> saveInterests(List<String> categoryIds) async {
    try {
      await _datasource.saveInterests(categoryIds);
      return right(null);
    } catch (e) {
      return left(_mapError(e));
    }
  }

  Failure _mapError(dynamic e) {
    if (e is DioException) {
      final status = e.response?.statusCode ?? 0;
      if (status == 401 || status == 403) return const Failure.auth();
      if (status == 400 || status == 422) {
        return const Failure.validation(code: 'INVALID_INTERESTS');
      }
      if (status >= 500) return const Failure.server();
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return const Failure.network();
      }
    }
    return const Failure.unknown();
  }
}
