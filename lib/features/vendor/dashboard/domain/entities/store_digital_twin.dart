class StoreDigitalTwin {
  const StoreDigitalTwin({
    required this.activeProductCount,
    required this.outOfStockProductCount,
    required this.lowStockVariantCount,
    required this.totalUnitsOnHand,
    required this.activeFlashSaleCount,
    required this.unitsSoldLast7Days,
    required this.generatedUtc,
  });

  final int activeProductCount;
  final int outOfStockProductCount;
  final int lowStockVariantCount;
  final int totalUnitsOnHand;
  final int activeFlashSaleCount;
  final int unitsSoldLast7Days;
  final DateTime generatedUtc;

  factory StoreDigitalTwin.fromJson(Map<String, dynamic> json) {
    int count(String key) => (json[key] as num?)?.toInt() ?? 0;
    return StoreDigitalTwin(
      activeProductCount: count('activeProductCount'),
      outOfStockProductCount: count('outOfStockProductCount'),
      lowStockVariantCount: count('lowStockVariantCount'),
      totalUnitsOnHand: count('totalUnitsOnHand'),
      activeFlashSaleCount: count('activeFlashSaleCount'),
      unitsSoldLast7Days: count('unitsSoldLast7Days'),
      generatedUtc:
          DateTime.tryParse(json['generatedUtc'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
