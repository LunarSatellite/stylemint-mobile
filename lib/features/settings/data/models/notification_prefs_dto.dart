import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';

part 'notification_prefs_dto.freezed.dart';
part 'notification_prefs_dto.g.dart';

/// Mirrors the backend's `NotificationTogglesDto` (Support module) field for
/// field — this is the full toggle set the PATCH endpoint expects; there is
/// no partial-toggle dictionary in v1, so every field must be sent.
@freezed
abstract class NotificationTogglesDto with _$NotificationTogglesDto {
  const factory NotificationTogglesDto({
    // pushEnabledMaster removed: backend does not yet expose it in v1
    @Default(true) bool ordersPlaced,
    @Default(true) bool ordersShipped,
    @Default(true) bool ordersDelivered,
    @Default(true) bool ordersRefunded,
    @Default(true) bool returnsUpdates,
    @Default(true) bool promotions,
    @Default(true) bool priceDrops,
    @Default(true) bool backInStock,
    @Default(false) bool newReelsFromFollowed,
    @Default(false) bool newFollower,
    @Default(true) bool commentReplies,
    @Default(true) bool saleNotifications,
    @Default(true) bool payoutEvents,
    @Default(true) bool newOrderForVendor,
    @Default(true) bool partnershipEvents,
    @Default(true) bool ticketUpdates,
    @Default(true) bool securityAlerts,
    @Default(true) bool signInFromNewDevice,
    @Default(false) bool emailNewsletter,
    @Default(false) bool productTips,
  }) = _NotificationTogglesDto;

  factory NotificationTogglesDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationTogglesDtoFromJson(json);
}

/// Mirrors the backend's `PreferenceQuietHoursDto`. `startLocalTime`/
/// `endLocalTime` are `TimeOnly` on the backend, serialized as `"HH:mm:ss"`.
@freezed
abstract class PreferenceQuietHoursDto with _$PreferenceQuietHoursDto {
  const factory PreferenceQuietHoursDto({
    @Default(true) bool enabled,
    @Default('22:00:00') String startLocalTime,
    @Default('08:00:00') String endLocalTime,
    @Default('Asia/Kathmandu') String timezone,
  }) = _PreferenceQuietHoursDto;

  factory PreferenceQuietHoursDto.fromJson(Map<String, dynamic> json) =>
      _$PreferenceQuietHoursDtoFromJson(json);
}

/// GET/PATCH `/v1/notifications/preferences` response shape.
@freezed
abstract class NotificationPreferencesDto with _$NotificationPreferencesDto {
  const factory NotificationPreferencesDto({
    required NotificationTogglesDto toggles,
    required PreferenceQuietHoursDto quietHours,
  }) = _NotificationPreferencesDto;

  const NotificationPreferencesDto._();

  factory NotificationPreferencesDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesDtoFromJson(json);

  static String _hhmm(String hhmmss) =>
      hhmmss.length >= 5 ? hhmmss.substring(0, 5) : hhmmss;

  static String _hhmmss(String hhmm) => hhmm.length == 5 ? '$hhmm:00' : hhmm;

  NotificationPreferences toDomain() => NotificationPreferences(
    pushEnabled: true, // was: toggles.pushEnabledMaster
    orderStatusChanges: toggles.ordersPlaced,
    deliveryUpdates: toggles.ordersShipped,
    returnStatus: toggles.ordersRefunded || toggles.returnsUpdates,
    priceDrops: toggles.priceDrops,
    backInStock: toggles.backInStock,
    flashSales: toggles.saleNotifications,
    newArrivals: toggles.promotions,
    newReelsFromCreators: toggles.newReelsFromFollowed,
    creatorRecommendations: toggles.newFollower,
    loginAlerts: toggles.signInFromNewDevice,
    passwordChanges: toggles.securityAlerts,
    paymentUpdates: toggles.payoutEvents,
    personalizedOffers: toggles.promotions,
    productRecommendations: toggles.productTips,
    newsletter: toggles.emailNewsletter,
    emailNotifications: toggles.emailNewsletter,
    smsNotifications: false,
    quietHoursEnabled: quietHours.enabled,
    quietHoursStart: _hhmm(quietHours.startLocalTime),
    quietHoursEnd: _hhmm(quietHours.endLocalTime),
    commentReplies: toggles.commentReplies,
    newOrderForVendor: toggles.newOrderForVendor,
    partnershipEvents: toggles.partnershipEvents,
    ticketUpdates: toggles.ticketUpdates,
    ordersDelivered: toggles.ordersDelivered,
  );

  /// Builds the PATCH payload from a (possibly UI-edited) domain entity.
  /// Fields the notification-prefs screen doesn't expose a toggle for
  /// (commentReplies, newOrderForVendor, partnershipEvents, ticketUpdates,
  /// ordersDelivered) are threaded through from what was loaded rather than
  /// reset to a hardcoded default — see NotificationPreferences.copyWith.
  static NotificationPreferencesDto fromDomain(NotificationPreferences p) =>
      NotificationPreferencesDto(
        toggles: NotificationTogglesDto(
          // pushEnabledMaster omitted: backend does not yet expose it
          ordersPlaced: p.orderStatusChanges,
          ordersShipped: p.deliveryUpdates,
          ordersDelivered: p.ordersDelivered,
          ordersRefunded: p.returnStatus,
          returnsUpdates: p.returnStatus,
          promotions: p.newArrivals || p.personalizedOffers,
          priceDrops: p.priceDrops,
          backInStock: p.backInStock,
          newReelsFromFollowed: p.newReelsFromCreators,
          newFollower: p.creatorRecommendations,
          commentReplies: p.commentReplies,
          saleNotifications: p.flashSales,
          payoutEvents: p.paymentUpdates,
          newOrderForVendor: p.newOrderForVendor,
          partnershipEvents: p.partnershipEvents,
          ticketUpdates: p.ticketUpdates,
          securityAlerts: p.passwordChanges,
          signInFromNewDevice: p.loginAlerts,
          emailNewsletter: p.newsletter || p.emailNotifications,
          productTips: p.productRecommendations,
        ),
        quietHours: PreferenceQuietHoursDto(
          enabled: p.quietHoursEnabled,
          startLocalTime: _hhmmss(p.quietHoursStart ?? '22:00'),
          endLocalTime: _hhmmss(p.quietHoursEnd ?? '08:00'),
        ),
      );
}

