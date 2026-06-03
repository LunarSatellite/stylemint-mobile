import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Auth entry — **passkey first**.
///
/// The default screen is intentionally just the passkey CTA (no method
/// buttons). Passkey is the highest-priority path — the device decides the
/// actual factor (Face / fingerprint / PIN). Email / phone / social and
/// "Create account" (Plan B) replace it when the user taps "More ways to
/// continue".
///
/// "Continue with Passkey" runs a real usernameless WebAuthn sign-in: the OS
/// presents whatever credential the device has, the server resolves the account
/// and issues a session (router redirects to home). If this device has no
/// passkey yet — a new user — we route to signup to create one.
class SignInMethodSelectionScreen extends ConsumerStatefulWidget {
  const SignInMethodSelectionScreen({super.key});

  @override
  ConsumerState<SignInMethodSelectionScreen> createState() =>
      _SignInMethodSelectionScreenState();
}

class _SignInMethodSelectionScreenState
    extends ConsumerState<SignInMethodSelectionScreen> {
  bool _showMore = false;
  bool _busy = false;

  Future<void> _continueWithPasskey() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(passkeyAuthProvider.notifier).authenticateUsernameless();
    if (!mounted) return;
    setState(() => _busy = false);

    final state = ref.read(passkeyAuthProvider);
    state.maybeWhen(
      // Success: the session recheck flips routing to home — nothing to do.
      loadSuccess: (_) {},
      loadFailure: (failure) {
        // No credential on this device → this is a new user; offer the
        // passkey-first quick signup (display name only).
        if (failure.validationCode == 'PASSKEY_NO_CREDENTIALS') {
          _startBootstrapSignup();
          return;
        }
        // User cancelled the OS sheet — stay put, no error noise.
        if (failure.isAuth) return;
        SmSnackbar.error(context, 'Could not sign in with passkey. Try again.');
      },
      orElse: () {},
    );
  }

  /// Passkey-first signup: ask only for a display name, then create the account
  /// + register a passkey + issue a session in one go (email/phone come later).
  Future<void> _startBootstrapSignup() async {
    final displayName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.s16)),
      ),
      builder: (_) => const _DisplayNameSheet(),
    );
    if (displayName == null || displayName.trim().isEmpty || !mounted) return;

    setState(() => _busy = true);
    await ref
        .read(passkeyBootstrapProvider.notifier)
        .signup(displayName: displayName.trim());
    if (!mounted) return;
    setState(() => _busy = false);

    ref.read(passkeyBootstrapProvider).maybeWhen(
          // Success: session recheck flips routing to home.
          loadSuccess: (_) {},
          loadFailure: (failure) {
            if (failure.isAuth) return;
            SmSnackbar.error(
                context, 'Could not create your account. Please try again.');
          },
          orElse: () {},
        );
  }

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
                      'Welcome to StyleMint',
                      textAlign: TextAlign.center,
                      style: DesignTokens.titleMedium,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      'No passwords. No codes. Just your device.',
                      textAlign: TextAlign.center,
                      style: DesignTokens.bodyText,
                    ),
                    const SizedBox(height: DesignTokens.s40),

                    // Default view = the passkey CTA *is* the hero. Tapping
                    // "More ways" swaps it out for Plan B.
                    if (!_showMore) ...[
                      SizedBox(
                        width: double.infinity,
                        child: SmPasskeyButton(
                          onPressed: _continueWithPasskey,
                          busy: _busy,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s12),
                      Text(
                        'Face · Fingerprint · PIN — your device decides',
                        textAlign: TextAlign.center,
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.textLight),
                      ),
                      const SizedBox(height: DesignTokens.s16),
                      TextButton(
                        onPressed: () => setState(() => _showMore = true),
                        child: Text(
                          'More ways to continue',
                          style: DesignTokens.mediumSemibold
                              .copyWith(color: DesignTokens.primaryGreen),
                        ),
                      ),
                    ] else ...[
                      _PlanB(onComingSoon: (p) => _comingSoon(context, p)),
                      const SizedBox(height: DesignTokens.s8),
                      TextButton(
                        onPressed: () => setState(() => _showMore = false),
                        child: Text(
                          'Use passkey instead',
                          style: DesignTokens.mediumSemibold
                              .copyWith(color: DesignTokens.primaryGreen),
                        ),
                      ),
                    ],
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

/// Large tappable passkey disc — the focal point of the entry screen. The OS
/// uses whatever the user enrolled (Face / fingerprint / device PIN) on tap.
/// Primary passkey CTA — the hero of the sign-in screen. A premium gradient
/// pill with a soft green glow and the passkey glyph. Shows a spinner while a
/// ceremony is in flight.
class SmPasskeyButton extends StatelessWidget {
  const SmPasskeyButton({
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DesignTokens.buttonRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3BE07F), Color(0xFF1FA85C)],
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primaryGreen.withValues(alpha: 0.38),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onPressed,
          borderRadius: radius,
          child: SizedBox(
            height: DesignTokens.buttonHeight + 4,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    )
                  : Text(
                      'Continue with Passkey',
                      style: DesignTokens.oneLinerSemibold.copyWith(
                        color: DesignTokens.buttonPrimaryText,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
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

/// Bottom sheet that collects just a display name for passkey-first signup.
/// Pops with the entered name (or null on cancel).
class _DisplayNameSheet extends StatefulWidget {
  const _DisplayNameSheet();

  @override
  State<_DisplayNameSheet> createState() => _DisplayNameSheetState();
}

class _DisplayNameSheetState extends State<_DisplayNameSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s24,
        DesignTokens.s16,
        DesignTokens.s24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What should we call you?', style: DesignTokens.titleMedium),
          const SizedBox(height: DesignTokens.s8),
          Text(
            "Pick a display name to get started. You'll add your email and phone "
            'later — your device passkey is all you need to sign in.',
            style: DesignTokens.bodyText,
          ),
          const SizedBox(height: DesignTokens.s24),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 64,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            cursorColor: DesignTokens.primaryGreen,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.inputFieldData,
            ),
            decoration: InputDecoration(
              hintText: 'Sarah',
              filled: true,
              fillColor: DesignTokens.inputFieldFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          SizedBox(
            width: double.infinity,
            child: SmPasskeyButton(onPressed: _submit),
          ),
        ],
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
