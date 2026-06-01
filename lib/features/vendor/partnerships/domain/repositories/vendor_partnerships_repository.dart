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
    List<String>? categories,
  });

  Future<Either<NetworkExceptions, CreatorInvite>> inviteCreator(
    String campaignId,
    String creatorId,
  );

  Future<Either<NetworkExceptions, List<CreatorInvite>>> getInvites(String campaignId);
}
