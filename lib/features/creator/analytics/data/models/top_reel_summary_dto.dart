import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/money_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reel_summary.dart';

part 'top_reel_summary_dto.freezed.dart';
part 'top_reel_summary_dto.g.dart';

@freezed
abstract class TopReelSummaryDto with _$TopReelSummaryDto {
  const factory TopReelSummaryDto({
    required String reelId,
    required DateTime publishedAtUtc,
    required MoneyDto earnings,
    @Default('') String title,
    @Default('') String thumbnailUrl,
    @Default(0) int views,
    @Default(0) int likes,
    @Default(0) int impressions,
    @Default(0) int shares,
    @Default(0) int comments,
    @Default(0) int sales,
  }) = _TopReelSummaryDto;

  const TopReelSummaryDto._();

  factory TopReelSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$TopReelSummaryDtoFromJson(json);

  TopReelSummary toDomain() => TopReelSummary(
    reelId: reelId,
    title: title,
    thumbnailUrl: thumbnailUrl,
    publishedAtUtc: publishedAtUtc,
    views: views,
    likes: likes,
    impressions: impressions,
    shares: shares,
    comments: comments,
    sales: sales,
    earnings: earnings.toDomain(),
  );
}
