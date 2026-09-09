import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/busy/busy_overlay.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/design_tokens.dart';
import 'theme/theme_mode_provider.dart';

class StyleMintApp extends ConsumerWidget {
  const StyleMintApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Style Mint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      // Global, non-blocking "please wait" bar shown while any API call runs.
      //
      // Also pins the Android system navigation bar (3-button or gesture
      // pill) to match the app background everywhere — previously only
      // AppBarTheme.systemOverlayStyle set this, which only takes effect
      // while a screen with an AppBar is on top. Shells, bottom sheets, and
      // AppBar-less screens fell back to Android's own default (light grey),
      // clashing hard against this app's near-black UI on 3-button-nav
      // devices.
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: isDark
                ? DesignTokens.bgAppFoundation
                : Colors.white,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: BusyOverlay(child: child ?? const SizedBox.shrink()),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh'),
        Locale('ne'),
        Locale('es'),
        Locale('hi'),
      ],
    );
  }
}
