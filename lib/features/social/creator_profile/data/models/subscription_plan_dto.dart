/// Wire model for `GET /v1/subscriptions/plans`.
///
/// The backend returns one entry per (tier × cadence) combination, so the
/// `Basic Monthly` and `Basic Yearly` plans arrive as two separate rows with
/// the same `tier` but different `cadence` values (1 = monthly, 2 = yearly).
/// Group by `tier` in the UI and pick the cadence row that matches the
/// selected billing cycle.
class SubscriptionPlanDto {
  const SubscriptionPlanDto({
    required this.id,
    required this.tier,
    required this.cadence,
    required this.priceAmount,
    required this.priceCurrency,
    required this.name,
    required this.marketingTag,
    required this.maxCampaigns,
    required this.maxProducts,
    required this.orderManagement,
    required this.sortOrder,
  });

  final String id;
  final int tier;
  final int cadence;
  final double priceAmount;
  final String? priceCurrency;
  final String? name;
  final String? marketingTag;
  final int maxCampaigns;
  final int maxProducts;
  final bool orderManagement;
  final int sortOrder;

  /// Sentinel used by the backend for "unlimited" — surfaces as such in the UI.
  static const int unlimited = -1;

  bool get isUnlimitedCampaigns => maxCampaigns == unlimited;
  bool get isUnlimitedProducts => maxProducts == unlimited;

  factory SubscriptionPlanDto.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanDto(
      id: json['id'] as String,
      tier: (json['tier'] as num).toInt(),
      cadence: (json['cadence'] as num).toInt(),
      priceAmount: (json['priceAmount'] as num).toDouble(),
      priceCurrency: json['priceCurrency'] as String?,
      name: json['name'] as String?,
      marketingTag: json['marketingTag'] as String?,
      maxCampaigns: (json['maxCampaigns'] as num).toInt(),
      maxProducts: (json['maxProducts'] as num).toInt(),
      orderManagement: json['orderManagement'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
