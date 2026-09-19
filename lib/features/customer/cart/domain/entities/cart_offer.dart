enum CartOfferKind { applyCode, spendMoreForCode, cheaperSwap, unknown }

class CartOfferAdvice {
  const CartOfferAdvice({
    required this.inControlGroup,
    required this.headline,
    required this.offers,
    required this.fairnessNote,
    this.note,
  });

  factory CartOfferAdvice.fromJson(Map<String, dynamic> json) =>
      CartOfferAdvice(
        inControlGroup: json['inControlGroup'] == true,
        headline: json['headline'] as String? ?? '',
        offers: (json['offers'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CartOffer.fromJson)
            .toList(growable: false),
        fairnessNote: json['fairnessNote'] as String? ?? '',
        note: json['note'] as String?,
      );

  final bool inControlGroup;
  final String headline;
  final List<CartOffer> offers;
  final String fairnessNote;
  final String? note;
  bool get hasContent => offers.isNotEmpty || (note?.isNotEmpty ?? false);
}

class CartOffer {
  const CartOffer({
    required this.kind,
    required this.title,
    required this.detail,
    required this.valueAmount,
    required this.currency,
    required this.recommended,
    this.code,
    this.spendMoreAmount,
    this.expiresUtc,
  });

  factory CartOffer.fromJson(Map<String, dynamic> json) => CartOffer(
    kind: switch (json['kind']) {
      1 || 'ApplyCode' || 'applyCode' => CartOfferKind.applyCode,
      2 ||
      'SpendMoreForCode' ||
      'spendMoreForCode' => CartOfferKind.spendMoreForCode,
      3 || 'CheaperSwap' || 'cheaperSwap' => CartOfferKind.cheaperSwap,
      _ => CartOfferKind.unknown,
    },
    title: json['title'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
    valueAmount: (json['valueAmount'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? 'NPR',
    code: json['code'] as String?,
    spendMoreAmount: (json['spendMoreAmount'] as num?)?.toDouble(),
    expiresUtc: DateTime.tryParse(json['expiresUtc'] as String? ?? ''),
    recommended: json['recommended'] == true,
  );

  final CartOfferKind kind;
  final String title;
  final String detail;
  final double valueAmount;
  final String currency;
  final String? code;
  final double? spendMoreAmount;
  final DateTime? expiresUtc;
  final bool recommended;
}
