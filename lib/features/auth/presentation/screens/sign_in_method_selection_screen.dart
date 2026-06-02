import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Auth entry — **fingerprint / passkey first**.
///
/// The default screen is intentionally just the fingerprint CTA (no method
/// buttons). Passkey is the highest-priority path; email / phone / social and
/// "Create account" (Plan B) are collapsed behind "More ways to continue" and
/// shown only on demand or when passkey isn't viable.
///
/// NOTE: true passkey login (token-issuing, usernameless) + passkey-only
/// account creation are pending backend issues #20/#21/#22/#23. Until then the
/// fingerprint CTA routes to the passkey screen and new users fall back to
/// Plan B (Create account).
class SignInMethodSelectionScreen extends StatefulWidget {
  const SignInMethodSelectionScreen({super.key});

  @override
  State<SignInMethodSelectionScreen> createState() =>
      _SignInMethodSelectionScreenState();
}

class _SignInMethodSelectionScreenState
    extends State<SignInMethodSelectionScreen> {
  bool _showMore = false;

  void _continueWithPasskey() => context.push(RouteNames.passkey);

  static void _comingSoon(BuildContext context, String provider) {
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s4,
                  DesignTokens.s16,
                  DesignTokens.s24,
                ),
                child: Column(
                  children: [
                    // ---- Header ----
                    Text(
                      'Welcome to Stylemint',
                      textAlign: TextAlign.center,
                      style: DesignTokens.titleMedium,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      'Sign in with your fingerprint — fast, secure, '
                      'no passwords.',
                      textAlign: TextAlign.center,
                      style: DesignTokens.bodyText,
                    ),
                    const SizedBox(height: DesignTokens.s40),

                    // ---- Fingerprint hero (the primary CTA) ----
                    _FingerprintHero(onTap: _continueWithPasskey),
                    const SizedBox(height: DesignTokens.s24),

                    SizedBox(
                      width: double.infinity,
                      child: SmFingerprintButton(onPressed: _continueWithPasskey),
                    ),
                    const SizedBox(height: DesignTokens.s16),

                    // ---- Plan B: collapsed by default ----
                    if (!_showMore)
                      TextButton(
                        onPressed: () => setState(() => _showMore = true),
                        child: Text(
                          'More ways to continue',
                          style: DesignTokens.mediumSemibold
                              .copyWith(color: DesignTokens.primaryGreen),
                        ),
                      )
                    else
                      _PlanB(onComingSoon: (p) => _comingSoon(context, p)),
                  ],
                ),
              ),
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

/// Large tappable fingerprint disc — the focal point of the entry screen.
class _FingerprintHero extends StatelessWidget {
  const _FingerprintHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DesignTokens.chipsSelectedFill,
          border: Border.all(color: DesignTokens.primaryGreen, width: 2),
        ),
        child: const Icon(
          Icons.fingerprint,
          size: 72,
          color: DesignTokens.primaryGreen,
        ),
      ),
    );
  }
}

/// Primary "Continue with Fingerprint" button.
class SmFingerprintButton extends StatelessWidget {
  const SmFingerprintButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesignTokens.buttonHeight,
      child: Material(
        color: DesignTokens.primaryGreen,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint,
                  color: DesignTokens.buttonPrimaryText, size: DesignTokens.iconMedium),
              const SizedBox(width: DesignTokens.s8),
              Text(
                'Continue with Fingerprint',
                style: DesignTokens.oneLinerSemibold
                    .copyWith(color: DesignTokens.buttonPrimaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plan B — revealed only via "More ways to continue".
class _PlanB extends StatelessWidget {
  const _PlanB({required this.onComingSoon});

  final void Function(String provider) onComingSoon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: DesignTokens.s8),
        _MethodRow(
          icon: Icons.mail_rounded,
          iconTileColor: DesignTokens.bgAppBodyLight,
          iconColor: DesignTokens.textLight,
          title: 'Continue with Email',
          description: 'Use your email to sign-in',
          onTap: () => context.push(RouteNames.email),
        ),
        _MethodRow(
          icon: Icons.phone_iphone,
          iconTileColor: DesignTokens.bgAppBodyLight,
          iconColor: DesignTokens.textLight,
          title: 'Continue with Phone No.',
          description: 'Use your phone No. to sign-in',
          onTap: () => context.push(RouteNames.login),
        ),
        const SizedBox(height: DesignTokens.s16),

        // Create account
        Center(
          child: GestureDetector(
            onTap: () => context.push(RouteNames.register),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'New to Style Mint? ',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textLight),
                  ),
                  TextSpan(
                    text: 'Create account',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.s24),

        // Divider
        Row(
          children: [
            const Expanded(
              child: Divider(color: DesignTokens.borderDefault, height: 1),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
              child: Text(
                'Or Continue With',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textLight),
              ),
            ),
            const Expanded(
              child: Divider(color: DesignTokens.borderDefault, height: 1),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s24),

        // Social
        _SocialButton(
          assetPath: 'assets/icons/apple.svg',
          label: 'Apple ID',
          onTap: () => onComingSoon('Apple'),
        ),
        const SizedBox(height: DesignTokens.s16),
        _SocialButton(
          assetPath: 'assets/icons/facebook.svg',
          label: 'Facebook ID',
          onTap: () => onComingSoon('Facebook'),
        ),
        const SizedBox(height: DesignTokens.s16),
        _SocialButton(
          assetPath: 'assets/icons/google.svg',
          label: 'Google ID',
          onTap: () => onComingSoon('Google'),
        ),
      ],
    );
  }
}

/// Minimal top app bar with a back chevron.
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: DesignTokens.bgAppFoundation,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(
          Icons.chevron_left_rounded,
          color: DesignTokens.textWhite,
          size: DesignTokens.iconMedium,
        ),
        onPressed: () {
          if (context.canPop()) context.pop();
        },
      ),
    );
  }
}

/// A tappable sign-in method row: [icon tile] [title + description] [chevron].
class _MethodRow extends StatelessWidget {
  final IconData icon;
  final Color iconTileColor;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _MethodRow({
    required this.icon,
    required this.iconTileColor,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8,
          vertical: DesignTokens.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconTileColor,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              child: Icon(icon, color: iconColor, size: DesignTokens.iconMedium),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.mediumRegular
                        .copyWith(color: DesignTokens.textWhite),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: DesignTokens.smallDescription),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.textLight,
              size: DesignTokens.iconSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width gray pill social button: [logo] [label].
class _SocialButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: Material(
        color: DesignTokens.buttonGrayFill,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(assetPath, width: 20, height: 20),
              const SizedBox(width: DesignTokens.s8),
              Text(label, style: DesignTokens.oneLinerSemibold),
            ],
          ),
        ),
      ),
    );
  }
}

/// Footer with Terms & Conditions / Privacy Policy green links.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final regular =
        DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite);
    final link =
        DesignTokens.mediumSemibold.copyWith(color: DesignTokens.primaryGreen);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s24,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'By Continuing you acknowledge that you read & agree our ',
              style: regular,
            ),
            TextSpan(text: 'Terms & Conditions', style: link),
            TextSpan(text: ' and ', style: regular),
            TextSpan(text: 'Privacy Policy', style: link),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
