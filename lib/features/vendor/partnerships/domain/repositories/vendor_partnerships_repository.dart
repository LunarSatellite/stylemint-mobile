import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class VendorPartnershipsRepository {
  Future<Either<NetworkExceptions, PagedResult<VendorPartnership>>>
  getPartnerships({List<PartnershipState>? states, String? cursor});

  Future<Either<NetworkExceptions, Unit>> acceptRequest(String id);

  Future<Either<NetworkExceptions, Unit>> declineRequest(String id);

  Future<Either<NetworkExceptions, Unit>> pause(String id, {String? reason});

  Future<Either<NetworkExceptions, Unit>> resume(String id);

  Future<Either<NetworkExceptions, Unit>> end(String id, {String? reason});

  Future<Either<NetworkExceptions, Unit>> adjustCommission(
    String id, {
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? reason,
  });

  Future<Either<NetworkExceptions, List<CampaignBrief>>> getCampaigns();

  Future<Either<NetworkExceptions, CampaignBrief>> createCampaign(
    CampaignBrief brief,
  );

  Future<Either<NetworkExceptions, CampaignBrief>> updateCampaign(
    String id,
    CampaignBrief brief,
  );

  Future<Either<NetworkExceptions, List<CreatorInvite>>> searchCreators({
    String? query,
    String? niche,
  });

  Future<Either<NetworkExceptions, void>> inviteCreator({
    required String creatorProfileId,
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? brandBriefId,
    String? message,
  });
}
