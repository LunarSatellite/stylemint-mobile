import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Handles the magic-link deep-link callback.
///
/// Route: `/auth/magic?token=<token>`
///
/// This screen appears when the user taps the magic-link email. It is
/// intentionally minimal — it shows a spinner while verifying, then redirects
/// to [RouteNames.home] on success or shows an error and goes back to
/// [RouteNames.signInMethod] on failure.
class MagicLinkScreen extends ConsumerStatefulWidget {
  const MagicLinkScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends ConsumerState<MagicLinkScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger immediately after the first frame so the widget tree is built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _consume());
  }

  Future<void> _consume() async {
    await ref
        .read(loginProvider.notifier)
        .consumeMagicLink(token: widget.token);
  }

  String _errorMessage(NetworkExceptions failure) => failure.maybeWhen(
        validation: (_) => 'This magic link is invalid or has already been used',
        auth: () => 'This magic link has expired. Please request a new one',
        noInternetConnection: () => 'Network error. Please check your connection',
        orElse: () => 'Sign-in failed. Please try again',
      );

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginProvider, (_, next) {
      next.maybeWhen(
        loadSuccess: (_) => context.go(RouteNames.home),
        loadFailure: (failure) {
          SmSnackbar.error(context, _errorMessage(failure));
          context.go(RouteNames.signInMethod);
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: DesignTokens.primaryGreen),
            SizedBox(height: DesignTokens.s24),
            Text(
              'Signing you in…',
              style: TextStyle(color: DesignTokens.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
