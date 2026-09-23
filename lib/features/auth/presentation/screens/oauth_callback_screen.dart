import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // ignore: avoid_print
    print(
      '[OAUTH-DEBUG] _handleCallback: hasCode=${widget.code.isNotEmpty} error=${widget.error}',
    );
    if (_started) return;
    _started = true;

    // The provider's page is still sitting on top of the app: the deep link
    // brought us here underneath it. Dismiss it first, whatever happens next,
    // or a sign-in that actually succeeded looks exactly like one that did
    // nothing — the browser just stays there. (The social-connect flow has
    // always done this; sign-in never did.)
    await _closeBrowser();

    // User declined in the provider sheet, or the provider returned an error.
    if ((widget.error != null && widget.error!.isNotEmpty) ||
        widget.code.isEmpty) {
      // ignore: avoid_print
      print('[OAUTH-DEBUG] bailing: provider error or empty code');
      _bail('Sign-in was cancelled.');
      return;
    }

    // CSRF check — the state must match the one we stashed when starting the
    // flow. The server also validates server-side; this is defense in depth.
    final expected = ref.read(oauthFlowProvider).state;
    // ignore: avoid_print
    print(
      '[OAUTH-DEBUG] CSRF check: matches=${expected != null && expected == widget.state}',
    );
    if (expected == null || expected != widget.state) {
      // ignore: avoid_print
      print('[OAUTH-DEBUG] bailing: CSRF mismatch');
      _bail('Sign-in could not be verified. Please try again.');
      return;
    }

    // ignore: avoid_print
    print('[OAUTH-DEBUG] calling completeCallback...');
    await ref
        .read(oauthSignInProvider.notifier)
        .completeCallback(
          code: widget.code,
          oauthState: widget.state,
        );
    // ignore: avoid_print
    print('[OAUTH-DEBUG] completeCallback returned');
  }

  /// Best effort: no in-app browser open (the link arrived some other way, or
  /// the platform has nothing to close) is not a reason to fail a sign-in.
  Future<void> _closeBrowser() async {
    try {
      await closeInAppWebView();
    } catch (_) {
      // Nothing to dismiss.
    }
  }

  void _bail(String message) {
    // ignore: avoid_print
    print('[OAUTH-DEBUG] _bail: $message (mounted=$mounted)');
    if (!mounted) return;
    SmSnackbar.error(context, message);
    context.go(RouteNames.signInMethod);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(oauthSignInProvider, (previous, next) {
      // State name only: LoginState.loadSuccess carries the access and refresh
      // tokens, and its toString() would write them to the device log.
      final stateName = next.maybeWhen(
        initial: () => 'initial',
        loadInProgress: () => 'loadInProgress',
        loadSuccess: (_) => 'loadSuccess',
        loadFailure: (f) => 'loadFailure(${f.validationCode ?? f.runtimeType})',
        orElse: () => 'other',
      );
      // ignore: avoid_print
      print('[OAUTH-DEBUG] oauthSignInProvider changed: $stateName');
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
