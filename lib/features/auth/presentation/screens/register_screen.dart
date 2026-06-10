import 'dart:math';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/presentation/widgets/sm_button.dart';
import '../../../../shared/presentation/widgets/sm_phone_number_field.dart';
import '../../../../shared/presentation/widgets/sm_snackbar.dart';
import '../../../../theme/design_tokens.dart';
import '../../data/models/registration_dto.dart';
import '../../shared/providers.dart';
import '../notifiers/registration_notifier.dart';
import '../providers/auth_state_provider.dart';
import '../widgets/auth_code_field.dart';
import '../widgets/registration_step_indicator.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _currentStep = 0;
  final _completedSteps = <int>{};

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _timezoneController = TextEditingController(text: 'Asia/Kathmandu');

  final _phoneFieldKey = GlobalKey<SmPhoneNumberFieldState>();
  final _emailOtpFieldKey = GlobalKey<AuthCodeFieldState>();
  final _phoneOtpFieldKey = GlobalKey<AuthCodeFieldState>();
  final _formKey = GlobalKey<FormState>();

  String _locale = 'en-US';

  static const _locales = {
    'en-US': 'English',
    'ne': '\u0928\u0947\u092a\u093e\u0932\u0940', // Nepali
    'zh': '\u4e2d\u6587', // Chinese
    'es': 'Espa\xf1ol',
    'hi': '\u0939\u093f\u0928\u094d\u0926\u0940', // Hindi
  };

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  RegistrationStartResponseDto? _startResponse() {
    return ref.read(registrationNotifierProvider.notifier).startResponse;
  }

  Future<void> _handleStep1() async {
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final timezone = _timezoneController.text.trim();

    if (displayName.isEmpty || email.isEmpty || phone.isEmpty || timezone.isEmpty) {
      SmSnackbar.error(context, 'Please fill in all fields');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      SmSnackbar.error(context, 'Please enter a valid email address');
      return;
    }

    final phoneE164 =
        _phoneFieldKey.currentState?.getFullPhoneNumber() ?? '';
    final countryDialCode =
        '+${_phoneFieldKey.currentState?.getSelectedCountry().phoneCode ?? '977'}';

    await ref.read(registrationNotifierProvider.notifier).startRegistration(
          displayName: displayName,
          locale: _locale,
          timezone: timezone,
          email: email,
          phoneE164: phoneE164,
          countryDialCode: countryDialCode,
        );
  }

  Future<void> _handleStep2() async {
    final code = _emailOtpFieldKey.currentState?.getCode() ?? '';
    if (code.length != 5) {
      SmSnackbar.error(context, 'Please enter all 5 digits');
      return;
    }
    await ref.read(registrationNotifierProvider.notifier).verifyEmail(code);
  }

  Future<void> _handleStep3() async {
    final code = _phoneOtpFieldKey.currentState?.getCode() ?? '';
    if (code.length != 5) {
      SmSnackbar.error(context, 'Please enter all 5 digits');
      return;
    }
    await ref.read(registrationNotifierProvider.notifier).verifyPhone(code);
  }

  /// Auth is passkey/device-first — the user never sets a password. We
  /// generate a strong one and set it silently (the backend still requires a
  /// password to complete registration; it's stored as a recovery credential).
  Future<void> _autoSetPassword() async {
    await ref
        .read(registrationNotifierProvider.notifier)
        .setPassword(_generateStrongPassword());
  }

  String _generateStrongPassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnpqrstuvwxyz';
    const digits = '23456789';
    const symbols = r'!@#\$%^&*-_=+';
    const all = upper + lower + digits + symbols;
    final rng = Random.secure();
    String pick(String set) => set[rng.nextInt(set.length)];
    // Guarantee one of each class, then fill to 24 chars.
    final chars = <String>[pick(upper), pick(lower), pick(digits), pick(symbols)];
    while (chars.length < 24) {
      chars.add(pick(all));
    }
    chars.shuffle(rng);
    return chars.join();
  }

  Future<void> _handleStep5() async {
    const consentVersion = '2026-01';
    await ref
        .read(registrationNotifierProvider.notifier)
        .acceptTerms(consentVersion);
  }

  /// After registration completes, silently log in with the just-created
  /// credentials so the device is authenticated and lands in the app.
  Future<void> _finishOnboarding() async {
    final reg = ref.read(registrationNotifierProvider.notifier);
    final email = reg.email;
    final password = reg.password;
    if (email == null || password == null) {
      if (mounted) context.go(RouteNames.signInMethod);
      return;
    }
    await ref.read(loginProvider.notifier).loginWithPassword(
          identifierType: 'email',
          identifier: email,
          password: password,
        );
    if (!mounted) return;
    ref.read(loginProvider).maybeWhen(
          loadSuccess: (_) {
            SmSnackbar.success(context, 'Welcome to Style Mint!');
            context.go(RouteNames.home);
          },
          orElse: () {
            SmSnackbar.success(context, 'Account created! Please log in.');
            context.go(RouteNames.signInMethod);
          },
        );
  }

  void _goToStep(int step) {
    setState(() {
      _completedSteps.add(_currentStep);
      _currentStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationNotifierProvider);
    final isLoading = state.isLoading;

    ref.listen<RegistrationState>(registrationNotifierProvider, (previous, next) {
      next.maybeWhen(
        step1LoadSuccess: (_) => _goToStep(1),
        step2Success: () => _goToStep(2),
        // Password is auto-generated + set silently after phone verification —
        // no password step is shown (passkey-first / device-auth model).
        step3Success: _autoSetPassword,
        step4Success: () => _goToStep(3),
        step5Success: (_) {
          // Device-auth: log in immediately so the user lands in the app
          // (no separate sign-in step). Falls back to the sign-in screen if
          // the auto-login can't complete.
          _finishOnboarding();
        },
        step1LoadNetworkExceptions: (failure) {
          // Account already exists → don't strand the user on the signup form;
          // tell them and send them to sign-in.
          if (failure.isConflict) {
            SmSnackbar.error(
              context,
              'This email or phone is already registered. Please sign in.',
            );
            context.go(RouteNames.signInMethod);
            return;
          }
          SmSnackbar.error(
            context,
            _failureMessage(failure, 'Failed to create account'),
          );
        },
        step2NetworkExceptions: (failure) {
          SmSnackbar.error(
            context,
            _failureMessage(failure, 'Email verification failed'),
          );
          _emailOtpFieldKey.currentState?.clearCode();
        },
        step3NetworkExceptions: (failure) {
          SmSnackbar.error(
            context,
            _failureMessage(failure, 'Phone verification failed'),
          );
          _phoneOtpFieldKey.currentState?.clearCode();
        },
        step4NetworkExceptions: (failure) {
          SmSnackbar.error(
            context,
            _failureMessage(failure, 'Failed to set password'),
          );
        },
        step5NetworkExceptions: (failure) {
          SmSnackbar.error(
            context,
            _failureMessage(failure, 'Failed to accept terms'),
          );
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
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep = _currentStep - 1);
            } else {
              context.canPop() ? context.pop() : null;
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            RegistrationStepIndicator(
              totalSteps: 4,
              currentStep: _currentStep,
              completedSteps: _completedSteps,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.appHorizontalPadding,
                  vertical: DesignTokens.s16,
                ),
                child: _buildStepContent(isLoading),
              ),
            ),
            _buildBottomButton(isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isLoading) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(isLoading);
      case 1:
        return _buildStep2(isLoading);
      case 2:
        return _buildStep3(isLoading);
      case 3:
        return _buildStep5();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Info', style: DesignTokens.titleLarge),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Tell us a bit about yourself to get started',
            style: DesignTokens.bodyText,
          ),
          const SizedBox(height: DesignTokens.s24),

          _buildLabel('Display Name'),
          const SizedBox(height: DesignTokens.s4),
          _buildTextField(
            controller: _displayNameController,
            hintText: 'Sarah',
            enabled: !isLoading,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: DesignTokens.s16),

          _buildLabel('Email'),
          const SizedBox(height: DesignTokens.s4),
          _buildTextField(
            controller: _emailController,
            hintText: 'sarah@example.com',
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: DesignTokens.s16),

          SmPhoneNumberField(
            key: _phoneFieldKey,
            controller: _phoneController,
            enabled: !isLoading,
            labelText: 'Phone Number',
            hintText: 'XXXXXXXXXX',
            initialCountry: CountryParser.parseCountryCode('NP'),
          ),
          const SizedBox(height: DesignTokens.s16),

          _buildLabel('Timezone'),
          const SizedBox(height: DesignTokens.s4),
          _buildTextField(
            controller: _timezoneController,
            hintText: 'Asia/Kathmandu',
            enabled: !isLoading,
          ),
          const SizedBox(height: DesignTokens.s16),

          _buildLabel('Language'),
          const SizedBox(height: DesignTokens.s4),
          _buildLocaleDropdown(isLoading),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isLoading) {
    final response = _startResponse();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.email_outlined,
          size: DesignTokens.iconXLarge,
          color: DesignTokens.primaryGreen,
        ),
        const SizedBox(height: DesignTokens.s16),
        Text('Verify Your Email', style: DesignTokens.titleLarge),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Enter the 5-digit code sent to ${ref.read(registrationNotifierProvider.notifier).email ?? 'your email'}',
          textAlign: TextAlign.center,
          style: DesignTokens.bodyText,
        ),
        if (response?.emailOtpCode != null) ...[
          const SizedBox(height: DesignTokens.s12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s12,
              vertical: DesignTokens.s8,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.infoFillDark,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: Text(
              'DEV OTP: ${response!.emailOtpCode}',
              style: const TextStyle(
                color: DesignTokens.infoTextLight,
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s24),
        AuthCodeField(
          key: _emailOtpFieldKey,
          enabled: !isLoading,
          codeLength: 5,
          onCompleted: (code) {
            if (!isLoading) _handleStep2();
          },
        ),
        const SizedBox(height: DesignTokens.s24),
        Text(
          'Enter the 5-digit code from your email',
          style: DesignTokens.smallRegular,
        ),
      ],
    );
  }

  Widget _buildStep3(bool isLoading) {
    final response = _startResponse();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.phone_android_outlined,
          size: DesignTokens.iconXLarge,
          color: DesignTokens.primaryGreen,
        ),
        const SizedBox(height: DesignTokens.s16),
        Text('Verify Your Phone', style: DesignTokens.titleLarge),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Enter the 5-digit code sent to ${ref.read(registrationNotifierProvider.notifier).phoneE164 ?? 'your phone'}',
          textAlign: TextAlign.center,
          style: DesignTokens.bodyText,
        ),
        if (response?.phoneOtpCode != null) ...[
          const SizedBox(height: DesignTokens.s12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s12,
              vertical: DesignTokens.s8,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.infoFillDark,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: Text(
              'DEV OTP: ${response!.phoneOtpCode}',
              style: const TextStyle(
                color: DesignTokens.infoTextLight,
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s24),
        AuthCodeField(
          key: _phoneOtpFieldKey,
          enabled: !isLoading,
          codeLength: 5,
          onCompleted: (code) {
            if (!isLoading) _handleStep3();
          },
        ),
        const SizedBox(height: DesignTokens.s24),
        Text(
          'Enter the 5-digit code from SMS',
          style: DesignTokens.smallRegular,
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: DesignTokens.iconXLarge,
          color: DesignTokens.primaryGreen,
        ),
        const SizedBox(height: DesignTokens.s16),
        Text('Almost Done!', style: DesignTokens.titleLarge),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Please review and accept our terms to create your account',
          textAlign: TextAlign.center,
          style: DesignTokens.bodyText,
        ),
        const SizedBox(height: DesignTokens.s32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: DesignTokens.cardDecoration(
            backgroundColor: DesignTokens.bgAppBody,
          ),
          child: Column(
            children: [
              _buildTermLink('Terms of Service', RouteNames.settingsTerms),
              const SizedBox(height: DesignTokens.s12),
              _buildTermLink('Privacy Policy', RouteNames.settingsPrivacy),
              const SizedBox(height: DesignTokens.s16),
              const Divider(color: DesignTokens.borderDefault),
              const SizedBox(height: DesignTokens.s12),
              Text(
                'Consent Version: 2026-01',
                style: DesignTokens.smallRegular,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                'By tapping "Accept & Create Account" you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: DesignTokens.smallRegular,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermLink(String title, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.open_in_new_rounded,
            size: DesignTokens.iconSmall,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(width: DesignTokens.s8),
          Text(
            title,
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isLoading) {
    String label;
    Future<void> Function()? onPressed;

    switch (_currentStep) {
      case 0:
        label = 'Continue';
        onPressed = isLoading ? null : _handleStep1;
        break;
      case 1:
        label = 'Verify Email';
        onPressed = isLoading ? null : _handleStep2;
        break;
      case 2:
        label = 'Verify Phone';
        onPressed = isLoading ? null : _handleStep3;
        break;
      case 3:
        label = 'Accept & Create Account';
        onPressed = isLoading ? null : _handleStep5;
        break;
      default:
        label = 'Continue';
        onPressed = null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      child: SizedBox(
        width: double.infinity,
        child: SmPrimaryButton(
          label: label,
          height: DesignTokens.buttonHeight,
          borderRadius: DesignTokens.buttonRadius,
          color: DesignTokens.primaryGreen,
          labelColor: DesignTokens.buttonPrimaryText,
          disabled: isLoading || onPressed == null,
          isLoadingInitially: isLoading,
          onPressed: onPressed ?? () async {},
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: DesignTokens.mediumRegular.copyWith(
        color: DesignTokens.inputFieldLabel,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    bool isPassword = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final isObscured = isPassword;

    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: isObscured,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        height: 1.5,
        color: DesignTokens.inputFieldData,
      ),
      cursorColor: DesignTokens.primaryGreen,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          height: 1.5,
          color: DesignTokens.inputFieldPlaceholder,
        ),
        filled: true,
        fillColor: DesignTokens.inputFieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: const BorderSide(
            color: DesignTokens.primaryGreen,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLocaleDropdown(bool isLoading) {
    return Container(
      width: double.infinity,
      height: DesignTokens.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.inputFieldFill,
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        border: Border.all(color: DesignTokens.inputFieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _locale,
          isExpanded: true,
          dropdownColor: DesignTokens.bgAppBody,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            height: 1.5,
            color: DesignTokens.inputFieldData,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: DesignTokens.inputFieldDropdownIcon,
          ),
          items: _locales.entries.map((e) {
            return DropdownMenuItem<String>(
              value: e.key,
              child: Text(
                e.value,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  color: DesignTokens.textWhite,
                ),
              ),
            );
          }).toList(),
          onChanged: isLoading
              ? null
              : (value) {
                  if (value != null) setState(() => _locale = value);
                },
        ),
      ),
    );
  }

  String _failureMessage(NetworkExceptions failure, String fallback) {
    final s = failure.toString();
    if (s.contains('DUPLICATE')) return 'An account with this email or phone already exists';
    if (s.contains('INVALID')) return 'Please check your information and try again';
    if (s.contains('network')) return 'Network error. Please check your connection';
    if (s.contains('auth')) return 'Authentication error. Please try again';
    return fallback;
  }
}
