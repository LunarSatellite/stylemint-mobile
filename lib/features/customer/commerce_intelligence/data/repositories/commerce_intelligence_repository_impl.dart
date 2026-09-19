import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/data/datasources/commerce_intelligence_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/data/models/evidence_answer_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/entities/evidence_answer.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/repositories/commerce_intelligence_repository.dart';

class CommerceIntelligenceRepositoryImpl
    implements CommerceIntelligenceRepository {
  CommerceIntelligenceRepositoryImpl({required this.remoteDataSource});

  final CommerceIntelligenceRemoteDataSource remoteDataSource;

  /// The server's own limit, applied here so a question that cannot succeed
  /// never becomes a round trip.
  static const int maxQueryLength = 500;

  @override
  Future<Either<NetworkExceptions, EvidenceAnswer>> answer({
    required String query,
    DateTime? asOfUtc,
    int evidenceLimit =
        CommerceIntelligenceRemoteDataSource.defaultEvidenceLimit,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return left(
        const NetworkExceptions.validation(
          code: 'validation.required',
          message: 'Type a question first.',
        ),
      );
    }
    if (trimmed.length > maxQueryLength) {
      return left(
        const NetworkExceptions.validation(
          code: 'validation.too_long',
          message: 'Questions can be up to $maxQueryLength characters.',
        ),
      );
    }
    try {
      return right(
        evidenceAnswerFromJson(
          await remoteDataSource.answer(
            query: trimmed,
            asOfUtc: asOfUtc,
            evidenceLimit: evidenceLimit,
          ),
        ),
      );
    } on DioException catch (e) {
      return left(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
