import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/domain/entities/recommendation.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class RecommendationsRepository {
  Future<Either<NetworkExceptions, PagedResult<RecommendationRequest>>> getRequests({
    int limit = 20,
    String? cursor,
  });

  Future<Either<NetworkExceptions, List<RecommendationReply>>> getThread(
    String requestId,
  );

  Future<Either<NetworkExceptions, RecommendationRequest>> createRequest({
    required String question,
    String? context,
    List<String>? taggedProducts,
    List<String>? categories,
  });

  Future<Either<NetworkExceptions, RecommendationReply>> replyToRequest({
    required String requestId,
    required String content,
    String? suggestedProduct,
  });

  Future<Either<NetworkExceptions, Unit>> likeReply(String replyId);
}
