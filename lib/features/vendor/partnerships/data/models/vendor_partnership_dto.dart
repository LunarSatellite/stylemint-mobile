import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_partnership_dto.freezed.dart';
part 'vendor_partnership_dto.g.dart';

@freezed
abstract class CampaignBriefDto with _$CampaignBriefDto {
  const factory CampaignBriefDto({
    required String id,
    required String title,
    required String description,
    required double commissionRate,
    required double budgetAmount,
    @Default('NPR') String budgetCurrency,
    required DateTime startDate,
    DateTime? endDate,
    @Default(0) int targetCreators,
    @Default([]) List<String> requiredCategories,
    @Default('draft') String status,
    required DateTime createdAt,
  }) = _CampaignBriefDto;

  const CampaignBriefDto._();

  factory CampaignBriefDto.fromJson(Map<String, dynamic> json) =>
      _$CampaignBriefDtoFromJson(json);

  CampaignBrief toDomain() {
    final statusEnum = CampaignStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => CampaignStatus.draft,
    );
    return CampaignBrief(
      id: id,
      title: title,
      description: description,
      commissionRate: commissionRate,
      budget: Money(amount: budgetAmount, currency: budgetCurrency),
      startDate: startDate,
      endDate: endDate,
      targetCreators: targetCreators,
      requiredCategories: requiredCategories,
      status: statusEnum,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toRequest() => {
    'title': title,
    'description': description,
    'commissionRate': commissionRate,
    'budgetAmount': budgetAmount,
    'budgetCurrency': budgetCurrency,
    'startDate': startDate.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    'targetCreators': targetCreators,
    'requiredCategories': requiredCategories,
  };
}

@freezed
abstract class CreatorInviteDto with _$CreatorInviteDto {
  const factory CreatorInviteDto({
    required String id,
    required String campaignId,
    required String creatorId,
    required String creatorName,
    required String creatorAvatarUrl,
    required String creatorHandle,
    required String creatorCategory,
    @Default(0) int followersCount,
    @Default('pending') String status,
    required DateTime invitedAt,
  }) = _CreatorInviteDto;

  const CreatorInviteDto._();

  factory CreatorInviteDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorInviteDtoFromJson(json);

  CreatorInvite toDomain() {
    final statusEnum = InviteStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => InviteStatus.pending,
    );
    return CreatorInvite(
      id: id,
      campaignId: campaignId,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
      creatorHandle: creatorHandle,
      creatorCategory: creatorCategory,
      followersCount: followersCount,
      status: statusEnum,
      invitedAt: invitedAt,
    );
  }
}
