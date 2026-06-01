import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_phone_number_field.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum _LoginTab { email, phone }

class PasswordLoginScreen extends ConsumerStatefulWidget {
  const PasswordLoginScreen({super.key});

  @override
  ConsumerState<PasswordLoginScreen> createState() =>
      _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends ConsumerState<PasswordLoginScreen> {
  _LoginTab _activeTab = _LoginTab.email;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneFieldKey = GlobalKey<SmPhoneNumberFieldState>();

  bool _obscurePassword = true;
  String _submittedIdentifier = '';

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      SmSnackbar.error(context, 'Please enter your password');
      return;
    }

    if (_activeTab == _LoginTab.email) {
      final email = _emailController.text.trim();
      if (email.isEmpty || !_emailRegex.hasMatch(email)) {
        SmSnackbar.error(context, 'Please enter a valid email address');
        return;
      }
      _submittedIdentifier = email;
    } else {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty || phone.length < 10) {
        SmSnackbar.error(context, 'Please enter a valid phone number');
        return;
      }
      _submittedIdentifier =
          _phoneFieldKey.currentState?.getFullPhoneNumber() ?? '';
    }

    await ref.read(loginProvider.notifier).loginWithPassword(
      identifierType: _activeTab == _LoginTab.email ? 'email' : 'phone',
      identifier: _submittedIdentifier,
      password: password,
    );
  }

  Country get _defaultCountry => CountryParser.parseCountryCode('NP');

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loginProvider).isLoading;

    ref.listen<LoginState>(loginProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess:
            (auth) => context.go(RouteNames.userTypeSelection, extra: auth),
        loadFailure:
            (_) => SmSnackbar.error(
              context,
              'Invalid credentials. Please try again',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.appHorizontalPadding,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: DesignTokens.s16),
                    Text(
                      'Sign In with Password',
                      textAlign: TextAlign.center,
                      style: DesignTokens.titleLarge,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      'Enter your credentials to sign in',
                      textAlign: TextAlign.center,
                      style: DesignTokens.bodyText,
                    ),
                    const SizedBox(height: DesignTokens.s24),

                    _TabToggle(
                      activeTab: _activeTab,
                      onChanged:
                          (tab) => setState(() {
                            _activeTab = tab;
                          }),
                    ),
                    const SizedBox(height: DesignTokens.s24),

                    if (_activeTab == _LoginTab.email) ...[
                      _EmailField(
                        controller: _emailController,
                        enabled: !isLoading,
                      ),
                    ] else ...[
                      SmPhoneNumberField(
                        key: _phoneFieldKey,
                        controller: _phoneController,
                        enabled: !isLoading,
                        labelText: 'Phone Number',
                        hintText: 'XXXXXXXXXX',
                        initialCountry: _defaultCountry,
                      ),
                    ],
                    const SizedBox(height: DesignTokens.s16),

                    _PasswordField(
                      controller: _passwordController,
                      obscure: _obscurePassword,
                      enabled: !isLoading,
                      onToggleObscure:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.s16),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.push(RouteNames.forgotPassword),
                        child: Text(
                          'Forgot Password?',
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                  label: 'Log In',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  disabled: isLoading,
                  isLoadingInitially: isLoading,
                  onPressed: _handleLogin,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  final _LoginTab activeTab;
  final ValueChanged<_LoginTab> onChanged;

  const _TabToggle({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(_LoginTab.email),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      activeTab == _LoginTab.email
                          ? DesignTokens.primaryGreen
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                ),
                child: Text(
                  'Email',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color:
                        activeTab == _LoginTab.email
                            ? DesignTokens.buttonPrimaryText
                            : DesignTokens.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(_LoginTab.phone),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      activeTab == _LoginTab.phone
                          ? DesignTokens.primaryGreen
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                ),
                child: Text(
                  'Phone',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color:
                        activeTab == _LoginTab.phone
                            ? DesignTokens.buttonPrimaryText
                            : DesignTokens.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _EmailField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        color: DesignTokens.inputFieldData,
      ),
      cursorColor: DesignTokens.primaryGreen,
      decoration: DesignTokens.inputDecoration(hintText: 'Email Address'),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final bool enabled;
  final VoidCallback onToggleObscure;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.enabled,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        color: DesignTokens.inputFieldData,
      ),
      cursorColor: DesignTokens.primaryGreen,
      decoration: DesignTokens.inputDecoration(
        hintText: 'Password',
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: DesignTokens.textMuted,
            size: DesignTokens.iconSmall,
          ),
          onPressed: onToggleObscure,
        ),
      ),
      onFieldSubmitted: (_) {},
    );
  }
}
