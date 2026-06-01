import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';

abstract interface class MatchmakingRepository {
  Future<Either<NetworkExceptions, List<MatchRecommendation>>> getRecommendations({
    MatchmakingFilter? filters,
  });

  Future<Either<NetworkExceptions, int>> getCompatibilityScore(String creatorId);

  Future<Either<NetworkExceptions, Unit>> inviteToCampaign(
    String campaignId,
    String creatorId,
  );
}
