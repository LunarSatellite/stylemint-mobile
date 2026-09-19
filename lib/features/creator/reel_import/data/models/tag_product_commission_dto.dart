import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/tag_product_commission.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Wire shape of one item from
/// `GET /v1/creator/tag-products/commission?productIds=…`.
///
/// ```json
/// { "ProductId": "…", "Status": "Applies", "PartnershipId": "…",
///   "CommissionRateFraction": 0.15, "CommissionRateMinFraction": 0.10,
///   "CommissionRateMaxFraction": 0.20, "ProductVariantId": "…",
///   "UnitPrice": { "Amount": 3000, "Currency": "NPR" },
///   "CommissionPerSale": { "Amount": 450, "Currency": "NPR" } }
/// ```
///
/// This endpoint serialises **PascalCase**, unlike the camelCase the rest of
/// this app reads, so every key is looked up in both spellings. A key that
/// is absent in both stays null — there is no fallback rate and no fallback
/// money here, because the whole point of the contract is that
/// `"Status": "NoPartnership"` carries nulls and `"Status": "Applies"` with
/// `"CommissionRateFraction": 0` carries a real zero.
///
/// An unrecognised status parses as
/// [TagProductCommissionStatus.productUnavailable], whose rule is "assert
/// nothing". That is the safe direction: a status this client has not seen
/// makes the chip disappear, never invents a rate.
class TagProductCommissionDto {
  const TagProductCommissionDto({
    required this.productId,
    required this.status,
    this.partnershipId,
    this.commissionRateFraction,
    this.commissionRateMinFraction,
    this.commissionRateMaxFraction,
    this.productVariantId,
    this.unitPrice,
    this.commissionPerSale,
  });

  factory TagProductCommissionDto.fromJson(Map<String, dynamic> json) {
    return TagProductCommissionDto(
      productId: _string(json, 'ProductId') ?? '',
      status: _string(json, 'Status') ?? '',
      partnershipId: _string(json, 'PartnershipId'),
      commissionRateFraction: _number(json, 'CommissionRateFraction'),
      commissionRateMinFraction: _number(json, 'CommissionRateMinFraction'),
      commissionRateMaxFraction: _number(json, 'CommissionRateMaxFraction'),
      productVariantId: _string(json, 'ProductVariantId'),
      unitPrice: _money(json, 'UnitPrice'),
      commissionPerSale: _money(json, 'CommissionPerSale'),
    );
  }

  /// The raw wire string, mapped only in [toDomain].
  final String status;
  final String productId;
  final String? partnershipId;
  final double? commissionRateFraction;
  final double? commissionRateMinFraction;
  final double? commissionRateMaxFraction;
  final String? productVariantId;
  final Money? unitPrice;
  final Money? commissionPerSale;

  TagProductCommission toDomain() => TagProductCommission(
    productId: productId,
    status: switch (status.toLowerCase()) {
      'applies' => TagProductCommissionStatus.applies,
      'nopartnership' => TagProductCommissionStatus.noPartnership,
      _ => TagProductCommissionStatus.productUnavailable,
    },
    partnershipId: partnershipId,
    commissionRateFraction: commissionRateFraction,
    commissionRateMinFraction: commissionRateMinFraction,
    commissionRateMaxFraction: commissionRateMaxFraction,
    productVariantId: productVariantId,
    unitPrice: unitPrice,
    commissionPerSale: commissionPerSale,
  );

  /// Both spellings of one key. `PascalCase` is what this endpoint sends;
  /// the camelCase alternative costs nothing and means a serialiser change
  /// upstream degrades to "no chip" rather than to a wrong chip.
  static dynamic _raw(Map<String, dynamic> json, String pascal) {
    if (json.containsKey(pascal)) return json[pascal];
    final camel = pascal[0].toLowerCase() + pascal.substring(1);
    return json[camel];
  }

  static String? _string(Map<String, dynamic> json, String key) =>
      _raw(json, key) as String?;

  static double? _number(Map<String, dynamic> json, String key) =>
      (_raw(json, key) as num?)?.toDouble();

  static Money? _money(Map<String, dynamic> json, String key) {
    final raw = _raw(json, key);
    if (raw is! Map<String, dynamic>) return null;
    final amount = (_raw(raw, 'Amount') as num?)?.toDouble();
    final currency = _raw(raw, 'Currency') as String?;
    if (amount == null || currency == null) return null;
    return Money(amount: amount, currency: currency);
  }
}

/// The `{ "Items": [...] }` envelope.
class TagProductCommissionListDto {
  const TagProductCommissionListDto({required this.items});

  factory TagProductCommissionListDto.fromJson(Map<String, dynamic> json) {
    final raw =
        (json['Items'] ?? json['items']) as List<dynamic>? ?? const <dynamic>[];
    return TagProductCommissionListDto(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(TagProductCommissionDto.fromJson)
          .toList(growable: false),
    );
  }

  /// In request order, as the server returns them.
  final List<TagProductCommissionDto> items;
}
