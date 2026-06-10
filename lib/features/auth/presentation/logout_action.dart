import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Confirms intent, then performs a full logout and routes to the sign-in entry.
///
/// [SessionController.logout] revokes the session server-side (best effort),
/// clears the local tokens, and flips the session to `unauthenticated`. We then
/// navigate to [RouteNames.signInMethod] (the same target the vendor more-menu
/// uses) so the user lands on a clean auth screen.
///
/// Pass [allSessions] true to sign out of every device.
Future<void> confirmAndLogout(
  BuildContext context,
  WidgetRef ref, {
  bool allSessions = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DesignTokens.bgAppBody,
      title: const Text(
        'Log Out',
        style: TextStyle(color: DesignTokens.textWhite),
      ),
      content: const Text(
        'Are you sure you want to log out?',
        style: TextStyle(color: DesignTokens.textLight),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: DesignTokens.colorError),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await ref
      .read(sessionControllerProvider.notifier)
      .logout(allSessions: allSessions);

  if (context.mounted) context.go(RouteNames.signInMethod);
}
