import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Splash screen — pixel-matched to Figma frame `9365:7950`.
///
/// Centered brand logo + tagline "Shop, Create, Sell, All in Reels" + pulse
/// spinner. After a short delay it advances to the onboarding carousel.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // TODO: gate on a "seen onboarding" flag + auth session once token
    // persistence (Tasks 10–13) lands; for now always show onboarding.
    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) context.go(RouteNames.onboarding);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand logo (placeholder — TODO: real Figma logo asset)
            const Icon(Icons.shopping_bag_outlined,
                size: 72, color: DesignTokens.primaryGreen),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'STYLE MINT',
              style: DesignTokens.sectionInnerTitle
                  .copyWith(color: DesignTokens.primaryGreen, letterSpacing: 3),
            ),
            const SizedBox(height: DesignTokens.s24),
            Text(
              'Shop, Create, Sell, All in Reels',
              textAlign: TextAlign.center,
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation(DesignTokens.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
