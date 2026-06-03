import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "How it works" info box for the passkey screens. Copy + styling are
/// pixel/word-exact to the "Login - Passkey" design spec (info-dark card,
/// #B8E6FE text, 4 bullets). Shared so every passkey surface reads identically.
class PasskeyHowItWorks extends StatelessWidget {
  const PasskeyHowItWorks({super.key});

  // Verbatim from the spec (note: "create", not "creates").
  static const List<String> _items = [
    "We'll ask you to verify with Face ID/Touch ID",
    'Your device create a secure passkey',
    'Next time, just use biometrics to sign in!',
    'Your privacy is protected. Passkeys never leave your device',
  ];

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
          const Icon(
            Icons.help_rounded,
            size: DesignTokens.iconMedium,
            color: DesignTokens.infoIconLight,
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            'How it works:',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.infoTextLight,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          ...List.generate(_items.length, (i) {
            return Padding(
              padding:
                  EdgeInsets.only(bottom: i == _items.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: DesignTokens.iconSmall,
                    height: 18,
                    child: Center(child: _Dot()),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      _items[i],
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.infoTextLight,
                      ),
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
