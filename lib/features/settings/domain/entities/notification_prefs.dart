class NotificationPreferences {
  const NotificationPreferences({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.orderUpdates,
    required this.promotional,
    required this.reelLikes,
    required this.newFollowers,
    required this.quietHoursEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final bool orderUpdates;
  final bool promotional;
  final bool reelLikes;
  final bool newFollowers;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? orderUpdates,
    bool? promotional,
    bool? reelLikes,
    bool? newFollowers,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotional: promotional ?? this.promotional,
      reelLikes: reelLikes ?? this.reelLikes,
      newFollowers: newFollowers ?? this.newFollowers,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}
