class LoyaltyWallet {
  const LoyaltyWallet({required this.summary, required this.transactions});

  final LoyaltySummary summary;
  final List<LoyaltyTransaction> transactions;

  factory LoyaltyWallet.fromJson(Map<String, dynamic> json) => LoyaltyWallet(
    summary: LoyaltySummary.fromJson(
      json['summary'] as Map<String, dynamic>? ?? const {},
    ),
    transactions: (json['transactions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LoyaltyTransaction.fromJson)
        .toList(growable: false),
  );
}

class LoyaltySummary {
  const LoyaltySummary({
    required this.balancePoints,
    required this.redeemableValueAmount,
    required this.checkoutCreditAmount,
    required this.currency,
    required this.tier,
    required this.lifetimeEarnedPoints,
    required this.lifetimeRedeemedPoints,
    required this.pointsToNextTier,
    required this.nextExpiryUtc,
    required this.pointsExpiringNext30Days,
  });

  final int balancePoints;
  final double redeemableValueAmount;
  final double checkoutCreditAmount;
  final String currency;
  final String tier;
  final int lifetimeEarnedPoints;
  final int lifetimeRedeemedPoints;
  final int? pointsToNextTier;
  final DateTime? nextExpiryUtc;
  final int pointsExpiringNext30Days;

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    const tiers = ['Seed', 'Sprout', 'Bloom', 'Icon'];
    final rawTier = json['tier'];
    final tier = rawTier is num
        ? tiers[rawTier.toInt().clamp(0, tiers.length - 1)]
        : (rawTier?.toString() ?? 'Seed');
    return LoyaltySummary(
      balancePoints: (json['balancePoints'] as num?)?.toInt() ?? 0,
      redeemableValueAmount:
          (json['redeemableValueAmount'] as num?)?.toDouble() ?? 0,
      checkoutCreditAmount:
          (json['checkoutCreditAmount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NPR',
      tier: tier,
      lifetimeEarnedPoints:
          (json['lifetimeEarnedPoints'] as num?)?.toInt() ?? 0,
      lifetimeRedeemedPoints:
          (json['lifetimeRedeemedPoints'] as num?)?.toInt() ?? 0,
      pointsToNextTier: (json['pointsToNextTier'] as num?)?.toInt(),
      nextExpiryUtc: DateTime.tryParse(json['nextExpiryUtc'] as String? ?? ''),
      pointsExpiringNext30Days:
          (json['pointsExpiringNext30Days'] as num?)?.toInt() ?? 0,
    );
  }
}

class LoyaltyTransaction {
  const LoyaltyTransaction({
    required this.id,
    required this.kind,
    required this.pointsDelta,
    required this.description,
    required this.occurredUtc,
  });
  final String id;
  final String kind;
  final int pointsDelta;
  final String description;
  final DateTime occurredUtc;

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransaction(
        id: json['id'] as String? ?? '',
        kind: json['kind']?.toString() ?? '',
        pointsDelta: (json['pointsDelta'] as num?)?.toInt() ?? 0,
        description: json['description'] as String? ?? '',
        occurredUtc:
            DateTime.tryParse(json['occurredUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

class LoyaltyRedemption {
  const LoyaltyRedemption({
    required this.pointsRedeemed,
    required this.creditAmount,
    required this.currency,
    required this.explanation,
  });
  final int pointsRedeemed;
  final double creditAmount;
  final String currency;
  final String explanation;

  factory LoyaltyRedemption.fromJson(Map<String, dynamic> json) =>
      LoyaltyRedemption(
        pointsRedeemed: (json['pointsRedeemed'] as num?)?.toInt() ?? 0,
        creditAmount: (json['creditAmount'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'NPR',
        explanation: json['explanation'] as String? ?? '',
      );
}
