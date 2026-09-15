import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Card density.
enum MallCardSize { compact, regular }

/// Layout maths shared by kit cards, their skeletons and rails.
///
/// Horizontal rails need a fixed height. Cards reserve fixed-height slots for
/// their text computed here from the ambient text scale, so a rail sized with
/// a card's `heightFor` always matches what the card renders — at 1.0× or
/// 1.3× — without overflow.
abstract final class MallMetrics {
  /// Height, rounded up to whole pixels, of [lines] lines of text set at
  /// [fontSize] with the line-height multiplier [lineHeight], at the text
  /// scale of [scaler].
  static double textHeight(
    TextScaler scaler, {
    required double fontSize,
    required double lineHeight,
    int lines = 1,
  }) => (scaler.scale(fontSize) * lineHeight * lines).ceilToDouble();

  static TextScaler scalerOf(BuildContext context) =>
      MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Whole rupees read cleaner on cards ("Rs 3,499"); paisa show only when
  /// the amount actually has them.
  static int priceDigits(Money money) =>
      money.amount == money.amount.truncateToDouble() ? 0 : 2;
}
