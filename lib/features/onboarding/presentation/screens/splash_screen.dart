import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Splash screen — pixel-matched to Figma frame `9365:7950`.
///
/// Calls [SessionController.bootstrap] to read persisted tokens, then lets
/// the go_router redirect guard decide the next screen:
/// - authenticated → [RouteNames.home]
/// - unauthenticated → [RouteNames.onboarding]
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
    // Reads persisted tokens; transitions session from unknown →
    // authenticated / unauthenticated. The router's redirect guard will
    // forward to the right screen automatically.
    await ref.read(sessionControllerProvider.notifier).bootstrap();

    // If still on splash after bootstrap (unauthenticated), go to onboarding.
    if (mounted) {
      final session = ref.read(sessionControllerProvider);
      if (!session.isAuthenticated) {
        context.go(RouteNames.onboarding);
      }
      // Authenticated case: router redirect handles it (→ home).
    }
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
