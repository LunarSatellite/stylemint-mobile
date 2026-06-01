/// The signed-in customer's profile header + counters (Figma "Profile").
class ProfileSummary {
  const ProfileSummary({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.savedItemsCount,
    required this.followingCount,
    required this.ordersCount,
    required this.language,
    required this.pushEnabled,
  });

  final String displayName;
  final String email;
  final String avatarUrl;
  final int savedItemsCount;
  final int followingCount;
  final int ordersCount;
  final String language; // e.g. "English"
  final bool pushEnabled;

  ProfileSummary copyWith({bool? pushEnabled}) => ProfileSummary(
    displayName: displayName,
    email: email,
    avatarUrl: avatarUrl,
    savedItemsCount: savedItemsCount,
    followingCount: followingCount,
    ordersCount: ordersCount,
    language: language,
    pushEnabled: pushEnabled ?? this.pushEnabled,
  );
}
