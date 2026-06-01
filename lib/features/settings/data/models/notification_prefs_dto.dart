import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';

part 'notification_prefs_dto.freezed.dart';
part 'notification_prefs_dto.g.dart';

@freezed
abstract class NotificationPreferencesDto with _$NotificationPreferencesDto {
  const factory NotificationPreferencesDto({
    @Default(true) bool pushEnabled,
    @Default(false) bool emailEnabled,
    @Default(true) bool orderUpdates,
    @Default(true) bool promotional,
    @Default(false) bool reelLikes,
    @Default(false) bool newFollowers,
    @Default(false) bool quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) = _NotificationPreferencesDto;

  const NotificationPreferencesDto._();

  factory NotificationPreferencesDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesDtoFromJson(json);

  NotificationPreferences toDomain() => NotificationPreferences(
    pushEnabled: pushEnabled,
    emailEnabled: emailEnabled,
    orderUpdates: orderUpdates,
    promotional: promotional,
    reelLikes: reelLikes,
    newFollowers: newFollowers,
    quietHoursEnabled: quietHoursEnabled,
    quietHoursStart: quietHoursStart,
    quietHoursEnd: quietHoursEnd,
  );
}
