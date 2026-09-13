import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_scenarios.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Wire shape of GET `/v1/cart/scenarios` — backend `BasketLab { Currency,
/// Budget, Scenarios[] }` with `BasketScenario` and `BasketScenarioLine`,
/// camelCase. `kind` and `change` arrive as enum ints (string names are
/// tolerated); amounts are decimals in the top-level currency.
class BasketScenariosDto {
  const BasketScenariosDto(this.result);

  factory BasketScenariosDto.fromJson(Map<String, dynamic> json) {
    final currency = _nonBlank(json['currency']) ?? 'NPR';
    Money money(Object? raw) =>
        Money(amount: _double(raw) ?? 0, currency: currency);

    return BasketScenariosDto(
      BasketScenarios(
        currency: currency,
        budget: _double(json['budget']),
        scenarios: _maps(json['scenarios'])
            .map(
              (s) => BasketScenario(
                kind: parseBasketScenarioKind(s['kind']),
                title: _string(s['title']),
                // Missing means "not flagged infeasible" — don't mute it.
                feasible: s['feasible'] != false,
                summary: _string(s['summary']),
                changes: _strings(s['changes']),
                lines: _maps(s['lines'])
                    .map(
                      (l) => BasketScenarioLine(
                        cartLineId: _nonBlank(l['cartLineId']),
                        productId: _string(l['productId']),
                        productVariantId: _string(l['productVariantId']),
                        title: _string(l['title']),
                        quantity: _int(l['quantity']) ?? 0,
                        unitPrice: money(l['unitPriceAmount']),
                        kept: l['kept'] == true,
                        change: parseBasketLineChange(l['change']),
                      ),
                    )
                    .toList(growable: false),
                subtotal: money(s['subtotalAmount']),
                tax: money(s['taxAmount']),
                grandTotal: money(s['grandTotalAmount']),
                difference: money(s['differenceAmount']),
                sellerCount: _int(s['sellerCount']) ?? 0,
                dispatchDays: _int(s['dispatchDays']) ?? 0,
                itemsAtStockRisk: _int(s['itemsAtStockRisk']) ?? 0,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  final BasketScenarios result;

  BasketScenarios toDomain() => result;
}

/// Backend `BasketScenarioKind`: 1 AsItIs, 2 WithinBudget, 3 LowerCost,
/// 4 FasterDispatch.
BasketScenarioKind parseBasketScenarioKind(Object? raw) => _parseEnum(
  raw,
  const [
    BasketScenarioKind.asItIs,
    BasketScenarioKind.withinBudget,
    BasketScenarioKind.lowerCost,
    BasketScenarioKind.fasterDispatch,
  ],
  BasketScenarioKind.unknown,
);

/// Backend `BasketLineChange`: 1 Unchanged, 2 QuantityReduced, 3 Removed,
/// 4 Swapped.
BasketLineChange parseBasketLineChange(Object? raw) => _parseEnum(
  raw,
  const [
    BasketLineChange.unchanged,
    BasketLineChange.quantityReduced,
    BasketLineChange.removed,
    BasketLineChange.swapped,
  ],
  BasketLineChange.unknown,
);

/// Ints count from 1 in [ordered]; names match ignoring case, spaces,
/// underscores and hyphens.
T _parseEnum<T extends Enum>(Object? raw, List<T> ordered, T fallback) {
  final text = '${raw ?? ''}'.trim();
  final asInt = raw is num ? raw.toInt() : int.tryParse(text);
  if (asInt != null) {
    return asInt >= 1 && asInt <= ordered.length
        ? ordered[asInt - 1]
        : fallback;
  }
  final key = text.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
  for (final value in ordered) {
    if (value.name.toLowerCase() == key) return value;
  }
  return fallback;
}

Iterable<Map<String, dynamic>> _maps(Object? raw) => raw is List
    ? raw.whereType<Map<String, dynamic>>()
    : const <Map<String, dynamic>>[];

List<String> _strings(Object? raw) => raw is List
    ? raw
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false)
    : const <String>[];

String _string(Object? raw) => raw is String ? raw.trim() : '';

String? _nonBlank(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

int? _int(Object? raw) =>
    raw is num ? raw.toInt() : (raw is String ? int.tryParse(raw) : null);

double? _double(Object? raw) =>
    raw is num ? raw.toDouble() : (raw is String ? double.tryParse(raw) : null);
