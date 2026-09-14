import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

Money _npr(double amount) => Money(amount: amount, currency: 'NPR');

void main() {
  group('formatCompactNumber', () {
    test('keeps whole numbers below a thousand', () {
      expect(formatCompactNumber(0), '0');
      expect(formatCompactNumber(950), '950');
      expect(formatCompactNumber(999.4), '999');
    });

    test('shortens thousands, millions and billions', () {
      expect(formatCompactNumber(1000), '1K');
      expect(formatCompactNumber(1200), '1.2K');
      expect(formatCompactNumber(12500), '12.5K');
      expect(formatCompactNumber(125000), '125K');
      expect(formatCompactNumber(3400000), '3.4M');
      expect(formatCompactNumber(2000000000), '2B');
    });

    test('moves to the next unit when rounding reaches it', () {
      expect(formatCompactNumber(999.6), '1K');
      expect(formatCompactNumber(999999), '1M');
    });

    test('handles negative and non-finite values', () {
      expect(formatCompactNumber(-1800), '-1.8K');
      expect(formatCompactNumber(double.nan), '0');
      expect(formatCompactNumber(double.infinity), '0');
    });
  });

  group('formatMoneyCompact', () {
    test('prefixes rupees with Rs', () {
      expect(formatMoneyCompact(_npr(1800)), 'Rs 1.8K');
      expect(formatMoneyCompact(_npr(950)), 'Rs 950');
      expect(formatMoneyCompact(_npr(2500000)), 'Rs 2.5M');
    });

    test('rounds paisa to whole rupees', () {
      expect(formatMoneyCompact(_npr(499.99)), 'Rs 500');
    });

    test('keeps the sign in front of the currency', () {
      expect(formatMoneyCompact(_npr(-1800)), '-Rs 1.8K');
    });

    test('uses the currency code for other currencies', () {
      expect(
        formatMoneyCompact(const Money(amount: 1800, currency: 'USD')),
        'USD 1.8K',
      );
    });
  });
}
