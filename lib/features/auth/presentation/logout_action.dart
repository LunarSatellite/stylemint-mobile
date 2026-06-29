import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Shows the confirm-logout bottom sheet, then logs out and navigates to
/// sign-in if the user confirms.
Future<void> confirmAndLogout(
  BuildContext context,
  WidgetRef ref, {
  bool allSessions = false,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LogoutSheet(),
  );
  if (confirmed != true) return;

  await ref
      .read(sessionControllerProvider.notifier)
      .logout(allSessions: allSessions);

  if (context.mounted) context.go(RouteNames.signInMethod);
}

// ── Bottom sheet ─────────────────────────────────────────────────────────────

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          // Logout illustration
          Image.asset(
            'assets/images/creatordash/logout.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.logout_rounded,
              size: 64,
              color: DesignTokens.primaryGreen,
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          const Text(
            'Confirm Logout',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          const Text(
            'Are you sure you want to logout ?',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          // Logout button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: DesignTokens.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: DesignTokens.s8),
                  Icon(Icons.logout_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.bgAppBodyLight,
                foregroundColor: DesignTokens.textWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
