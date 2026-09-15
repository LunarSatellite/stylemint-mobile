import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Renders a [Money] value as "Rs 1,234.56".
///
/// Pass `decimalDigits: 0` for whole-rupee display ("Rs 1,235"), as used on
/// product cards.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.money, {
    super.key,
    this.style,
    this.locale,
    this.decimalDigits = 2,
    this.maxLines,
    this.semanticsLabel,
  });

  final Money money;
  final TextStyle? style;
  final String? locale;
  final int decimalDigits;
  final int? maxLines;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatMoney(money, locale: locale, decimalDigits: decimalDigits),
      style: style,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
    );
  }
}
