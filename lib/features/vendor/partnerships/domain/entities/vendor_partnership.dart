import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum CampaignStatus { draft, active, paused, completed }

class CampaignBrief {
  const CampaignBrief({
    required this.id,
    required this.title,
    required this.description,
    required this.commissionRate,
    required this.budget,
    required this.startDate,
    this.endDate,
    this.targetCreators = 0,
    this.requiredCategories = const <String>[],
    this.status = CampaignStatus.draft,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final double commissionRate;
  final Money budget;
  final DateTime startDate;
  final DateTime? endDate;
  final int targetCreators;
  final List<String> requiredCategories;
  final CampaignStatus status;
  final DateTime createdAt;

  CampaignBrief copyWith({
    String? id,
    String? title,
    String? description,
    double? commissionRate,
    Money? budget,
    DateTime? startDate,
    DateTime? endDate,
    int? targetCreators,
    List<String>? requiredCategories,
    CampaignStatus? status,
    DateTime? createdAt,
  }) {
    return CampaignBrief(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      commissionRate: commissionRate ?? this.commissionRate,
      budget: budget ?? this.budget,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetCreators: targetCreators ?? this.targetCreators,
      requiredCategories: requiredCategories ?? this.requiredCategories,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum InviteStatus { pending, accepted, declined, expired }

class CreatorInvite {
  const CreatorInvite({
    required this.id,
    required this.campaignId,
    required this.creatorId,
    required this.creatorName,
    required this.creatorAvatarUrl,
    required this.creatorHandle,
    required this.creatorCategory,
    this.followersCount = 0,
    this.status = InviteStatus.pending,
    required this.invitedAt,
  });

  final String id;
  final String campaignId;
  final String creatorId;
  final String creatorName;
  final String creatorAvatarUrl;
  final String creatorHandle;
  final String creatorCategory;
  final int followersCount;
  final InviteStatus status;
  final DateTime invitedAt;

  CreatorInvite copyWith({
    String? id,
    String? campaignId,
    String? creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
    String? creatorHandle,
    String? creatorCategory,
    int? followersCount,
    InviteStatus? status,
    DateTime? invitedAt,
  }) {
    return CreatorInvite(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      creatorHandle: creatorHandle ?? this.creatorHandle,
      creatorCategory: creatorCategory ?? this.creatorCategory,
      followersCount: followersCount ?? this.followersCount,
      status: status ?? this.status,
      invitedAt: invitedAt ?? this.invitedAt,
    );
  }
}
