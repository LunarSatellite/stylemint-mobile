/// Wire model for `GET /v1/subscriptions/me` and the response of
/// `POST /v1/subscriptions/me/upgrade` / `POST /v1/subscriptions/me/cancel`.
class AccountSubscriptionDto {
  const AccountSubscriptionDto({
    required this.id,
    required this.accountId,
    required this.planId,
    required this.tier,
    required this.cadence,
    required this.pricePaidAmount,
    required this.pricePaidCurrency,
    required this.startedUtc,
    required this.cancelledUtc,
    required this.status,
  });

  final String id;
  final String accountId;
  final String planId;
  final int tier;
  final int cadence;
  final double pricePaidAmount;
  final String? pricePaidCurrency;
  final DateTime startedUtc;
  final DateTime? cancelledUtc;
  final int status;

  factory AccountSubscriptionDto.fromJson(Map<String, dynamic> json) {
    return AccountSubscriptionDto(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      planId: json['planId'] as String,
      tier: (json['tier'] as num).toInt(),
      cadence: (json['cadence'] as num).toInt(),
      pricePaidAmount: (json['pricePaidAmount'] as num).toDouble(),
      pricePaidCurrency: json['pricePaidCurrency'] as String?,
      startedUtc: DateTime.parse(json['startedUtc'] as String),
      cancelledUtc: json['cancelledUtc'] == null
          ? null
          : DateTime.parse(json['cancelledUtc'] as String),
      status: (json['status'] as num).toInt(),
    );
  }
}
