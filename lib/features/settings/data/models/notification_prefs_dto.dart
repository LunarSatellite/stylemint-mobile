import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';

/// Mirrors the backend Identity module's `NotificationPreferencesDto` — a
/// flat Email/Push/Sms x category shape (Security, OrderUpdates,
/// DeliveryUpdates, Messages, ReelActivity, FriendActivity, Marketing,
/// SystemAnnouncements), NOT the nested `{toggles, quietHours}` shape this
/// file used to declare. That nested shape, and its priceDrops/backInStock/
/// newArrivals/etc field names, don't exist anywhere in the backend — every
/// save silently sent a payload the `UpdateNotificationTogglesVm` model
/// binder couldn't match a single field of, and every load crashed parsing
/// a `toggles` key the response never had. See
/// `NotificationPreferencesDto.cs` / `UpdateNotificationTogglesVm.cs` in the
/// Identity module for the authoritative shape.
class NotificationPreferencesDto {
  const NotificationPreferencesDto({
    required this.emailEnabledMaster,
    required this.pushEnabledMaster,
    required this.smsEnabledMaster,
    required this.emailSecurity,
    required this.pushSecurity,
    required this.emailOrderUpdates,
    required this.pushOrderUpdates,
    required this.emailDeliveryUpdates,
    required this.pushDeliveryUpdates,
    required this.emailMessages,
    required this.pushMessages,
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
  final bool emailSecurity;
  final bool pushSecurity;
  final bool emailOrderUpdates;
  final bool pushOrderUpdates;
  final bool emailDeliveryUpdates;
  final bool pushDeliveryUpdates;
  final bool emailMessages;
  final bool pushMessages;
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
        emailSecurity: json['emailSecurity'] as bool? ?? true,
        pushSecurity: json['pushSecurity'] as bool? ?? true,
        emailOrderUpdates: json['emailOrderUpdates'] as bool? ?? true,
        pushOrderUpdates: json['pushOrderUpdates'] as bool? ?? true,
        emailDeliveryUpdates: json['emailDeliveryUpdates'] as bool? ?? true,
        pushDeliveryUpdates: json['pushDeliveryUpdates'] as bool? ?? true,
        emailMessages: json['emailMessages'] as bool? ?? true,
        pushMessages: json['pushMessages'] as bool? ?? true,
        emailReelActivity: json['emailReelActivity'] as bool? ?? false,
        pushReelActivity: json['pushReelActivity'] as bool? ?? false,
        emailFriendActivity: json['emailFriendActivity'] as bool? ?? false,
        pushFriendActivity: json['pushFriendActivity'] as bool? ?? false,
        emailMarketing: json['emailMarketing'] as bool? ?? true,
        pushMarketing: json['pushMarketing'] as bool? ?? true,
        emailSystemAnnouncements: json['emailSystemAnnouncements'] as bool? ?? true,
        pushSystemAnnouncements: json['pushSystemAnnouncements'] as bool? ?? true,
        quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
        quietHoursStartLocal: json['quietHoursStartLocal'] as String? ?? '22:00:00',
        quietHoursEndLocal: json['quietHoursEndLocal'] as String? ?? '08:00:00',
      );

  /// Body for `PATCH .../notification-preferences/toggles`
  /// (`UpdateNotificationTogglesVm` — no quiet-hours fields; those go
  /// through the separate `.../quiet-hours` endpoint).
  Map<String, dynamic> toJson() => {
    'pushEnabledMaster': pushEnabledMaster,
    'emailEnabledMaster': emailEnabledMaster,
    'smsEnabledMaster': smsEnabledMaster,
    'emailOrderUpdates': emailOrderUpdates,
    'pushOrderUpdates': pushOrderUpdates,
    'emailDeliveryUpdates': emailDeliveryUpdates,
    'pushDeliveryUpdates': pushDeliveryUpdates,
    'emailMessages': emailMessages,
    'pushMessages': pushMessages,
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

  static String _hhmmss(String hhmm) => hhmm.length == 5 ? '$hhmm:00' : hhmm;

  /// Backend has no dedicated categories for most of the toggles this screen
  /// shows (priceDrops, backInStock, flashSales, newArrivals, returns,
  /// payments, login/password alerts, product recs, ...) — only the eight
  /// Email/Push categories above exist. Each UI toggle is mapped onto the
  /// closest real category; several UI toggles necessarily share one
  /// backend field (documented per line below) until the backend grows
  /// dedicated categories for them.
  NotificationPreferences toDomain() => NotificationPreferences(
    pushEnabled: pushEnabledMaster,
    orderStatusChanges: pushOrderUpdates,
    deliveryUpdates: pushDeliveryUpdates,
    returnStatus: pushMessages, // "Messages" is otherwise unused — best available slot
    priceDrops: pushMarketing,
    backInStock: pushMarketing,
    flashSales: pushMarketing,
    newArrivals: pushMarketing,
    newReelsFromCreators: pushReelActivity,
    creatorRecommendations: pushFriendActivity,
    loginAlerts: pushSecurity,
    passwordChanges: pushSecurity,
    paymentUpdates: pushSystemAnnouncements,
    personalizedOffers: pushMarketing,
    productRecommendations: pushMarketing,
    newsletter: emailMarketing,
    emailNotifications: emailEnabledMaster,
    smsNotifications: smsEnabledMaster,
    quietHoursEnabled: quietHoursEnabled,
    quietHoursStart: _hhmm(quietHoursStartLocal),
    quietHoursEnd: _hhmm(quietHoursEndLocal),
    commentReplies: pushFriendActivity,
    newOrderForVendor: pushOrderUpdates,
    partnershipEvents: pushSystemAnnouncements,
    ticketUpdates: pushSystemAnnouncements,
    ordersDelivered: pushDeliveryUpdates,
  );

  /// Builds the PATCH payload from a (possibly UI-edited) domain entity.
  /// Inverse of the best-effort mapping in [toDomain] — see its comment.
  ///
  /// Deliberately does NOT OR in [NotificationPreferences] fields that have
  /// no UI toggle of their own (ordersDelivered, commentReplies,
  /// newOrderForVendor, partnershipEvents, ticketUpdates) — those are pure
  /// mirrors of another field, populated by [toDomain] from whatever was
  /// last loaded. ORing a stale mirror back in here means toggling its
  /// "real" sibling off would never actually clear the shared backend field
  /// (a mirror recorded as `true` at load time keeps winning the OR
  /// forever). Only fields the screen actually renders a switch for are
  /// combined.
  static NotificationPreferencesDto fromDomain(NotificationPreferences p) =>
      NotificationPreferencesDto(
        emailEnabledMaster: p.emailNotifications,
        pushEnabledMaster: p.pushEnabled,
        smsEnabledMaster: p.smsNotifications,
        emailSecurity: p.loginAlerts || p.passwordChanges,
        pushSecurity: p.loginAlerts || p.passwordChanges,
        emailOrderUpdates: p.orderStatusChanges,
        pushOrderUpdates: p.orderStatusChanges,
        emailDeliveryUpdates: p.deliveryUpdates,
        pushDeliveryUpdates: p.deliveryUpdates,
        emailMessages: p.returnStatus,
        pushMessages: p.returnStatus,
        emailReelActivity: p.newReelsFromCreators,
        pushReelActivity: p.newReelsFromCreators,
        emailFriendActivity: p.creatorRecommendations,
        pushFriendActivity: p.creatorRecommendations,
        emailMarketing: p.newsletter || p.priceDrops || p.backInStock || p.flashSales ||
            p.newArrivals || p.personalizedOffers || p.productRecommendations,
        pushMarketing: p.priceDrops || p.backInStock || p.flashSales || p.newArrivals ||
            p.personalizedOffers || p.productRecommendations,
        emailSystemAnnouncements: p.paymentUpdates,
        pushSystemAnnouncements: p.paymentUpdates,
        quietHoursEnabled: p.quietHoursEnabled,
        quietHoursStartLocal: _hhmmss(p.quietHoursStart ?? '22:00'),
        quietHoursEndLocal: _hhmmss(p.quietHoursEnd ?? '08:00'),
      );
}
