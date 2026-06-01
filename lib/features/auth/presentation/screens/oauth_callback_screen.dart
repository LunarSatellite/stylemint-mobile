import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Handles the OAuth redirect callback.
///
/// Route: `/social/:provider?code=<code>&state=<state>`
///
/// After the user authorises in the external browser (Google/Apple/Facebook),
/// the redirect comes back here. The screen calls [oauthCallback], which links
/// the external identity; then the user registers or logs in.
class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({
    super.key,
    required this.provider,
    required this.code,
    required this.state,
  });

  final String provider;
  final String code;
  final String state;

  @override
  ConsumerState<OAuthCallbackScreen> createState() =>
      _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleCallback());
  }

  Future<void> _handleCallback() async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _error = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.oauthCallback(
      code: widget.code,
      state: widget.state,
    );
    result.fold(
      (failure) {
        setState(() {
          _processing = false;
          _error = 'Social sign-in failed. Please try again.';
        });
      },
      (callbackResult) async {
        // If this was a new link the account may already be authenticated
        // (tokens persisted from an earlier OTP/magic flow). Otherwise the
        // user needs to register / pick a role.
        await ref.read(sessionControllerProvider.notifier).recheck();
        if (mounted) {
          final session = ref.read(sessionControllerProvider);
          if (session.isAuthenticated) {
            context.go(RouteNames.home);
          } else {
            context.go(RouteNames.signInMethod);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SmSnackbar.error(context, _error!);
        context.go(RouteNames.signInMethod);
      });
    }

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
