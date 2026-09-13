import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Voyager "Counterfactual Basket Laboratory" — the shopper's cart next to
/// alternatives built from it (within a budget, lower cost, ready sooner),
/// each with its total, dispatch time, seller count, stock risk and every
/// change explained. Read-only: nothing here modifies the cart. Backend
/// `BasketLab`.
class BasketScenarios {
  const BasketScenarios({
    required this.currency,
    required this.scenarios,
    this.budget,
  });

  final String currency;

  /// The budget the scenarios were built for, when one was given.
  final double? budget;
  final List<BasketScenario> scenarios;
}

/// Which alternative a scenario explores.
enum BasketScenarioKind {
  asItIs,
  withinBudget,
  lowerCost,
  fasterDispatch,
  unknown,
}

/// What happened to a cart line in a scenario.
enum BasketLineChange { unchanged, quantityReduced, removed, swapped, unknown }

class BasketScenario {
  const BasketScenario({
    required this.kind,
    required this.title,
    required this.feasible,
    required this.summary,
    required this.changes,
    required this.lines,
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
    required this.difference,
    required this.sellerCount,
    required this.dispatchDays,
    required this.itemsAtStockRisk,
  });

  final BasketScenarioKind kind;
  final String title;

  /// False when this alternative can't be built from the cart (e.g. the
  /// items to keep already cost more than the budget).
  final bool feasible;
  final String summary;

  /// Plain sentences, one per change from the current cart.
  final List<String> changes;
  final List<BasketScenarioLine> lines;
  final Money subtotal;
  final Money tax;
  final Money grandTotal;

  /// Grand total minus the current cart's; negative means cheaper.
  final Money difference;

  /// How many sellers the order would ship from.
  final int sellerCount;

  /// Days until every item is ready to ship; the slowest item sets it.
  final int dispatchDays;

  /// Items with fewer units in stock than the quantity wanted.
  final int itemsAtStockRisk;
}

class BasketScenarioLine {
  const BasketScenarioLine({
    required this.productId,
    required this.productVariantId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.kept,
    required this.change,
    this.cartLineId,
  });

  /// The cart line this came from; null for a product swapped in.
  final String? cartLineId;
  final String productId;
  final String productVariantId;
  final String title;
  final int quantity;
  final Money unitPrice;
  final bool kept;
  final BasketLineChange change;
}
