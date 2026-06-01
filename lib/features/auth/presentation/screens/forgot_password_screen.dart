import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      SmSnackbar.error(context, 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.requestPasswordReset(email: email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => SmSnackbar.error(context, 'Failed to send reset link'),
      (_) => setState(() => _sent = true),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.appHorizontalPadding,
          ),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DesignTokens.s40),
        Text(
          'Forgot Password?',
          textAlign: TextAlign.center,
          style: DesignTokens.titleLarge,
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Enter your email address and we will send you a reset link',
          textAlign: TextAlign.center,
          style: DesignTokens.bodyText,
        ),
        const SizedBox(height: DesignTokens.s32),
        TextFormField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.inputFieldData,
          ),
          cursorColor: DesignTokens.primaryGreen,
          decoration: DesignTokens.inputDecoration(hintText: 'Email Address'),
          onFieldSubmitted: (_) => _handleSubmit(),
        ),
        const SizedBox(height: DesignTokens.s24),
        SizedBox(
          height: DesignTokens.buttonHeight,
          child: SmPrimaryButton(
            label: 'Send Reset Link',
            height: DesignTokens.buttonHeight,
            borderRadius: DesignTokens.buttonRadius,
            color: DesignTokens.primaryGreen,
            labelColor: DesignTokens.buttonPrimaryText,
            disabled: _isLoading,
            isLoadingInitially: _isLoading,
            onPressed: _handleSubmit,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: DesignTokens.primaryGreen,
            size: 64,
          ),
          const SizedBox(height: DesignTokens.s24),
          Text(
            'Check your email',
            style: DesignTokens.titleMedium,
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'We have sent a password reset link to your email address. '
            'Please check your inbox and follow the link to reset your password.',
            textAlign: TextAlign.center,
            style: DesignTokens.bodyText,
          ),
          const SizedBox(height: DesignTokens.s32),
          SizedBox(
            height: DesignTokens.buttonHeight,
            child: SmPrimaryButton(
              label: 'Back to Sign In',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.primaryGreen,
              labelColor: DesignTokens.buttonPrimaryText,
              onPressed: () async => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}
