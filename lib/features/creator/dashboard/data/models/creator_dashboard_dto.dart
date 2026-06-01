import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'creator_dashboard_dto.freezed.dart';
part 'creator_dashboard_dto.g.dart';

@freezed
abstract class CreatorReelDto with _$CreatorReelDto {
  const factory CreatorReelDto({
    required String id,
    required String platform,
    required String thumbnailUrl,
    required int views,
    required int likes,
    required int comments,
    required int shares,
    required DateTime createdAt,
    required String status,
  }) = _CreatorReelDto;

  const CreatorReelDto._();

  factory CreatorReelDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorReelDtoFromJson(json);

  CreatorReel toDomain() => CreatorReel(
    id: id,
    platform: platform,
    thumbnailUrl: thumbnailUrl,
    views: views,
    likes: likes,
    comments: comments,
    shares: shares,
    createdAt: createdAt,
    status: _statusFromCode(status),
  );

  static CreatorReelStatus _statusFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'active':
        return CreatorReelStatus.active;
      case 'pending':
        return CreatorReelStatus.pending;
      case 'flagged':
        return CreatorReelStatus.flagged;
      default:
        return CreatorReelStatus.pending;
    }
  }
}

@freezed
abstract class CreatorDashboardDto with _$CreatorDashboardDto {
  const factory CreatorDashboardDto({
    required double earnings,
    @Default('NPR') String currency,
    required int totalReels,
    required int totalViews,
    required int totalEngagement,
    required List<CreatorReelDto> recentReels,
    required int activePartnerships,
    required int pendingInvites,
  }) = _CreatorDashboardDto;

  const CreatorDashboardDto._();

  factory CreatorDashboardDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorDashboardDtoFromJson(json);

  CreatorDashboard toDomain() => CreatorDashboard(
    earnings: Money(amount: earnings, currency: currency),
    totalReels: totalReels,
    totalViews: totalViews,
    totalEngagement: totalEngagement,
    recentReels: recentReels.map((r) => r.toDomain()).toList(growable: false),
    activePartnerships: activePartnerships,
    pendingInvites: pendingInvites,
  );
}
