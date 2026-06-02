import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_reason.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Inline, fingerprint-first auth prompt shown when a guest takes a protected
/// action. Contextual to [reason].
///
/// INTERIM: the fingerprint CTA routes to the full fingerprint-first entry
/// (`signInMethod`) because token-issuing / usernameless passkey login isn't
/// available yet (backend #20/#21/#23). When it lands, this CTA runs the passkey
/// ceremony inline and pops `true` — `ensureAuth` and all call sites stay as-is.
class AuthPromptSheet extends StatelessWidget {
  const AuthPromptSheet({required this.reason, super.key});

  final AuthReason reason;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s24,
          DesignTokens.s12,
          DesignTokens.s24,
          DesignTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: DesignTokens.s24),
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignTokens.chipsSelectedFill,
              ),
              child: const Icon(Icons.fingerprint,
                  color: DesignTokens.primaryGreen, size: 40),
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(reason.prompt,
                textAlign: TextAlign.center, style: DesignTokens.titleMedium),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Fast & secure with your fingerprint — no passwords.',
              textAlign: TextAlign.center,
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: Material(
                color: DesignTokens.primaryGreen,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(RouteNames.signInMethod);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fingerprint,
                          color: DesignTokens.buttonPrimaryText,
                          size: DesignTokens.iconMedium),
                      const SizedBox(width: DesignTokens.s8),
                      Text('Continue with Fingerprint',
                          style: DesignTokens.oneLinerSemibold.copyWith(
                              color: DesignTokens.buttonPrimaryText)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Maybe later',
                  style: DesignTokens.mediumRegular
                      .copyWith(color: DesignTokens.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
