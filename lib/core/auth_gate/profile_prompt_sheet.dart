import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Just-in-time profile completion prompt. Lists only the fields the
/// account is actually missing (per [ensureProfile]) with a CTA that routes
/// to the screen that fills each one in.
class ProfilePromptSheet extends StatelessWidget {
  const ProfilePromptSheet({required this.missing, super.key});

  final List<ProfileField> missing;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Text(
              'A few more details needed',
              textAlign: TextAlign.center,
              style: DesignTokens.titleMedium,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Complete these before continuing.',
              textAlign: TextAlign.center,
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s24),
            for (final field in missing) ...[
              _ProfileFieldRow(field: field),
              const SizedBox(height: DesignTokens.s12),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe later',
                style: DesignTokens.mediumRegular
                    .copyWith(color: DesignTokens.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFieldRow extends StatelessWidget {
  const _ProfileFieldRow({required this.field});

  final ProfileField field;

  @override
  Widget build(BuildContext context) {
    final route = _routeFor(field);
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: Material(
        color: DesignTokens.primaryGreen,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: route == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  context.push(route);
                },
          child: Center(
            child: Text(
              'Add ${field.label}',
              style: DesignTokens.oneLinerSemibold
                  .copyWith(color: DesignTokens.buttonPrimaryText),
            ),
          ),
        ),
      ),
    );
  }

  // ponytail: kyc has no customer-facing verification screen yet — the row
  // still lists it as missing but isn't actionable until one exists.
  String? _routeFor(ProfileField field) => switch (field) {
        ProfileField.email => RouteNames.profileEdit,
        ProfileField.phone => RouteNames.profileEdit,
        ProfileField.shippingAddress => RouteNames.shippingAddEdit,
        ProfileField.kyc => null,
      };
}

extension ProfileFieldLabel on ProfileField {
  String get label => switch (this) {
        ProfileField.email => 'email address',
        ProfileField.phone => 'phone number',
        ProfileField.shippingAddress => 'shipping address',
        ProfileField.kyc => 'identity verification',
      };
}
