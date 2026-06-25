import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/widgets/auth_code_field.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// OTP Verification screen — pixel-matched to Figma frame `9684:20916`.
///
/// Centered checkmark illustration + "OTP Verification" (24px) + subtitle,
/// 5 × 48px digit boxes, resend line. The screen only verifies the code and
/// auto-submits once all 5 digits are entered — the name (when required) is
/// collected afterwards on [RouteNames.completeName].
class OtpScreen extends ConsumerStatefulWidget {
  final String phone; // identifier (phone number or email)
  final String otpId;
  final String identifierType; // 'phone' | 'email'

  const OtpScreen({
    super.key,
    required this.phone,
    required this.otpId,
    this.identifierType = 'phone',
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final GlobalKey<AuthCodeFieldState> _codeFieldKey =
      GlobalKey<AuthCodeFieldState>();

  /// Inline verification error shown under the code field (null = no error).
  /// Cleared as soon as the user edits the code again.
  String? _codeError;

  /// Resend cooldown — Resend is disabled until this reaches 0.
  static const int _resendCooldownSeconds = 120;
  Timer? _resendTimer;
  int _secondsRemaining = _resendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  /// (Re)start the 120s resend cooldown.
  void _startResendTimer() {
    _resendTimer?.cancel();
    _secondsRemaining = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  /// Cooldown formatted as `m:ss`, e.g. `2:00`.
  String get _formattedCooldown {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _onResend() {
    // TODO: wire the real resend request once available.
    SmSnackbar.info(context, 'Resend OTP coming soon');
    setState(_startResendTimer);
  }

  /// Verify the code as soon as all 5 digits are entered. The name, when the
  /// account needs one, is collected after verification (see [_routeAfterAuth]).
  void _onCodeComplete(String _) => unawaited(_submit());

  Future<void> _submit() async {
    final code = _codeFieldKey.currentState?.getCode() ?? '';
    if (code.length != 5) {
      SmSnackbar.error(context, 'Please enter all 5 digits');
      return;
    }
    await ref.read(otpVerificationProvider.notifier).verifyOtp(
          identifierType: widget.identifierType,
          identifier: widget.phone,
          code: code,
        );
  }

  /// Maps the failure to a user-facing message, keyed on the backend's
  /// machine-readable `errorCode` (RFC 7807) — never HTTP status or English
  /// title.
  String _getErrorMessage(NetworkExceptions failure) => failure.maybeWhen(
        validation: (code) => switch (code) {
          'validation.invalid_format' || 'validation.invalid_otp' =>
            'The code you entered is incorrect. Please try again',
          'validation.otp_expired' || 'validation.expired' =>
            'This code has expired. Tap Resend to get a new one',
          'system.rate_limited' =>
            'Too many attempts. Please wait a moment and try again',
          'system.account_locked' =>
            'Too many attempts. Please try again later',
          _ => 'Verification failed. Please try again',
        },
        serverUnavailable: () =>
            'StyleMint is temporarily unavailable. Please try again in a moment',
        noInternetConnection: () =>
            'Network error. Please check your connection',
        orElse: () => 'Verification failed. Please try again',
      );

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(otpVerificationProvider).isLoading;

    // Side-effects react to the verification outcome (see SKILL §3.8).
    ref.listen<OtpVerificationState>(otpVerificationProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess: (auth) {
          // No confirmed name → collect it on the dedicated screen (which then
          // continues into onboarding). Already named but new → onboarding.
          // Otherwise an existing user → home.
          if (!auth.displayNameConfirmed) {
            context.go(
              RouteNames.completeName,
              extra: {'accountId': auth.accountId},
            );
          } else if (auth.isNewAccount) {
            context.go(RouteNames.pickInterests);
          } else {
            context.go(RouteNames.home);
          }
        },
        loadFailure: (failure) {
          // Inline error (red boxes + message) instead of a transient
          // snackbar — the user needs to see it while re-entering the code.
          _codeFieldKey.currentState?.clearCode();
          setState(() => _codeError = _getErrorMessage(failure));
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: DesignTokens.textWhite,
            size: DesignTokens.iconMedium,
          ),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.appHorizontalPadding,
            ),
            child: Column(
              children: [
                // Checkmark illustration (Figma image 1, node 9684:20919)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/images/auth/auth_otp_verified.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: DesignTokens.s24),

                // Header
                Column(
                  children: [
                    Text(
                      'OTP Verification',
                      textAlign: TextAlign.center,
                      style: DesignTokens.titleLarge,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      'Please enter the OTP code we sent you in the phone number',
                      textAlign: TextAlign.center,
                      style: DesignTokens.bodyText,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s24),

                // 5-digit code input
                AuthCodeField(
                  key: _codeFieldKey,
                  enabled: !isLoading,
                  codeLength: 5,
                  hasError: _codeError != null,
                  onCompleted: _onCodeComplete,
                  // Clear any error the moment the user edits the code.
                  onChanged: () {
                    if (_codeError != null) {
                      setState(() => _codeError = null);
                    }
                  },
                ),
                if (_codeError != null) ...[
                  const SizedBox(height: DesignTokens.s8),
                  Text(
                    _codeError!,
                    textAlign: TextAlign.center,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.colorError,
                    ),
                  ),
                ],
                const SizedBox(height: DesignTokens.s24),

                // Resend line — disabled (shows a countdown) until the 120s
                // cooldown elapses, then becomes tappable.
                if (_secondsRemaining > 0)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Did not receive code? ',
                          style: DesignTokens.mediumRegular.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                        TextSpan(
                          text: 'Resend in $_formattedCooldown',
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: isLoading ? null : _onResend,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Did not receive code? ',
                            style: DesignTokens.mediumRegular.copyWith(
                              color: DesignTokens.textLight,
                            ),
                          ),
                          TextSpan(
                            text: 'Resend Code',
                            style: DesignTokens.mediumSemibold.copyWith(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
