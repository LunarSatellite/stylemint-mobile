import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Email verification method.
enum EmailVerificationType { otp, magicLink }

/// Email Login screen — pixel-matched to Figma frame `9684:21684`.
///
/// - Email illustration + "Enter your Email" (24px) + subtitle (16px)
/// - Email input ("Email Address" placeholder, #27272A fill, #52525C border)
/// - "Email Verification Type" radio group: OTP (default) / Magic Link
/// - Submit button (green pill) pinned at the bottom
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  EmailVerificationType _verificationType = EmailVerificationType.otp;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Stashed so the listener can pass it to the OTP route on success.
  String _submittedEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validate + fire. Navigation/error handled by the `ref.listen` in [build].
  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      SmSnackbar.error(context, 'Please enter your email address');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      SmSnackbar.error(context, 'Please enter a valid email address');
      return;
    }

    _submittedEmail = email;

    if (_verificationType == EmailVerificationType.magicLink) {
      // Magic-link path — server emails a link; consumption is handled by
      // MagicLinkScreen via the /auth/magic deep link.
      await ref.read(magicLinkProvider.notifier).requestLink(email);
      return;
    }

    // OTP path — reuse the shared OTP request flow with identifierType "email".
    await ref
        .read(otpRequestProvider.notifier)
        .requestOtp(
          identifierType: 'email',
          identifier: email,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(otpRequestProvider).isLoading ||
        ref.watch(magicLinkProvider).isLoading;

    // Side-effects react to the request outcome (see SKILL §3.8).
    ref..listen<OtpRequestState>(otpRequestProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess:
            (otp) => context.push(
              RouteNames.otp,
              extra: {
                'phone':
                    _submittedEmail, // OtpScreen uses this as the identifier
                'otpId': otp.otpId,
                'identifierType': 'email',
              },
            ),
        loadFailure:
            (_) => SmSnackbar.error(
              context,
              'Failed to send OTP. Please try again',
            ),
        orElse: () {},
      );
    })

    ..listen<MagicLinkRequestState>(magicLinkProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess:
            (_) => SmSnackbar.success(
              context,
              'Magic link sent to $_submittedEmail. '
              'Open it on this device to sign in.',
            ),
        loadFailure:
            (_) => SmSnackbar.error(
              context,
              'Failed to send magic link. Please try again',
            ),
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
                      // Email illustration (Figma image 49, node 9684:21749)
                      SizedBox(
                        width: 115,
                        height: 100,
                        child: Image.asset(
                          'assets/images/auth/auth_email.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s24),

                      // Header
                      Column(
                        children: [
                          Text(
                            'Enter your Email',
                            textAlign: TextAlign.center,
                            style: DesignTokens.titleLarge,
                          ),
                          const SizedBox(height: DesignTokens.s8),
                          Text(
                            'Sign in with your email. Password-less and easy',
                            textAlign: TextAlign.center,
                            style: DesignTokens.bodyText,
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.s24),

                      // Email input field
                      TextFormField(
                        controller: _emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: DesignTokens.inputFieldData,
                        ),
                        cursorColor: DesignTokens.primaryGreen,
                        decoration: DesignTokens.inputDecoration(
                          hintText: 'Email Address',
                        ),
                        onFieldSubmitted: (_) => _handleSubmit(),
                      ),
                      const SizedBox(height: DesignTokens.s24),

                      // Verification type
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Verification Type',
                          style: DesignTokens.mediumSemibold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s16),
                      _RadioListItem(
                        title: 'OTP Verification',
                        description: 'We will send you an OTP for verification',
                        selected:
                            _verificationType == EmailVerificationType.otp,
                        onTap:
                            () => setState(
                              () =>
                                  _verificationType = EmailVerificationType.otp,
                            ),
                      ),
                      const SizedBox(height: DesignTokens.s12),
                      _RadioListItem(
                        title: 'Magic Link Verification',
                        description: 'We will send you a link to sign in',
                        selected:
                            _verificationType ==
                            EmailVerificationType.magicLink,
                        onTap:
                            () => setState(
                              () =>
                                  _verificationType =
                                      EmailVerificationType.magicLink,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Submit button pinned to bottom
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
                  label: 'Submit',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  disabled: isLoading,
                  isLoadingInitially: isLoading,
                  onPressed: _handleSubmit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio list item matching Figma "Radio List Item" component.
/// #18181B fill, 8px radius, title (14px white) + description (12px muted),
/// trailing radio icon (green when checked, grey when not).
class _RadioListItem extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _RadioListItem({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.s8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.radioFill,
          borderRadius: BorderRadius.circular(DesignTokens.s8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.radioTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(description, style: DesignTokens.smallRegular),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s16),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color:
                  selected
                      ? DesignTokens.radioIconChecked
                      : DesignTokens.radioIconDefault,
            ),
          ],
        ),
      ),
    );
  }
}
