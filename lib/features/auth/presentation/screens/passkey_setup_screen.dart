import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Biometric variant for passkey setup.
enum PasskeyType { face, fingerprint }

/// Passkey Setup screen — pixel-matched to Figma frames
/// `9704:9705` (Face) and `9704:14248` (Fingerprint). The two frames are
/// identical apart from the illustration and subtitle, so this widget is
/// parameterized by [PasskeyType].
///
/// Layout: illustration (100x100) → "Setup a Passkey" (24px) + subtitle (16px)
/// → "How it works" info box (#052F4A bg, #B8E6FE text) → Setup button.
class PasskeySetupScreen extends StatelessWidget {
  final PasskeyType type;

  const PasskeySetupScreen({super.key, required this.type});

  String get _subtitle => type == PasskeyType.face
      ? 'Sign in with just your face. Password-less, secure and works '
          'across all devices'
      : 'Sign in with just your finger print. Password-less, secure and works '
          'across all devices';

  // Figma image 52 (Face, node 9704:9753) / image 53 (Fingerprint, node 9704:14304).
  String get _illustrationAsset => type == PasskeyType.face
      ? 'assets/images/auth/auth_passkey_face.png'
      : 'assets/images/auth/auth_passkey_fingerprint.png';

  static const List<String> _howItWorks = [
    "We'll ask you to verify with Face ID/Touch ID",
    'Your device create a secure passkey',
    'Next time, just use biometrics to sign in!',
    'Your privacy is protected. Passkeys never leave your device',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: DesignTokens.textWhite, size: DesignTokens.iconMedium),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.appHorizontalPadding),
                  child: Column(
                    children: [
                      // Biometric illustration (Figma image 52 / 53)
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          _illustrationAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s24),

                      // Header
                      Column(
                        children: [
                          Text('Setup a Passkey',
                              textAlign: TextAlign.center,
                              style: DesignTokens.titleLarge),
                          const SizedBox(height: DesignTokens.s8),
                          Text(_subtitle,
                              textAlign: TextAlign.center,
                              style: DesignTokens.bodyText),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.s24),

                      // "How it works" info box
                      const _HowItWorksBox(items: _howItWorks),
                    ],
                  ),
                ),
              ),
            ),

            // Setup button pinned at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                DesignTokens.s32,
              ),
              child: SizedBox(
                width: double.infinity,
                child: SmPrimaryButton(
                  label: 'Setup Passkey',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  suffixIcon: const Icon(Icons.arrow_forward_rounded,
                      size: DesignTokens.iconSmall,
                      color: DesignTokens.buttonPrimaryText),
                  onPressed: () async {
                    // TODO(Task 19): integrate local_auth biometric prompt +
                    // RegisterPasskeyUseCase, then navigate to user type selection.
                    SmSnackbar.info(context, 'Passkey setup coming soon');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Info/alert box: #052F4A fill, 16px radius, help icon, "How it works:" title,
/// and bulleted lines — all in light-blue (#B8E6FE). Matches Figma "Alert".
class _HowItWorksBox extends StatelessWidget {
  final List<String> items;
  const _HowItWorksBox({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.infoFillDark,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.help_rounded,
              size: DesignTokens.iconMedium, color: DesignTokens.infoIconLight),
          const SizedBox(height: DesignTokens.s12),
          Text('How it works:',
              style: DesignTokens.mediumSemibold
                  .copyWith(color: DesignTokens.infoTextLight)),
          const SizedBox(height: DesignTokens.s12),
          ...List.generate(items.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bullet dot inside a 16px box
                  const SizedBox(
                    width: DesignTokens.iconSmall,
                    height: 18,
                    child: Center(
                      child: _Dot(),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      items[i],
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.infoTextLight),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: DesignTokens.infoIconLight,
        shape: BoxShape.circle,
      ),
    );
  }
}
