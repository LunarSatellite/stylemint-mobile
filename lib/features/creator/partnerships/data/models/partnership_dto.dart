import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';

part 'partnership_dto.freezed.dart';
part 'partnership_dto.g.dart';

// PartnershipState: 1=Invited, 2=Declined, 3=Active, 4=Paused, 5=Ended
// Active filter: states=[3,4]  Invites filter: states=[1]

@freezed
abstract class PartnershipDto with _$PartnershipDto {
  const factory PartnershipDto({
    required String id,
    required String vendorProfileId,
    required String creatorProfileId,
    required int state,
    @Default(0.0) double commissionMinPercent,
    @Default(0.0) double commissionMaxPercent,
    required DateTime invitedUtc,
    DateTime? respondedUtc,
    DateTime? endedUtc,
    String? endReason,
    String? requestMessage,
    double? vendorRating,
    String? vendorName,
    String? vendorLogoUrl,
    @Default(false) bool initiatedByCreator,
    String? vendorAccountId,
    required DateTime createdUtc,
    required DateTime updatedUtc,
  }) = _PartnershipDto;

  const PartnershipDto._();

  factory PartnershipDto.fromJson(Map<String, dynamic> json) =>
      _$PartnershipDtoFromJson(json);

  PartnershipInvite toInviteDomain() {
    final status = switch (state) {
      3 => PartnershipStatus.accepted,
      2 => PartnershipStatus.declined,
      _ => PartnershipStatus.pending,
    };
    return PartnershipInvite(
      id: id,
      vendorProfileId: vendorProfileId,
      vendorAccountId: vendorAccountId,
      vendorName: vendorName ?? '',
      vendorLogoUrl: vendorLogoUrl ?? '',
      campaignBrief: requestMessage ?? '',
      commissionRate: commissionMinPercent,
      expiresAt: invitedUtc,
      status: status,
      vendorRating: vendorRating,
    );
  }

  /// Maps only the fields `GET /v1/partnerships` actually returns.
  ///
  /// This used to also set `totalEarned: Money(0)`, `totalSales: 0` and
  /// `productsCount: 0` — constants, not data, which the card then rendered
  /// as "Rs 0" to every creator on the platform. Those fields no longer
  /// exist on [ActivePartnership]; see the doc on
  /// `domain/entities/partnership.dart` for what the backend does and does
  /// not record, and why nothing here can be filled in.
  ActivePartnership toActiveDomain() => ActivePartnership(
    id: id,
    vendorProfileId: vendorProfileId,
    vendorAccountId: vendorAccountId,
    vendorName: vendorName ?? '',
    vendorLogoUrl: vendorLogoUrl ?? '',
    commissionRate: commissionMinPercent,
    startedAt: respondedUtc ?? invitedUtc,
  );

  /// As [toActiveDomain], plus the close. Carried the same two hardcoded
  /// zeros and lost them for the same reason.
  EndedPartnership toEndedDomain() => EndedPartnership(
    id: id,
    vendorName: vendorName ?? '',
    vendorLogoUrl: vendorLogoUrl ?? '',
    commissionRate: commissionMinPercent,
    startedAt: respondedUtc ?? invitedUtc,
    endedAt: endedUtc ?? updatedUtc,
    endReason: endReason,
  );
}
