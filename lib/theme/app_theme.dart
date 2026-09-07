import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'design_tokens.dart';
import 'typography.dart';

abstract class AppTheme {
  // ── Light ─────────────────────────────────────────────────────────────────
  static ThemeData get light => _build(_lightScheme, Brightness.light);

  // ── Dark ──────────────────────────────────────────────────────────────────
  static ThemeData get dark => _build(_darkScheme, Brightness.dark);

  // ── Builder ───────────────────────────────────────────────────────────────
  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Inter',
      textTheme: AppTextTheme.staticTheme,
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
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark.copyWith(
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.light.copyWith(
                // The actual dark background every screen renders against —
                // individual screens hardcode this directly on their
                // Scaffold rather than reading scheme.surface, so this (not
                // kSurfaceColorDark) is what the nav bar must match.
                systemNavigationBarColor: DesignTokens.bgAppFoundation,
                systemNavigationBarIconBrightness: Brightness.light,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
      ),
      dividerTheme: const DividerThemeData(
        color: kDividerColor,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kErrorColor, width: 1.5),
        ),
        hintStyle: const TextStyle(color: kHintTextColor, fontSize: 14),
        errorStyle: const TextStyle(color: kErrorColor, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(360)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimaryColor,
          side: const BorderSide(color: kPrimaryColor),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(360)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kPrimaryColor,
      ),
      iconTheme: const IconThemeData(color: kTextColor),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: kPrimaryColor,
    onPrimary: Colors.white,
    primaryContainer: kPrimaryLight,
    onPrimaryContainer: kPrimaryDark,
    secondary: kSecondaryColor,
    onSecondary: Colors.white,
    error: kErrorColor,
    onError: Colors.white,
    surface: kSurfaceColor,
    onSurface: kTextColor,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: kPrimaryColor,
    onPrimary: Colors.white,
    primaryContainer: kPrimaryDark,
    onPrimaryContainer: kPrimaryLight,
    secondary: kSecondaryColor,
    onSecondary: Colors.white,
    error: kErrorColor,
    onError: Colors.white,
    surface: kSurfaceColorDark,
    onSurface: Colors.white,
  );
}
