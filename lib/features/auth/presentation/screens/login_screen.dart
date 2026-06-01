import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_phone_number_field.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

/// Phone Login screen — pixel-matched to Figma frame `9688:21840`.
///
/// Centered illustration + "Enter your Phone No." (24px) + subtitle (16px),
/// phone field (flag/dial-code add-on), Submit button pinned at the bottom.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<SmPhoneNumberFieldState> _phoneFieldKey =
      GlobalKey<SmPhoneNumberFieldState>();

  /// Stashed so the listener can pass it to the OTP route on success.
  String _submittedPhone = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Validate + fire the request. Navigation/error are handled by the
  /// `ref.listen` in [build] — NOT here. We never await-then-read state.
  Future<void> _handleSubmit() async {
    final number = _phoneController.text.trim();
    if (number.isEmpty || number.length < 10) {
      SmSnackbar.error(context, 'Please enter a valid phone number');
      return;
    }
    _submittedPhone = _phoneFieldKey.currentState?.getFullPhoneNumber() ?? '';

    await ref
        .read(otpRequestProvider.notifier)
        .requestOtp(
          identifierType: 'phone',
          identifier: _submittedPhone,
        );
  }

  Country get _defaultCountry => CountryParser.parseCountryCode('NP');

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(otpRequestProvider).isLoading;

    // Side-effects (navigate / snackbar) react to the state transition.
    // `ref.listen` fires only when the state changes, so this runs once
    // per request outcome — never on a plain rebuild.
    ref.listen<OtpRequestState>(otpRequestProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess:
            (otp) => context.push(
              RouteNames.otp,
              extra: {
                'phone': _submittedPhone,
                'otpId': otp.otpId,
                'identifierType': 'phone',
              },
            ),
        loadFailure:
            (_) => SmSnackbar.error(
              context,
              'Failed to send OTP. Please try again',
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
                      // Phone illustration (Figma image 50, node 9688:21904)
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          'assets/images/auth/auth_phone.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s24),

                      // Header
                      Column(
                        children: [
                          Text(
                            'Enter your Phone No.',
                            textAlign: TextAlign.center,
                            style: DesignTokens.titleLarge,
                          ),
                          const SizedBox(height: DesignTokens.s8),
                          Text(
                            'Sign in with your phone number. Password-less and easy',
                            textAlign: TextAlign.center,
                            style: DesignTokens.bodyText,
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.s24),

                      // Phone number field
                      SmPhoneNumberField(
                        key: _phoneFieldKey,
                        controller: _phoneController,
                        enabled: !isLoading,
                        labelText: 'Phone Number',
                        hintText: 'XXXXXXXXXX',
                        initialCountry: _defaultCountry,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Submit button pinned at bottom
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
