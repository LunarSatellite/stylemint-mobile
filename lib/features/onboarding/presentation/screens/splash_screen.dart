import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Splash — the logo comes up from dim to lit while light runs around its
/// edge, then session bootstrap starts. The router's redirect owns the
/// navigation: once the session resolves, the redirect sends the user to home
/// (authenticated) or onboarding (unauthenticated). Splash does NOT call
/// `context.go` itself — doing so raced with the redirect and could strand
/// the user on splash.
///
/// There is no local-biometric "app unlock" gate here: it was redundant with
/// the passkey/session login and re-fired in a loop on some devices.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// How long the logo shows before bootstrap. Bootstrap publishes the
  /// session at once and the router redirects straight away, so the hold
  /// comes first: long enough for the logo to light up and the light to
  /// circle it once.
  static const _hold = Duration(milliseconds: 1700);

  /// Logo from dim to lit, then the wordmark and tagline.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// The light's laps around the logo's edge.
  late final AnimationController _lap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  late final Animation<double> _lit = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.7, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.6, 1, curve: Curves.easeOutCubic),
  );

  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _intro.value = 1;
      _lap.value = 0.1;
    } else {
      unawaited(_intro.forward());
      unawaited(_lap.repeat());
    }
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(_hold);
    if (!mounted) return;
    await ref.read(sessionControllerProvider.notifier).bootstrap();
  }

  @override
  void dispose() {
    _intro.dispose();
    _lap.dispose();
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
            Semantics(
              label: 'StyleMint',
              image: true,
              child: SizedBox.square(
                dimension: 188,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(_lit),
                  child: SmLuminousMark(
                    lap: _lap,
                    brightness: _lit,
                    halo: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s32),
            FadeTransition(
              opacity: _wordmark,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_wordmark),
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Style',
                        style: TextStyle(color: DesignTokens.textWhite),
                      ),
                      TextSpan(
                        text: 'Mint',
                        style: TextStyle(color: DesignTokens.primaryGreen),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 36,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            FadeTransition(
              opacity: _tagline,
              child: Text(
                'Shop, Create, Sell, All in Reels',
                textAlign: TextAlign.center,
                style: DesignTokens.sectionInnerTitle.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
