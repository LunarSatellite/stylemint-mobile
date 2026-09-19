import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/store_digital_twin.dart';

void main() {
  test('parses the live store digital twin contract', () {
    final snapshot = StoreDigitalTwin.fromJson({
      'activeProductCount': 18,
      'outOfStockProductCount': 2,
      'lowStockVariantCount': 4,
      'totalUnitsOnHand': 126,
      'activeFlashSaleCount': 1,
      'unitsSoldLast7Days': 39,
      'generatedUtc': '2026-09-17T08:45:00Z',
    });

    expect(snapshot.activeProductCount, 18);
    expect(snapshot.outOfStockProductCount, 2);
    expect(snapshot.lowStockVariantCount, 4);
    expect(snapshot.totalUnitsOnHand, 126);
    expect(snapshot.activeFlashSaleCount, 1);
    expect(snapshot.unitsSoldLast7Days, 39);
    expect(snapshot.generatedUtc, DateTime.utc(2026, 9, 17, 8, 45));
  });

  test('defaults sparse counters safely for a new store', () {
    final snapshot = StoreDigitalTwin.fromJson(const {});

    expect(snapshot.activeProductCount, 0);
    expect(snapshot.totalUnitsOnHand, 0);
    expect(snapshot.generatedUtc.millisecondsSinceEpoch, 0);
  });
}
