import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/widgets/auth_code_field.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

/// OTP Verification screen — pixel-matched to Figma frame `9684:20916`.
///
/// Centered checkmark illustration + "OTP Verification" (24px) + subtitle,
/// 5 × 48px digit boxes, resend line, Verify button (with arrow) at the bottom.
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

  Future<void> _handleVerifyOtp(String code) async {
    if (code.length != 5) {
      SmSnackbar.error(context, 'Please enter all 5 digits');
      return;
    }

    await ref.read(otpVerificationProvider.notifier).verifyOtp(
          identifierType: widget.identifierType,
          identifier: widget.phone,
          code: code,
        );

    if (!mounted) return;
    final verifyState = ref.read(otpVerificationProvider);
    if (verifyState.isSuccess && verifyState.authData != null) {
      context.push(RouteNames.userTypeSelection, extra: verifyState.authData!);
    } else if (verifyState.hasError) {
      SmSnackbar.error(context, _getErrorMessage(verifyState.error));
      _codeFieldKey.currentState?.clearCode();
    }
  }

  String _getErrorMessage(dynamic error) {
    final s = error.toString();
    if (s.contains('INVALID_OTP')) return 'Invalid OTP code. Please try again';
    if (s.contains('EXPIRED')) return 'OTP code has expired. Request a new one';
    if (s.contains('network')) {
      return 'Network error. Please check your connection';
    }
    return 'Verification failed. Please try again';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(otpVerificationProvider).isLoading;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: DesignTokens.textWhite, size: DesignTokens.iconMedium),
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
                      horizontal: DesignTokens.appHorizontalPadding),
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
                          Text('OTP Verification',
                              textAlign: TextAlign.center,
                              style: DesignTokens.titleLarge),
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
                        onCompleted: _handleVerifyOtp,
                      ),
                      const SizedBox(height: DesignTokens.s24),

                      // Resend line
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => SmSnackbar.info(
                                context, 'Resend OTP coming soon'),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Did not receive code? ',
                                style: DesignTokens.mediumRegular
                                    .copyWith(color: DesignTokens.textLight),
                              ),
                              TextSpan(
                                text: 'Resend Code',
                                style: DesignTokens.mediumSemibold
                                    .copyWith(color: DesignTokens.primaryGreen),
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
                  suffixIcon: const Icon(Icons.arrow_forward_rounded,
                      size: DesignTokens.iconSmall,
                      color: DesignTokens.buttonPrimaryText),
                  onPressed: () async {
                    final code = _codeFieldKey.currentState?.getCode() ?? '';
                    await _handleVerifyOtp(code);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
