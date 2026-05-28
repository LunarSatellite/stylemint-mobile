import 'package:flutter/material.dart';
import '../../../core/utils/format_money.dart';
import '../../domain/entities/money.dart';

/// Renders a [Money] value as "Rs 1,234.56".
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.money, {
    super.key,
    this.style,
    this.locale,
  });

  final Money money;
  final TextStyle? style;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatMoney(money, locale: locale),
      style: style,
    );
  }
}
