import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Sign-In Method Selection — the auth entry point.
///
/// Pixel-matched to Figma frame `9684:9357` ("Login"):
/// - Title "Welcome to Stylemint" (22px) + subtitle (16px)
/// - Method rows (transparent): Passkey (Recommended), Email, Phone
///   • Passkey icon tile is yellow (#f1c40f); Email/Phone tiles dark (#27272a)
/// - "Or Continue With" divider
/// - Full-width gray pill social buttons: Apple ID, Facebook ID, Google ID
/// - Footer: Terms & Conditions / Privacy Policy (green links)
class SignInMethodSelectionScreen extends StatelessWidget {
  const SignInMethodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar — back chevron only (matches Figma)
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
                    Column(
                      children: [
                        Text(
                          'Welcome to Stylemint',
                          textAlign: TextAlign.center,
                          style: DesignTokens.titleMedium,
                        ),
                        const SizedBox(height: DesignTokens.s8),
                        Text(
                          "Let's get you in to shop differently. "
                          'Pick your sign-in method to continue',
                          textAlign: TextAlign.center,
                          style: DesignTokens.bodyText,
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.s32),

                    // ---- Method rows ----
                    _MethodRow(
                      icon: Icons.key_rounded,
                      iconTileColor: DesignTokens.secondaryYellow,
                      iconColor: DesignTokens.bgAppBody,
                      title: 'Use Passkey (Recommended)',
                      description: 'Fast, secure & no passwords needed',
                      onTap: () => context.push(RouteNames.passkey),
                    ),
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
                    const SizedBox(height: DesignTokens.s24),

                    // ---- Divider ----
                    Row(
                      children: [
                        const Expanded(child: Divider(color: DesignTokens.borderDefault, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
                          child: Text(
                            'Or Continue With',
                            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
                          ),
                        ),
                        const Expanded(child: Divider(color: DesignTokens.borderDefault, height: 1)),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.s24),

                    // ---- Social buttons ----
                    _SocialButton(
                      assetPath: 'assets/icons/apple.svg',
                      label: 'Apple ID',
                      onTap: () => _comingSoon(context, 'Apple'),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    _SocialButton(
                      assetPath: 'assets/icons/facebook.svg',
                      label: 'Facebook ID',
                      onTap: () => _comingSoon(context, 'Facebook'),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    _SocialButton(
                      assetPath: 'assets/icons/google.svg',
                      label: 'Google ID',
                      onTap: () => _comingSoon(context, 'Google'),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Footer: Terms & Privacy ----
            const _Footer(),
          ],
        ),
      ),
    );
  }

  static void _comingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider Sign-In coming soon')),
    );
  }
}

/// Minimal top app bar (Fill/App Foundation bg) with a back chevron, matching
/// the Figma top bar on this frame.
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: DesignTokens.bgAppFoundation,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, color: DesignTokens.textWhite, size: DesignTokens.iconMedium),
        onPressed: () {
          if (context.canPop()) context.pop();
        },
      ),
    );
  }
}

/// A tappable sign-in method row: [icon tile] [title + description] [chevron].
/// Transparent background (no card border), matching Figma.
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
            // 40x40 icon tile, 8px radius
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
            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite),
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

/// Full-width gray (#3f3f46) pill social button: [logo] [label].
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
    final regular = DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite);
    final link = DesignTokens.mediumSemibold.copyWith(color: DesignTokens.primaryGreen);
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
            TextSpan(text: 'By Continuing you acknowledge that you read & agree our ', style: regular),
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
