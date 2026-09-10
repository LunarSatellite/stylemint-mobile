import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

/// Device-local appearance preference. Appearance is intentionally not sent
/// to the API: it controls this installation's rendering, not account data.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  // Every screen hardcodes dark DesignTokens colors rather than reading
  // Theme.of(context), so ThemeMode.system/light only mismatch native
  // Material widgets (dialogs, text selection) against the rest of the
  // app without changing anything else — dark is the only mode that
  // actually looks consistent, so it's the default and the only one the
  // Appearance picker offers.
  ThemeModeNotifier() : super(ThemeMode.dark) {
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_themeModeKey);
    state = switch (value) {
      'light' => ThemeMode.light,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
  }
}
