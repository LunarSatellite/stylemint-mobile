import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/security/local_auth_service.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Splash — bootstraps the session, then:
/// - authenticated → biometric/device unlock (local_auth) → [RouteNames.home]
/// - unauthenticated → [RouteNames.onboarding]
///
/// The unlock gates an already-persisted session ("open app → biometric → in").
/// If the device can't authenticate locally, entry isn't blocked.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _unlockFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await ref.read(sessionControllerProvider.notifier).bootstrap();
    if (!mounted) return;
    if (ref.read(sessionControllerProvider).isAuthenticated) {
      await _unlockAndEnter();
    } else {
      context.go(RouteNames.onboarding);
    }
  }

  Future<void> _unlockAndEnter() async {
    final auth = ref.read(localAuthServiceProvider);
    // If the device can't do local auth, don't lock the user out.
    if (!await auth.isAvailable()) {
      if (mounted) context.go(RouteNames.home);
      return;
    }
    final ok = await auth.authenticate();
    if (!mounted) return;
    if (ok) {
      context.go(RouteNames.home);
    } else {
      setState(() => _unlockFailed = true);
    }
  }

  Future<void> _signOut() async {
    await ref.read(sessionControllerProvider.notifier).logout();
    if (mounted) context.go(RouteNames.signInMethod);
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
            if (_unlockFailed) ...[
              const Icon(Icons.lock_outline,
                  color: DesignTokens.textMuted, size: 28),
              const SizedBox(height: DesignTokens.s12),
              Text('Unlock to continue', style: DesignTokens.bodyText),
              const SizedBox(height: DesignTokens.s16),
              TextButton(
                onPressed: () {
                  setState(() => _unlockFailed = false);
                  _unlockAndEnter();
                },
                child: Text('Unlock',
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.primaryGreen)),
              ),
              TextButton(
                onPressed: _signOut,
                child: Text('Sign out',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textMuted)),
              ),
            ] else
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
