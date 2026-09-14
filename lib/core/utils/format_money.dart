import 'package:intl/intl.dart';
import '../../shared/domain/entities/money.dart';

/// Formats a [Money] value for display.
/// NPR always shown with "Rs " prefix.
///
/// [decimalDigits] defaults to 2 ("Rs 1,234.56"); pass 0 for whole-rupee
/// copy such as reel captions ("Rs 8,999").
String formatMoney(Money money, {String? locale, int decimalDigits = 2}) {
  if (money.currency == 'NPR') {
    final fmt = NumberFormat.currency(
      locale: locale ?? 'en_US',
      symbol: 'Rs ',
      decimalDigits: decimalDigits,
    );
    return fmt.format(money.amount);
  }
  return NumberFormat.currency(
    locale: locale ?? 'en_US',
    name: money.currency,
    decimalDigits: decimalDigits,
  ).format(money.amount);
}
