class NotificationPreferences {
  const NotificationPreferences({
    // Push
    this.pushEnabled = true,
    // Order Updates
    this.orderStatusChanges = true,
    this.deliveryUpdates = true,
    this.returnStatus = true,
    // Shopping & Deals
    this.priceDrops = true,
    this.backInStock = true,
    this.flashSales = true,
    this.newArrivals = false,
    // Creator Activity
    this.newReelsFromCreators = false,
    this.creatorRecommendations = false,
    // Account & Security
    this.loginAlerts = true,
    this.passwordChanges = true,
    this.paymentUpdates = true,
    // Marketing & Promotions
    this.personalizedOffers = true,
    this.productRecommendations = false,
    this.newsletter = false,
    // Email & SMS
    this.emailNotifications = false,
    this.smsNotifications = false,
    // Quiet Hours
    this.quietHoursEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    // Legacy aliases kept for DTO compat
    bool? emailEnabled,
    bool? orderUpdates,
    bool? promotional,
    bool? reelLikes,
    bool? newFollowers,
  });

  final bool pushEnabled;
  final bool orderStatusChanges;
  final bool deliveryUpdates;
  final bool returnStatus;
  final bool priceDrops;
  final bool backInStock;
  final bool flashSales;
  final bool newArrivals;
  final bool newReelsFromCreators;
  final bool creatorRecommendations;
  final bool loginAlerts;
  final bool passwordChanges;
  final bool paymentUpdates;
  final bool personalizedOffers;
  final bool productRecommendations;
  final bool newsletter;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  // Legacy getters so existing DTO/repository code compiles unchanged
  bool get emailEnabled => emailNotifications;
  bool get orderUpdates => orderStatusChanges;
  bool get promotional => personalizedOffers;
  bool get reelLikes => newReelsFromCreators;
  bool get newFollowers => creatorRecommendations;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? orderStatusChanges,
    bool? deliveryUpdates,
    bool? returnStatus,
    bool? priceDrops,
    bool? backInStock,
    bool? flashSales,
    bool? newArrivals,
    bool? newReelsFromCreators,
    bool? creatorRecommendations,
    bool? loginAlerts,
    bool? passwordChanges,
    bool? paymentUpdates,
    bool? personalizedOffers,
    bool? productRecommendations,
    bool? newsletter,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      orderStatusChanges: orderStatusChanges ?? this.orderStatusChanges,
      deliveryUpdates: deliveryUpdates ?? this.deliveryUpdates,
      returnStatus: returnStatus ?? this.returnStatus,
      priceDrops: priceDrops ?? this.priceDrops,
      backInStock: backInStock ?? this.backInStock,
      flashSales: flashSales ?? this.flashSales,
      newArrivals: newArrivals ?? this.newArrivals,
      newReelsFromCreators: newReelsFromCreators ?? this.newReelsFromCreators,
      creatorRecommendations: creatorRecommendations ?? this.creatorRecommendations,
      loginAlerts: loginAlerts ?? this.loginAlerts,
      passwordChanges: passwordChanges ?? this.passwordChanges,
      paymentUpdates: paymentUpdates ?? this.paymentUpdates,
      personalizedOffers: personalizedOffers ?? this.personalizedOffers,
      productRecommendations: productRecommendations ?? this.productRecommendations,
      newsletter: newsletter ?? this.newsletter,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}
