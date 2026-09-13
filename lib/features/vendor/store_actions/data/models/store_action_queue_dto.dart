import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/entities/store_actions.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Wire shape of GET `/v1/vendor/store/actions` — backend
/// `StoreActionQueue { Actions[], GeneratedUtc }` with
/// `StoreAction { Kind, Severity, ProductId, ProductVariantId?, ProductName,
/// Sku?, Recommendation, Evidence[], ValueAtStake? }`, serialized camelCase.
/// The backend registers no JsonStringEnumConverter, so `kind` and
/// `severity` arrive as ints; string names are accepted too. Actions without
/// a message are dropped, so a partial payload degrades to the empty state.
class StoreActionQueueDto {
  const StoreActionQueueDto({required this.actions, this.generatedUtc});

  factory StoreActionQueueDto.fromJson(Map<String, dynamic> json) {
    final raw = json['actions'];
    return StoreActionQueueDto(
      generatedUtc: json['generatedUtc'] is String
          ? DateTime.tryParse(json['generatedUtc'] as String)
          : null,
      actions: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(StoreActionDto.fromJson)
                .where((a) => a.recommendation.isNotEmpty)
                .toList(growable: false)
          : const <StoreActionDto>[],
    );
  }

  final List<StoreActionDto> actions;
  final DateTime? generatedUtc;

  StoreActionQueue toDomain() => StoreActionQueue(
    actions: actions.map((a) => a.toDomain()).toList(growable: false),
    generatedUtc: generatedUtc,
  );
}

class StoreActionDto {
  const StoreActionDto({
    required this.kind,
    required this.severity,
    required this.productId,
    required this.productName,
    required this.recommendation,
    required this.evidence,
    this.productVariantId,
    this.sku,
    this.valueAtStake,
  });

  factory StoreActionDto.fromJson(Map<String, dynamic> json) => StoreActionDto(
    kind: parseStoreActionKind(json['kind']),
    severity: parseStoreActionSeverity(json['severity']),
    productId: (json['productId'] as String? ?? '').trim(),
    productVariantId: _blankToNull(json['productVariantId']),
    productName: (json['productName'] as String? ?? '').trim(),
    sku: _blankToNull(json['sku']),
    recommendation: (json['recommendation'] as String? ?? '').trim(),
    evidence: _parseEvidence(json['evidence']),
    valueAtStake: _parseMoney(json['valueAtStake']),
  );

  final StoreActionKind kind;
  final StoreActionSeverity severity;
  final String productId;
  final String? productVariantId;
  final String productName;
  final String? sku;
  final String recommendation;
  final List<String> evidence;
  final Money? valueAtStake;

  StoreAction toDomain() => StoreAction(
    kind: kind,
    severity: severity,
    productId: productId,
    productVariantId: productVariantId,
    productName: productName,
    sku: sku,
    recommendation: recommendation,
    evidence: evidence,
    valueAtStake: valueAtStake,
  );
}

/// Backend `StoreActionKind`: RestockSoon=1, SoldOutWhileSelling=2,
/// SlowMovingStock=3, AddProductImages=4, ReturnsRising=5. Accepts the int, a
/// numeric string, or the name in any casing / snake_case; anything else is
/// [StoreActionKind.unknown].
StoreActionKind parseStoreActionKind(Object? raw) =>
    switch (_normalizeEnum(raw)) {
      1 || 'restocksoon' => StoreActionKind.restockSoon,
      2 || 'soldoutwhileselling' => StoreActionKind.soldOutWhileSelling,
      3 || 'slowmovingstock' => StoreActionKind.slowMovingStock,
      4 || 'addproductimages' => StoreActionKind.addProductImages,
      5 || 'returnsrising' => StoreActionKind.returnsRising,
      _ => StoreActionKind.unknown,
    };

/// Backend `StoreActionSeverity`: High=1, Medium=2, Low=3. Unknown values
/// read as [StoreActionSeverity.low] so they get the neutral styling rather
/// than an alarming one.
StoreActionSeverity parseStoreActionSeverity(Object? raw) =>
    switch (_normalizeEnum(raw)) {
      1 || 'high' => StoreActionSeverity.high,
      2 || 'medium' => StoreActionSeverity.medium,
      _ => StoreActionSeverity.low,
    };

/// An int for int / whole-number / numeric-string input, a lowercase name
/// with `_`, `-` and spaces removed for other strings, else null.
Object? _normalizeEnum(Object? raw) {
  if (raw is int) return raw;
  if (raw is num && raw == raw.roundToDouble()) return raw.toInt();
  if (raw is String) {
    final trimmed = raw.trim();
    return int.tryParse(trimmed) ??
        trimmed.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }
  return null;
}

String? _blankToNull(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _parseEvidence(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw
      .whereType<String>()
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}

Money? _parseMoney(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final amount = raw['amount'];
  if (amount is! num) return null;
  final currency = (raw['currency'] as String? ?? '').trim().toUpperCase();
  return Money(
    amount: amount.toDouble(),
    currency: currency.isEmpty ? 'NPR' : currency,
  );
}
