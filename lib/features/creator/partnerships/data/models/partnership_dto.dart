import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

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

  ActivePartnership toActiveDomain() => ActivePartnership(
        id: id,
        vendorProfileId: vendorProfileId,
        vendorAccountId: vendorAccountId,
        vendorName: vendorName ?? '',
        vendorLogoUrl: vendorLogoUrl ?? '',
        commissionRate: commissionMinPercent,
        totalEarned: const Money(amount: 0, currency: 'NPR'),
        totalSales: 0,
        startedAt: respondedUtc ?? invitedUtc,
        productsCount: 0,
      );

  EndedPartnership toEndedDomain() => EndedPartnership(
        id: id,
        vendorName: vendorName ?? '',
        vendorLogoUrl: vendorLogoUrl ?? '',
        commissionRate: commissionMinPercent,
        totalEarned: const Money(amount: 0, currency: 'NPR'),
        totalSales: 0,
        startedAt: respondedUtc ?? invitedUtc,
        endedAt: endedUtc ?? updatedUtc,
        productsCount: 0,
        endReason: endReason,
      );
}