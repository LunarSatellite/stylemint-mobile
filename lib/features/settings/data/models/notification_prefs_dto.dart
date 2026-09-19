import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';

/// Mirrors the backend Identity module's `NotificationPreferencesDto` — a
/// flat Email/Push/Sms x category shape (Security, OrderUpdates,
/// DeliveryUpdates, Messages, ReelActivity, FriendActivity, Marketing,
/// SystemAnnouncements). See `NotificationPreferencesDto.cs` /
/// `UpdateNotificationTogglesVm.cs` / `UpdateQuietHoursVm.cs` in the Identity
/// module for the authoritative shapes.
class NotificationPreferencesDto {
  const NotificationPreferencesDto({
    required this.emailEnabledMaster,
    required this.pushEnabledMaster,
    required this.smsEnabledMaster,
    required this.emailOrderUpdates,
    required this.pushOrderUpdates,
    required this.emailDeliveryUpdates,
    required this.pushDeliveryUpdates,
    required this.emailReelActivity,
    required this.pushReelActivity,
    required this.emailFriendActivity,
    required this.pushFriendActivity,
    required this.emailMarketing,
    required this.pushMarketing,
    required this.emailSystemAnnouncements,
    required this.pushSystemAnnouncements,
    required this.quietHoursEnabled,
    required this.quietHoursStartLocal,
    required this.quietHoursEndLocal,
  });

  final bool emailEnabledMaster;
  final bool pushEnabledMaster;
  final bool smsEnabledMaster;
  final bool emailOrderUpdates;
  final bool pushOrderUpdates;
  final bool emailDeliveryUpdates;
  final bool pushDeliveryUpdates;
  final bool emailReelActivity;
  final bool pushReelActivity;
  final bool emailFriendActivity;
  final bool pushFriendActivity;
  final bool emailMarketing;
  final bool pushMarketing;
  final bool emailSystemAnnouncements;
  final bool pushSystemAnnouncements;
  final bool quietHoursEnabled;

  /// "HH:mm:ss" — backend `TimeOnly`.
  final String quietHoursStartLocal;
  final String quietHoursEndLocal;

  factory NotificationPreferencesDto.fromJson(Map<String, dynamic> json) =>
      NotificationPreferencesDto(
        emailEnabledMaster: json['emailEnabledMaster'] as bool? ?? true,
        pushEnabledMaster: json['pushEnabledMaster'] as bool? ?? true,
        smsEnabledMaster: json['smsEnabledMaster'] as bool? ?? false,
        emailOrderUpdates: json['emailOrderUpdates'] as bool? ?? true,
        pushOrderUpdates: json['pushOrderUpdates'] as bool? ?? true,
        emailDeliveryUpdates: json['emailDeliveryUpdates'] as bool? ?? true,
        pushDeliveryUpdates: json['pushDeliveryUpdates'] as bool? ?? true,
        emailReelActivity: json['emailReelActivity'] as bool? ?? false,
        pushReelActivity: json['pushReelActivity'] as bool? ?? false,
        emailFriendActivity: json['emailFriendActivity'] as bool? ?? false,
        pushFriendActivity: json['pushFriendActivity'] as bool? ?? false,
        emailMarketing: json['emailMarketing'] as bool? ?? true,
        pushMarketing: json['pushMarketing'] as bool? ?? true,
        emailSystemAnnouncements:
            json['emailSystemAnnouncements'] as bool? ?? true,
        pushSystemAnnouncements:
            json['pushSystemAnnouncements'] as bool? ?? true,
        quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
        quietHoursStartLocal:
            json['quietHoursStartLocal'] as String? ?? '22:00:00',
        quietHoursEndLocal: json['quietHoursEndLocal'] as String? ?? '08:00:00',
      );

  /// Body for `PATCH .../notification-preferences/toggles`
  /// (`UpdateNotificationTogglesVm`).
  ///
  /// Every property on that VM is nullable and an omitted key means "leave it
  /// alone", so only the columns this app actually renders a control for are
  /// sent. `email/pushMessages` are omitted on purpose: the Messages rollup
  /// gates partnership invites, which this screen has no control over, and
  /// sending a value for it would silently rewrite a setting nobody touched.
  Map<String, dynamic> toJson() => {
    'pushEnabledMaster': pushEnabledMaster,
    'emailEnabledMaster': emailEnabledMaster,
    'smsEnabledMaster': smsEnabledMaster,
    'emailOrderUpdates': emailOrderUpdates,
    'pushOrderUpdates': pushOrderUpdates,
    'emailDeliveryUpdates': emailDeliveryUpdates,
    'pushDeliveryUpdates': pushDeliveryUpdates,
    'emailReelActivity': emailReelActivity,
    'pushReelActivity': pushReelActivity,
    'emailFriendActivity': emailFriendActivity,
    'pushFriendActivity': pushFriendActivity,
    'emailMarketing': emailMarketing,
    'pushMarketing': pushMarketing,
    'emailSystemAnnouncements': emailSystemAnnouncements,
    'pushSystemAnnouncements': pushSystemAnnouncements,
  };

  static String _hhmm(String hhmmss) =>
      hhmmss.length >= 5 ? hhmmss.substring(0, 5) : hhmmss;

  static String hhmmss(String hhmm) => hhmm.length == 5 ? '$hhmm:00' : hhmm;

  /// Every field below is a straight read of one backend column — no two
  /// domain fields share a column, so what the screen shows after a load is
  /// exactly what the server stores.
  NotificationPreferences toDomain() => NotificationPreferences(
    pushEnabled: pushEnabledMaster,
    emailNotifications: emailEnabledMaster,
    smsNotifications: smsEnabledMaster,
    orderStatusChanges: pushOrderUpdates,
    deliveryUpdates: pushDeliveryUpdates,
    newReelsFromCreators: pushReelActivity,
    newFollowers: pushFriendActivity,
    paymentUpdates: pushSystemAnnouncements,
    marketingPush: pushMarketing,
    newsletter: emailMarketing,
    quietHoursEnabled: quietHoursEnabled,
    quietHoursStart: _hhmm(quietHoursStartLocal),
    quietHoursEnd: _hhmm(quietHoursEndLocal),
  );

  /// Exact inverse of [toDomain]: one domain field in, one column out. The
  /// email twin of each push category follows its push switch so the two
  /// channels stay consistent, except Marketing, where email (newsletter) and
  /// push are separately controlled and separately stored.
  static NotificationPreferencesDto fromDomain(NotificationPreferences p) =>
      NotificationPreferencesDto(
        pushEnabledMaster: p.pushEnabled,
        emailEnabledMaster: p.emailNotifications,
        smsEnabledMaster: p.smsNotifications,
        emailOrderUpdates: p.orderStatusChanges,
        pushOrderUpdates: p.orderStatusChanges,
        emailDeliveryUpdates: p.deliveryUpdates,
        pushDeliveryUpdates: p.deliveryUpdates,
        emailReelActivity: p.newReelsFromCreators,
        pushReelActivity: p.newReelsFromCreators,
        emailFriendActivity: p.newFollowers,
        pushFriendActivity: p.newFollowers,
        emailMarketing: p.newsletter,
        pushMarketing: p.marketingPush,
        emailSystemAnnouncements: p.paymentUpdates,
        pushSystemAnnouncements: p.paymentUpdates,
        quietHoursEnabled: p.quietHoursEnabled,
        quietHoursStartLocal: hhmmss(p.quietHoursStart ?? '22:00'),
        quietHoursEndLocal: hhmmss(p.quietHoursEnd ?? '08:00'),
      );
}
