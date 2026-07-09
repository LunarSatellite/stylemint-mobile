class CreatorPerformance {
  const CreatorPerformance({
    required this.creatorAccountId,
    required this.unitsSold,
    required this.attributedRevenue,
    required this.commissionPaid,
    required this.currency,
    required this.distinctReelCount,
    this.creatorHandle,
    this.creatorDisplayName,
    this.creatorAvatarUrl,
  });

  final String creatorAccountId;
  final int unitsSold;
  final double attributedRevenue;
  final double commissionPaid;
  final String currency;
  final int distinctReelCount;
  final String? creatorHandle;
  final String? creatorDisplayName;
  final String? creatorAvatarUrl;

  /// Best available creator label: display name → @handle → short-id fallback.
  String get label {
    final name = creatorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = creatorHandle?.trim();
    if (handle != null && handle.isNotEmpty) return '@$handle';
    return creatorAccountId.length >= 4
        ? 'Creator ••${creatorAccountId.substring(creatorAccountId.length - 4)}'
        : 'Creator';
  }

  String get formattedHandle {
    final h = creatorHandle?.trim();
    if (h != null && h.isNotEmpty) return '@$h';
    return '';
  }

  CreatorPerformance copyWith({
    String? creatorAccountId,
    int? unitsSold,
    double? attributedRevenue,
    double? commissionPaid,
    String? currency,
    int? distinctReelCount,
    String? creatorHandle,
    String? creatorDisplayName,
    String? creatorAvatarUrl,
  }) {
    return CreatorPerformance(
      creatorAccountId: creatorAccountId ?? this.creatorAccountId,
      unitsSold: unitsSold ?? this.unitsSold,
      attributedRevenue: attributedRevenue ?? this.attributedRevenue,
      commissionPaid: commissionPaid ?? this.commissionPaid,
      currency: currency ?? this.currency,
      distinctReelCount: distinctReelCount ?? this.distinctReelCount,
      creatorHandle: creatorHandle ?? this.creatorHandle,
      creatorDisplayName: creatorDisplayName ?? this.creatorDisplayName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CreatorPerformance &&
      other.creatorAccountId == creatorAccountId &&
      other.unitsSold == unitsSold &&
      other.attributedRevenue == attributedRevenue &&
      other.commissionPaid == commissionPaid &&
      other.currency == currency &&
      other.distinctReelCount == distinctReelCount &&
      other.creatorHandle == creatorHandle &&
      other.creatorDisplayName == creatorDisplayName &&
      other.creatorAvatarUrl == creatorAvatarUrl;

  @override
  int get hashCode => Object.hash(
    creatorAccountId,
    unitsSold,
    attributedRevenue,
    commissionPaid,
    currency,
    distinctReelCount,
    creatorHandle,
    creatorDisplayName,
    creatorAvatarUrl,
  );
}
