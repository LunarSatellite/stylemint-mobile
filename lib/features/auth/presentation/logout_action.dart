import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

Future<void> confirmAndLogout(
  BuildContext context,
  WidgetRef ref, {
  bool allSessions = false,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.cardRadius),
      ),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s24,
        0,
        DesignTokens.s24,
        DesignTokens.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: DesignTokens.s12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),

          // Icon
          SvgPicture.asset(
            'assets/icons/Logout.svg',
            width: 64,
            height: 64,
          ),
          const SizedBox(height: DesignTokens.s16),

          const Text('Log Out', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Are you sure you want to log out?',
            textAlign: TextAlign.center,
            style: DesignTokens.mediumRegular
                .copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s24),

          // Log Out button
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.colorError,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
                minimumSize:
                    const Size(0, DesignTokens.buttonHeight),
              ),
              child: const Text('Log Out', style: DesignTokens.mediumSemibold),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.buttonGrayFill,
                foregroundColor: DesignTokens.buttonGrayText,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
                minimumSize:
                    const Size(0, DesignTokens.buttonHeight),
              ),
              child:
                  const Text('Cancel', style: DesignTokens.mediumSemibold),
            ),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return;

  await ref
      .read(sessionControllerProvider.notifier)
      .logout(allSessions: allSessions);

  if (context.mounted) context.go(RouteNames.signInMethod);
}
