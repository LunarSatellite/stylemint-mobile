import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class VendorPartnershipsRepository {
  Future<Either<NetworkExceptions, PagedResult<VendorPartnership>>>
  getPartnerships({List<PartnershipState>? states, String? cursor});

  /// `totalCount` of pending creator-initiated partnership requests -
  /// dashboard tile count.
  Future<Either<NetworkExceptions, int>> getPendingCreatorRequestCount();

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

  Future<Either<NetworkExceptions, CampaignBrief>> getCampaign(String id);

  Future<Either<NetworkExceptions, CampaignBrief>> lockCampaign(String id);

  Future<Either<NetworkExceptions, CampaignBrief>> forkCampaign(String id);

  Future<Either<NetworkExceptions, CampaignBrief>> retireCampaign(String id);

  Future<Either<NetworkExceptions, RoiProjectionSummary>> recomputeRoi(
    String id,
  );

  Future<Either<NetworkExceptions, List<CreatorInvite>>> searchCreators({
    String? query,
    String? niche,
  });

  /// Send a partnership invite to a creator.
  ///
  /// [creatorAccountId] is the Account.Id returned by the creator-search
  /// picker (`CreatorPickerDto.CreatorAccountId`). It is NOT the creator
  /// profile id - the invite endpoint (`InviteCreatorVm.CreatorProfileId`)
  /// stores the profile id on the partnership aggregate, so this
  /// repository resolves Account.Id -> CreatorProfile.Id before calling
  /// the API. Doing it here keeps the bridge out of every call site.
  Future<Either<NetworkExceptions, void>> inviteCreator({
    required String creatorAccountId,
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? brandBriefId,
    String? message,
  });
}
