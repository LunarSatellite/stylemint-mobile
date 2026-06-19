import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Handles the OAuth redirect callback.
///
/// Reached via the deep link `stylemint://auth/oauth/callback?code=&state=`
/// (or `?error=access_denied` when the user declines).
///
/// Verifies the CSRF `state` against the in-flight attempt, exchanges the code
/// for a session, then routes by `isNewAccount` (new → role/onboarding picker,
/// returning → home).
class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({
    super.key,
    this.provider = '',
    required this.code,
    required this.state,
    this.error,
  });

  final String provider;
  final String code;
  final String state;

  /// Provider error code from the deep link (e.g. `access_denied`).
  final String? error;

  @override
  ConsumerState<OAuthCallbackScreen> createState() =>
      _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleCallback());
  }

  Future<void> _handleCallback() async {
    if (_started) return;
    _started = true;

    // User declined in the provider sheet, or the provider returned an error.
    if ((widget.error != null && widget.error!.isNotEmpty) ||
        widget.code.isEmpty) {
      _bail('Sign-in was cancelled.');
      return;
    }

    // CSRF check — the state must match the one we stashed when starting the
    // flow. The server also validates server-side; this is defense in depth.
    final expected = ref.read(oauthFlowProvider).state;
    if (expected == null || expected != widget.state) {
      _bail('Sign-in could not be verified. Please try again.');
      return;
    }

    await ref.read(oauthSignInProvider.notifier).completeCallback(
          code: widget.code,
          oauthState: widget.state,
        );
  }

  void _bail(String message) {
    if (!mounted) return;
    SmSnackbar.error(context, message);
    context.go(RouteNames.signInMethod);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(oauthSignInProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess: (auth) {
          if (auth.isNewAccount) {
            // New account → role / onboarding picker. Pass isNewAccount via the
            // query string (not extra) so it survives the post-login refresh.
            context.go('${RouteNames.userTypeSelection}?new=true');
          } else {
            context.go(RouteNames.home);
          }
        },
        loadFailure: (failure) {
          // 409 — the email is already on a different sign-in method.
          if (failure.isConflict) {
            _bail(
              'An account already uses this email. Sign in with your '
              'existing method, then link this provider from settings.',
            );
            return;
          }
          _bail('Social sign-in failed. Please try again.');
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
              'Completing sign-in…',
              style: TextStyle(color: DesignTokens.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
