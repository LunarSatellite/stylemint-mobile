import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum PublishStatus { scheduled, published, failed }

class PublishTarget {
  const PublishTarget({
    required this.id,
    required this.platform,
    required this.scheduledAt,
    this.status = PublishStatus.scheduled,
  });

  final String id;
  final SocialPlatform platform;
  final DateTime scheduledAt;
  final PublishStatus status;

  PublishTarget copyWith({
    String? id,
    SocialPlatform? platform,
    DateTime? scheduledAt,
    PublishStatus? status,
  }) {
    return PublishTarget(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
    );
  }
}

enum BoostStatus { active, paused, completed, rejected }

class BoostCampaign {
  const BoostCampaign({
    required this.id,
    required this.reelId,
    required this.platform,
    required this.budget,
    required this.spentAmount,
    required this.impressions,
    required this.clicks,
    required this.status,
    required this.startedAt,
    this.endAt,
  });

  final String id;
  final String reelId;
  final SocialPlatform platform;
  final Money budget;
  final Money spentAmount;
  final int impressions;
  final int clicks;
  final BoostStatus status;
  final DateTime startedAt;
  final DateTime? endAt;

  BoostCampaign copyWith({
    String? id,
    String? reelId,
    SocialPlatform? platform,
    Money? budget,
    Money? spentAmount,
    int? impressions,
    int? clicks,
    BoostStatus? status,
    DateTime? startedAt,
    DateTime? endAt,
  }) {
    return BoostCampaign(
      id: id ?? this.id,
      reelId: reelId ?? this.reelId,
      platform: platform ?? this.platform,
      budget: budget ?? this.budget,
      spentAmount: spentAmount ?? this.spentAmount,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endAt: endAt ?? this.endAt,
    );
  }
}

class ReachAnalytics {
  const ReachAnalytics({
    required this.totalImpressions,
    required this.totalClicks,
    required this.totalEngagements,
    required this.totalSpent,
    required this.periodStart,
    required this.periodEnd,
  });

  final int totalImpressions;
  final int totalClicks;
  final int totalEngagements;
  final Money totalSpent;
  final DateTime periodStart;
  final DateTime periodEnd;

  ReachAnalytics copyWith({
    int? totalImpressions,
    int? totalClicks,
    int? totalEngagements,
    Money? totalSpent,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    return ReachAnalytics(
      totalImpressions: totalImpressions ?? this.totalImpressions,
      totalClicks: totalClicks ?? this.totalClicks,
      totalEngagements: totalEngagements ?? this.totalEngagements,
      totalSpent: totalSpent ?? this.totalSpent,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }
}
