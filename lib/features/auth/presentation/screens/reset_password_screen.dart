import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || password.length < 8) {
      SmSnackbar.error(
        context,
        'Password must be at least 8 characters',
      );
      return;
    }

    if (password != confirm) {
      SmSnackbar.error(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.consumePasswordReset(
      token: widget.token,
      newPassword: password,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => SmSnackbar.error(context, 'Failed to reset password'),
      (_) {
        SmSnackbar.success(context, 'Password reset successfully');
        context.go(RouteNames.passwordLogin);
      },
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.appHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DesignTokens.s40),
              Text(
                'Reset Password',
                textAlign: TextAlign.center,
                style: DesignTokens.titleLarge,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                'Enter your new password below',
                textAlign: TextAlign.center,
                style: DesignTokens.bodyText,
              ),
              const SizedBox(height: DesignTokens.s32),
              TextFormField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.inputFieldData,
                ),
                cursorColor: DesignTokens.primaryGreen,
                decoration: DesignTokens.inputDecoration(
                  hintText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: DesignTokens.textMuted,
                      size: DesignTokens.iconSmall,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              TextFormField(
                controller: _confirmController,
                enabled: !_isLoading,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.inputFieldData,
                ),
                cursorColor: DesignTokens.primaryGreen,
                decoration: DesignTokens.inputDecoration(
                  hintText: 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: DesignTokens.textMuted,
                      size: DesignTokens.iconSmall,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              SizedBox(
                height: DesignTokens.buttonHeight,
                child: SmPrimaryButton(
                  label: 'Reset Password',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  disabled: _isLoading,
                  isLoadingInitially: _isLoading,
                  onPressed: _handleReset,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
