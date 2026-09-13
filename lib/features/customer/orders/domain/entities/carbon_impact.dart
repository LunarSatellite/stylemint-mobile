/// Voyager "Carbon impact of delivery" — the signed-in customer's
/// cumulative CO2 avoided by community (Traveler / Neighbor) delivery hops
/// compared with a traditional courier. Backend `CarbonSavingsDto`.
class CarbonImpact {
  const CarbonImpact({
    required this.kgCo2Saved,
    required this.deliveryCount,
    required this.comparedToTraditionalKg,
  });

  /// Kilograms of CO2 avoided across all completed hops.
  final double kgCo2Saved;

  /// Completed delivery hops the figure is computed from.
  final int deliveryCount;

  /// Kilograms a traditional courier would have emitted for the same hops.
  final double comparedToTraditionalKg;

  /// Whether there is anything worth showing — no completed hops, or hops
  /// that saved nothing (e.g. all standard-courier tiers), mean no card.
  bool get hasSavings => deliveryCount > 0 && kgCo2Saved > 0;

  /// Share of the traditional-courier emissions avoided, as a whole
  /// percentage in 1..100. Null when there is no baseline to compare to or
  /// the share rounds down to zero.
  int? get percentSaved {
    if (comparedToTraditionalKg <= 0 || kgCo2Saved <= 0) return null;
    final percent = (kgCo2Saved / comparedToTraditionalKg * 100)
        .round()
        .clamp(0, 100);
    return percent == 0 ? null : percent;
  }
}
