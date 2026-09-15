import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/theme/typography.dart';

/// Material themes for Style Mint.
///
/// Every colour comes from [DesignTokens] and every Material text style is
/// Poppins. The editorial display face (Instrument Serif) is never applied
/// theme-wide — hero and section titles opt in via `DesignTokens.display*`.
abstract class AppTheme {
  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData get light => _build(_lightScheme);

  // ── Dark (the app's default) ──────────────────────────────────────────────
  static ThemeData get dark => _build(_darkScheme);

  // ── Builder ───────────────────────────────────────────────────────────────
  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final applied = AppTextTheme.staticTheme.apply(
      fontFamily: DesignTokens.fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final textTheme = applied.copyWith(
      bodySmall: applied.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      labelSmall: applied.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
    );
    final fieldRadius = BorderRadius.circular(10);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      fontFamily: DesignTokens.fontFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        // Explicit systemNavigationBarColor here (not just the .dark/.light
        // shorthand) because AppBar wraps this in its own AnnotatedRegion,
        // which sits deeper in the tree than the app root's and wins —
        // the shorthand presets don't pin the nav bar color, so it fell
        // through to Android's own default (light grey) on any screen with
        // an AppBar, clashing against this app's near-black UI.
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(
                systemNavigationBarColor: DesignTokens.lightSurface,
                systemNavigationBarIconBrightness: Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.light.copyWith(
                // The dark background every screen renders against.
                systemNavigationBarColor: DesignTokens.bgAppFoundation,
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
      ),
      dividerTheme: DividerThemeData(
        color: isLight
            ? DesignTokens.lightSurfaceContainerHigh
            : DesignTokens.bgAppBodyLight,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? DesignTokens.lightSurfaceContainer
            : DesignTokens.inputFieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: isLight
              ? DesignTokens.textContentSecondary
              : DesignTokens.inputFieldPlaceholder,
          fontSize: 14,
        ),
        errorStyle: TextStyle(color: scheme.error, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: isLight
              ? DesignTokens.lightSurfaceContainerHigh
              : DesignTokens.bgAppBodyLight,
          disabledForegroundColor: DesignTokens.textMuted,
          minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(360),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(360),
          ),
          textStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: DesignTokens.primaryGreen,
    onPrimary: DesignTokens.buttonPrimaryText,
    primaryContainer: DesignTokens.primaryGreenLight,
    onPrimaryContainer: DesignTokens.textWhite,
    secondary: DesignTokens.secondaryYellow,
    onSecondary: DesignTokens.textDark,
    tertiary: DesignTokens.colorInfo,
    onTertiary: DesignTokens.textDark,
    error: DesignTokens.colorError,
    onError: DesignTokens.textDark,
    surface: DesignTokens.lightSurface,
    onSurface: DesignTokens.textDark,
    onSurfaceVariant: DesignTokens.textContentSecondary,
    surfaceContainerLowest: DesignTokens.lightSurface,
    surfaceContainerLow: DesignTokens.lightSurfaceContainer,
    surfaceContainer: DesignTokens.lightSurfaceContainer,
    surfaceContainerHigh: DesignTokens.lightSurfaceContainerHigh,
    surfaceContainerHighest: DesignTokens.textLight,
    outline: DesignTokens.textMuted,
    outlineVariant: DesignTokens.lightSurfaceContainerHigh,
    shadow: DesignTokens.baseBlack,
    scrim: DesignTokens.baseBlack,
    inverseSurface: DesignTokens.bgAppBody,
    onInverseSurface: DesignTokens.textWhite,
    inversePrimary: DesignTokens.primaryGreen,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: DesignTokens.primaryGreen,
    onPrimary: DesignTokens.buttonPrimaryText,
    primaryContainer: DesignTokens.primaryGreenLight,
    onPrimaryContainer: DesignTokens.textWhite,
    secondary: DesignTokens.secondaryYellow,
    onSecondary: DesignTokens.textDark,
    secondaryContainer: DesignTokens.warningFillDark,
    onSecondaryContainer: DesignTokens.warningTextLight,
    tertiary: DesignTokens.colorInfo,
    onTertiary: DesignTokens.textDark,
    tertiaryContainer: DesignTokens.infoFillDark,
    onTertiaryContainer: DesignTokens.infoTextLight,
    error: DesignTokens.colorError,
    onError: DesignTokens.textDark,
    surface: DesignTokens.bgAppFoundation,
    onSurface: DesignTokens.textWhite,
    onSurfaceVariant: DesignTokens.textMuted,
    surfaceContainerLowest: DesignTokens.baseBlack,
    surfaceContainerLow: DesignTokens.bgAppBody,
    surfaceContainer: DesignTokens.bgAppBody,
    surfaceContainerHigh: DesignTokens.surfaceRaised,
    surfaceContainerHighest: DesignTokens.bgAppBodyLight,
    outline: DesignTokens.inputFieldBorder,
    outlineVariant: DesignTokens.borderDefault,
    shadow: DesignTokens.baseBlack,
    scrim: DesignTokens.baseBlack,
    inverseSurface: DesignTokens.textWhite,
    onInverseSurface: DesignTokens.textDark,
    inversePrimary: DesignTokens.primaryGreenDark,
  );
}
