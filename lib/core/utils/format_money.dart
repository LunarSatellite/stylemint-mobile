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

/// [money] in compact form for small chips: "Rs 950", "Rs 1.8K", "Rs 2.5M".
/// Amounts in other currencies are prefixed with their code ("USD 1.8K").
String formatMoneyCompact(Money money) {
  final prefix = money.currency == 'NPR' ? 'Rs ' : '${money.currency} ';
  final text = formatCompactNumber(money.amount);
  return text.startsWith('-')
      ? '-$prefix${text.substring(1)}'
      : '$prefix$text';
}

/// Short form of [value]: 950, 1K, 1.8K, 12.5K, 125K, 3.4M, 2B.
///
/// Rounds to a whole number first, keeps one decimal while the scaled value
/// is below 100, drops a trailing ".0", and moves to the next unit when
/// rounding reaches 1000 of the current one (999,999 is "1M", not "1000K").
String formatCompactNumber(num value) {
  if (!value.isFinite) return '0';
  final rounded = value.abs().roundToDouble();
  final sign = value < 0 && rounded != 0 ? '-' : '';
  if (rounded < 1000) return '$sign${rounded.toStringAsFixed(0)}';

  const units = <(double, String)>[(1e3, 'K'), (1e6, 'M'), (1e9, 'B')];
  for (var i = 0; i < units.length; i++) {
    final (unit, suffix) = units[i];
    final isLast = i == units.length - 1;
    if (!isLast && rounded >= units[i + 1].$1) continue;
    final scaled = rounded / unit;
    var text = scaled.toStringAsFixed(scaled < 100 ? 1 : 0);
    if (!isLast && double.parse(text) >= 1000) continue;
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return '$sign$text$suffix';
  }
  return '$sign${rounded.toStringAsFixed(0)}';
}
