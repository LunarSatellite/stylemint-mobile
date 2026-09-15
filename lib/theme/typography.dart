import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Material [TextTheme] for Style Mint, set in Poppins.
///
/// Sizes and weights are the ones existing screens already rely on. No colours
/// are set here: `AppTheme` applies the colour scheme's onSurface and
/// onSurfaceVariant, so text reads correctly in both brightnesses.
///
/// The editorial display face (Instrument Serif) is deliberately not part of
/// the Material text theme — hero and section titles opt in through
/// `DesignTokens.displayHero` / `displayTitle` / `displaySection`.
abstract class AppTextTheme {
  static const String _family = DesignTokens.fontFamily;

  /// Tablet-responsive text theme: [staticTheme] scaled up 25% when the
  /// shortest side is at least 600dp, merged over the ambient theme.
  static TextTheme build(BuildContext context) {
    final factor = MediaQuery.sizeOf(context).shortestSide >= 600 ? 1.25 : 1.0;
    return Theme.of(
      context,
    ).textTheme.merge(staticTheme.apply(fontSizeFactor: factor));
  }

  /// Text theme used at ThemeData construction time (before a context exists).
  static const TextTheme staticTheme = TextTheme(
    // ── Display / Heading ──────────────────────────────────────────────────
    displayLarge: TextStyle(
      fontFamily: _family,
      fontSize: 28,
      fontWeight: FontWeight.w700,
    ),
    displayMedium: TextStyle(
      fontFamily: _family,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: TextStyle(
      fontFamily: _family,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: TextStyle(
      fontFamily: _family,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontFamily: _family,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: _family,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    // ── Title ──────────────────────────────────────────────────────────────
    titleLarge: TextStyle(
      fontFamily: _family,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: _family,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    titleSmall: TextStyle(
      fontFamily: _family,
      fontSize: 13,
      fontWeight: FontWeight.w400,
    ),
    // ── Body ───────────────────────────────────────────────────────────────
    bodyLarge: TextStyle(fontFamily: _family, fontSize: 14, height: 1.5),
    bodyMedium: TextStyle(fontFamily: _family, fontSize: 13, height: 1.5),
    bodySmall: TextStyle(fontFamily: _family, fontSize: 12, height: 1.4),
    // ── Label ──────────────────────────────────────────────────────────────
    labelLarge: TextStyle(
      fontFamily: _family,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontFamily: _family,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(fontFamily: _family, fontSize: 10),
  );
}
