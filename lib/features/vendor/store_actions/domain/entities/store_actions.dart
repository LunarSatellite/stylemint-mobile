import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Voyager "Autonomous Retail Operations" — the vendor's store as a short,
/// ranked to-do list: restock what is selling out, promote stock that isn't
/// moving, add photos to live products. Recommendations only; nothing changes
/// until the vendor acts. Backend `StoreActionQueue`.
class StoreActionQueue {
  const StoreActionQueue({required this.actions, this.generatedUtc});

  /// Most urgent first, in the order the backend ranked them.
  final List<StoreAction> actions;
  final DateTime? generatedUtc;

  bool get isEmpty => actions.isEmpty;
}

/// What a store action asks the vendor to do. Backend `StoreActionKind`.
enum StoreActionKind {
  /// Stock will run out within a week at the current pace.
  restockSoon,

  /// Sold out while it was still selling.
  soldOutWhileSelling,

  /// Plenty in stock and nothing sold for 30 days.
  slowMovingStock,

  /// A live product with no photos.
  addProductImages,

  /// A kind this app version doesn't know yet.
  unknown,
}

/// How soon a store action matters. Backend `StoreActionSeverity`.
enum StoreActionSeverity { high, medium, low }

class StoreAction {
  const StoreAction({
    required this.kind,
    required this.severity,
    required this.productId,
    required this.productName,
    required this.recommendation,
    this.productVariantId,
    this.sku,
    this.evidence = const <String>[],
    this.valueAtStake,
  });

  final StoreActionKind kind;
  final StoreActionSeverity severity;
  final String productId;
  final String? productVariantId;
  final String productName;
  final String? sku;

  /// The backend's one-sentence message, e.g. "Restock Linen shirt (LS-M):
  /// about 2 days of stock left at this week's pace."
  final String recommendation;

  /// Short facts behind the recommendation, e.g. "12 sold in the last 7 days".
  final List<String> evidence;

  /// Sales at risk for stock actions, or the value of unsold stock for
  /// slow-moving stock. Null when no money figure applies.
  final Money? valueAtStake;
}
