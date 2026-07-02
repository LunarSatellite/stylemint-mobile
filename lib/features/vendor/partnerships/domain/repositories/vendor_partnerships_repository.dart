import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';

abstract interface class VendorPartnershipsRepository {
  Future<Either<NetworkExceptions, List<CampaignBrief>>> getCampaigns();

  Future<Either<NetworkExceptions, CampaignBrief>> createCampaign(CampaignBrief brief);

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
