import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/entities/reach.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

abstract interface class ReachRepository {
  Future<Either<NetworkExceptions, List<PublishTarget>>> getPublishTargets();

  Future<Either<NetworkExceptions, Unit>> schedulePublish({
    required String draftId,
    required List<String> platformNames,
    required DateTime scheduledAt,
  });

  Future<Either<NetworkExceptions, List<BoostCampaign>>> getBoostCampaigns();

  Future<Either<NetworkExceptions, BoostCampaign>> createBoostCampaign({
    required String reelId,
    required String platform,
    required Money budget,
    required int durationDays,
  });

  Future<Either<NetworkExceptions, ReachAnalytics>> getAnalytics({
    DateTime? periodStart,
    DateTime? periodEnd,
  });
}
