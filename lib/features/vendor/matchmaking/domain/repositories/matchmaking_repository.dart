import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class MatchmakingRepository {
  Future<Either<NetworkExceptions, PagedResult<MatchRecommendation>>>
  getRecommendations({required int pageSize, String? cursor});

  Future<Either<NetworkExceptions, PartnershipPrefill>> invite(String matchId);

  Future<Either<NetworkExceptions, Unit>> dismissMatch(String matchId);
}
