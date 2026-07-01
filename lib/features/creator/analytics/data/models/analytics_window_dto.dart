import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/analytics_window.dart';

part 'analytics_window_dto.freezed.dart';
part 'analytics_window_dto.g.dart';

@freezed
abstract class AnalyticsWindowDto with _$AnalyticsWindowDto {
  const factory AnalyticsWindowDto({
    required DateTime fromUtc,
    required DateTime toUtc,
    @Default(30) int durationDays,
  }) = _AnalyticsWindowDto;

  const AnalyticsWindowDto._();

  factory AnalyticsWindowDto.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsWindowDtoFromJson(json);

  AnalyticsWindow toDomain() => AnalyticsWindow(
    fromUtc: fromUtc,
    toUtc: toUtc,
    durationDays: durationDays,
  );
}
