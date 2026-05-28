import 'package:intl/intl.dart';
import '../../shared/domain/entities/money.dart';

/// Formats a [Money] value for display.
/// NPR always shown with "Rs " prefix.
String formatMoney(Money money, {String? locale}) {
  if (money.currency == 'NPR') {
    final fmt = NumberFormat.currency(
      locale: locale ?? 'en_US',
      symbol: 'Rs ',
      decimalDigits: 2,
    );
    return fmt.format(money.amount);
  }
  return NumberFormat.currency(
    locale: locale ?? 'en_US',
    name: money.currency,
    decimalDigits: 2,
  ).format(money.amount);
}
