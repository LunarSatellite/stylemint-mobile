import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/widgets/auth_code_field.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// OTP Verification screen — pixel-matched to Figma frame `9684:20916`.
///
/// Centered checkmark illustration + "OTP Verification" (24px) + subtitle,
/// 5 × 48px digit boxes, resend line, Verify button (with arrow) at the bottom.
class OtpScreen extends ConsumerStatefulWidget {
  final String phone; // identifier (phone number or email)
  final String otpId;
  final String identifierType; // 'phone' | 'email'

  /// True when the OTP request just provisioned a new account (smart-start).
  /// Drives showing the "Your name" field so the name is set in the same
  /// verify call.
  final bool isNewAccount;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.otpId,
    this.identifierType = 'phone',
    this.isNewAccount = false,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final GlobalKey<AuthCodeFieldState> _codeFieldKey =
      GlobalKey<AuthCodeFieldState>();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  /// Inline verification error shown under the code field (null = no error).
  /// Cleared as soon as the user edits the code again.
  String? _codeError;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  /// Called when all 5 OTP digits are entered.
  /// - New accounts: move focus to the name field so the user can complete
  ///   their profile before pressing Verify (does NOT auto-submit).
  /// - Existing accounts: no name to collect, so verify the OTP directly.
  void _onCodeComplete(String _) {
    if (widget.isNewAccount) {
      _nameFocusNode.requestFocus();
    } else {
      unawaited(_submit());
    }
  }

  /// Called only by the Verify button — validates field(s) then submits.
  Future<void> _submit() async {
    final code = _codeFieldKey.currentState?.getCode() ?? '';
    if (code.length != 5) {
      SmSnackbar.error(context, 'Please enter all 5 digits');
      return;
    }
    // Name is collected (and required) only when provisioning a new account.
    if (widget.isNewAccount && _nameController.text.trim().isEmpty) {
      SmSnackbar.error(context, 'Please enter your name');
      _nameFocusNode.requestFocus();
      return;
    }
    await ref.read(otpVerificationProvider.notifier).verifyOtp(
      identifierType: widget.identifierType,
      identifier: widget.phone,
      code: code,
      displayName:
          widget.isNewAccount ? _nameController.text.trim() : null,
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
        // New accounts complete onboarding (pick interests); existing
        // accounts go straight to home.
        loadSuccess:
            (_) => context.go(
              widget.isNewAccount
                  ? RouteNames.pickInterests
                  : RouteNames.home,
            ),
        loadFailure: (failure) {
          // Inline error (red boxes + message) instead of a transient
          // snackbar — the user needs to see it while re-entering the code.
          setState(() => _codeError = _getErrorMessage(failure));
          _codeFieldKey.currentState?.clearCode();
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
        child: Column(
          children: [
            Expanded(
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
                        // Clear the error the moment the user edits the code.
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

                      // Name field — new accounts only. Existing accounts
                      // verify with the OTP alone (no name prompt).
                      if (widget.isNewAccount) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Your name',
                            style: DesignTokens.mediumSemibold,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s8),
                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          enabled: !isLoading,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          maxLength: 64,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            color: DesignTokens.inputFieldData,
                          ),
                          cursorColor: DesignTokens.primaryGreen,
                          decoration: DesignTokens.inputDecoration(
                            hintText: 'e.g. Alice',
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: DesignTokens.s24),
                      ],

                      // Resend line
                      GestureDetector(
                        onTap:
                            isLoading
                                ? null
                                : () => SmSnackbar.info(
                                  context,
                                  'Resend OTP coming soon',
                                ),
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

            // Verify button pinned at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                DesignTokens.s32,
              ),
              child: SizedBox(
                width: double.infinity,
                child: SmPrimaryButton(
                  label: 'Verify',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  disabled: isLoading,
                  isLoadingInitially: isLoading,
                  onPressed: _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
