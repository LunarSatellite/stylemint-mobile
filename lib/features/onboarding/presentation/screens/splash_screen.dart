import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Splash — only kicks off session bootstrap. The router's redirect owns the
/// navigation: while the session is `unknown` the user stays here (spinner);
/// once it resolves, the redirect sends them to home (authenticated) or
/// onboarding (unauthenticated). Splash does NOT call `context.go` itself —
/// doing so raced with the redirect and could strand the user on splash.
///
/// There is no local-biometric "app unlock" gate here: it was redundant with
/// the passkey/session login and re-fired in a loop on some devices.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // Sets the session to authenticated/unauthenticated; the router redirect
    // (driven by its refreshListenable) then routes off splash.
    await ref.read(sessionControllerProvider.notifier).bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: DesignTokens.primaryGreen,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'STYLE MINT',
              style: DesignTokens.sectionInnerTitle.copyWith(
                color: DesignTokens.primaryGreen,
                letterSpacing: 3,
              ),
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
                valueColor: AlwaysStoppedAnimation(DesignTokens.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
