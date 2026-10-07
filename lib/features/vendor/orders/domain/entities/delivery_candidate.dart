/// A delivery partner who could carry this order's parcel.
///
/// Produced by the routing pipeline on the server, not by a query of our own,
/// so a partner absent from the list is one routing would refuse. Offering to
/// someone not in it comes back as a refusal with the reason.
class DeliveryCandidate {
  const DeliveryCandidate({
    required this.courierProfileId,
    required this.tier,
    required this.currentGeohash,
    required this.score,
    required this.reliability,
    required this.rating,
    required this.recentDeclines24h,
    required this.payoutAmount,
    required this.payoutCurrency,
  });

  factory DeliveryCandidate.fromJson(Map<String, dynamic> json) =>
      DeliveryCandidate(
        courierProfileId: json['courierProfileId'] as String? ?? '',
        tier: (json['tier'] as num?)?.toInt() ?? 0,
        currentGeohash: json['currentGeohash'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
        reliability: (json['reliability'] as num?)?.toDouble() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        recentDeclines24h: (json['recentDeclines24h'] as num?)?.toInt() ?? 0,
        payoutAmount: (json['proposedPayoutAmount'] as num?)?.toDouble() ?? 0,
        payoutCurrency: json['proposedPayoutCurrency'] as String? ?? 'NPR',
      );

  final String courierProfileId;

  /// 1 Neighbour, 2 Traveller, 3 Pro. Mirrors `DeliveryTier`.
  final int tier;

  final String currentGeohash;

  /// Routing's own score — the order the automatic auction would have used.
  final double score;

  final double reliability;
  final double rating;
  final int recentDeclines24h;

  final double payoutAmount;
  final String payoutCurrency;

  /// How to name the tier to a vendor. Not the number, which means nothing to
  /// them, and not the enum name either.
  String get tierLabel => switch (tier) {
    1 => 'Neighbour',
    2 => 'Traveller',
    3 => 'Pro',
    _ => 'Partner',
  };
}
