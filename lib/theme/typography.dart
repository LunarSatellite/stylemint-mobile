import 'package:flutter/material.dart';
import 'colors.dart';

/// Style Mint text theme — tablet-responsive, adapted from vpt-mydawa pattern.
abstract class AppTextTheme {
  static TextTheme build(BuildContext context) {
    final base = Theme.of(context).textTheme;
    final double s = MediaQuery.of(context).size.shortestSide >= 600 ? 1.25 : 1.0;

    return base.copyWith(
      // ── Display / Heading ────────────────────────────────────────────────
      displayLarge:   base.displayLarge?.copyWith(fontSize: 28 * s, color: kTextColor, fontWeight: FontWeight.w700),
      displayMedium:  base.displayMedium?.copyWith(fontSize: 24 * s, color: kTextColor, fontWeight: FontWeight.w700),
      displaySmall:   base.displaySmall?.copyWith(fontSize: 22 * s, color: kTextColor, fontWeight: FontWeight.w600),
      headlineLarge:  base.headlineLarge?.copyWith(fontSize: 20 * s, color: kTextColor, fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 18 * s, color: kTextColor, fontWeight: FontWeight.w600),
      headlineSmall:  base.headlineSmall?.copyWith(fontSize: 16 * s, color: kTextColor, fontWeight: FontWeight.w600),
      // ── Title ────────────────────────────────────────────────────────────
      titleLarge:     base.titleLarge?.copyWith(fontSize: 15 * s, color: kTextColor, fontWeight: FontWeight.w600),
      titleMedium:    base.titleMedium?.copyWith(fontSize: 14 * s, color: kTextColor, fontWeight: FontWeight.w400),
      titleSmall:     base.titleSmall?.copyWith(fontSize: 13 * s, color: kTextColor, fontWeight: FontWeight.w400),
      // ── Body ─────────────────────────────────────────────────────────────
      bodyLarge:      base.bodyLarge?.copyWith(fontSize: 14 * s, color: kTextColor, height: 1.5),
      bodyMedium:     base.bodyMedium?.copyWith(fontSize: 13 * s, color: kTextColor, height: 1.5),
      bodySmall:      base.bodySmall?.copyWith(fontSize: 12 * s, color: kTextSecondary, height: 1.4),
      // ── Label ────────────────────────────────────────────────────────────
      labelLarge:     base.labelLarge?.copyWith(fontSize: 14 * s, fontWeight: FontWeight.w600),
      labelMedium:    base.labelMedium?.copyWith(fontSize: 12 * s, fontWeight: FontWeight.w500),
      labelSmall:     base.labelSmall?.copyWith(fontSize: 10 * s, color: kTextSecondary),
    );
  }

  /// Static text theme used at ThemeData construction time (before context).
  static const TextTheme staticTheme = TextTheme(
    displayLarge:   TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kTextColor),
    displayMedium:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kTextColor),
    displaySmall:   TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kTextColor),
    headlineLarge:  TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kTextColor),
    headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kTextColor),
    headlineSmall:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextColor),
    titleLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextColor),
    titleMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: kTextColor),
    titleSmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: kTextColor),
    bodyLarge:      TextStyle(fontSize: 14, height: 1.5, color: kTextColor),
    bodyMedium:     TextStyle(fontSize: 13, height: 1.5, color: kTextColor),
    bodySmall:      TextStyle(fontSize: 12, height: 1.4, color: kTextSecondary),
    labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall:     TextStyle(fontSize: 10, color: kTextSecondary),
  );
}
