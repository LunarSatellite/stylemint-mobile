class BadgeAward {
  const BadgeAward({
    required this.id,
    required this.badgeCode,
    required this.badgeDisplayName,
    required this.badgeIconUrl,
    required this.badgeTier,
    required this.badgeCategory,
    required this.isShowcased,
    this.showcasedOrder,
  });

  final String id;
  final String badgeCode;
  final String badgeDisplayName;
  final String badgeIconUrl;
  final int badgeTier;
  final int badgeCategory;
  final bool isShowcased;
  final int? showcasedOrder;
}
