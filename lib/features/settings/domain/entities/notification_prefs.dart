/// The notification preferences the customer can actually change.
///
/// Every field here maps **one-to-one** onto a column the backend stores and
/// a gate the backend reads. That is deliberate: this entity previously
/// carried a dozen finer-grained flags (priceDrops, backInStock, flashSales,
/// newArrivals, productRecommendations, personalizedOffers, ...) that were all
/// OR-ed into the single `PushMarketing` column on the way out and all read
/// back from that same column on the way in. Turning one of them off changed
/// nothing while any sibling was on, and the switch flipped itself back on at
/// the next load. Fields that cannot be independently stored are not modelled
/// here, so no screen can offer a control the backend cannot honour.
///
/// Also absent: security alerts. `IsEmailEnabled`/`IsPushEnabled` in the
/// Identity module return `true` for `NotificationCategory.Security`
/// unconditionally, and `UpdateNotificationTogglesVm` has no Security field at
/// all, so a login/password-alert preference can neither be sent nor honoured.
class NotificationPreferences {
  const NotificationPreferences({
    // Channel masters
    this.pushEnabled = true,
    this.emailNotifications = false,
    this.smsNotifications = false,
    // Per-category (Identity rollups)
    this.orderStatusChanges = true,
    this.deliveryUpdates = true,
    this.newReelsFromCreators = false,
    this.newFollowers = false,
    this.paymentUpdates = true,
    this.marketingPush = true,
    this.newsletter = false,
    // Quiet Hours — saved through its own endpoint.
    this.quietHoursEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });

  /// `pushEnabledMaster` — gates every non-Security push.
  final bool pushEnabled;

  /// `emailEnabledMaster` — gates every non-Security email.
  final bool emailNotifications;

  /// `smsEnabledMaster`.
  ///
  /// Stored by the backend but, today, read by nothing that can change a
  /// dispatch outcome: `IsSmsEnabled` returns `SmsSecurity` for Security
  /// (ignoring this master) and `false` for every other category whether the
  /// master is on or off. See the screen's note and the audit report.
  final bool smsNotifications;

  /// `push/emailOrderUpdates` — OrderPlaced, OrderCancelled, OrderRefunded.
  final bool orderStatusChanges;

  /// `push/emailDeliveryUpdates` — OrderShipped, OrderDelivered.
  final bool deliveryUpdates;

  /// `push/emailReelActivity` — NewReelFromFollowed, CommentReply.
  final bool newReelsFromCreators;

  /// `push/emailFriendActivity` — NewFollower.
  final bool newFollowers;

  /// `push/emailSystemAnnouncements` — payouts, support replies, and the
  /// default rollup for newer categories.
  final bool paymentUpdates;

  /// `pushMarketing` — PriceDrop, StockBack, CheckoutAbandonedReminder and
  /// every other promotional push. One column, one switch.
  final bool marketingPush;

  /// `emailMarketing` — the marketing email channel.
  final bool newsletter;

  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? orderStatusChanges,
    bool? deliveryUpdates,
    bool? newReelsFromCreators,
    bool? newFollowers,
    bool? paymentUpdates,
    bool? marketingPush,
    bool? newsletter,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      orderStatusChanges: orderStatusChanges ?? this.orderStatusChanges,
      deliveryUpdates: deliveryUpdates ?? this.deliveryUpdates,
      newReelsFromCreators: newReelsFromCreators ?? this.newReelsFromCreators,
      newFollowers: newFollowers ?? this.newFollowers,
      paymentUpdates: paymentUpdates ?? this.paymentUpdates,
      marketingPush: marketingPush ?? this.marketingPush,
      newsletter: newsletter ?? this.newsletter,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}
