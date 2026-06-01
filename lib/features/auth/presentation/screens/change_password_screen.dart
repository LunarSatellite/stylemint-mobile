import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChange() async {
    final current = _currentPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty) {
      SmSnackbar.error(context, 'Please enter your current password');
      return;
    }

    if (newPwd.isEmpty || newPwd.length < 8) {
      SmSnackbar.error(
        context,
        'New password must be at least 8 characters',
      );
      return;
    }

    if (newPwd != confirm) {
      SmSnackbar.error(context, 'New passwords do not match');
      return;
    }

    if (newPwd == current) {
      SmSnackbar.error(
        context,
        'New password must be different from current password',
      );
      return;
    }

    setState(() => _isLoading = true);

    final session =
        ref.read(sessionControllerProvider);
    final accountId = session.maybeWhen(
      authenticated: (id) => id,
      orElse: () => '',
    );

    if (accountId.isEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SmSnackbar.error(context, 'Not authenticated');
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.changePassword(
      accountId: accountId,
      currentPassword: current,
      newPassword: newPwd,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => SmSnackbar.error(context, 'Failed to change password'),
      (_) {
        SmSnackbar.success(context, 'Password changed successfully');
        context.pop();
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
        title: Text(
          'Change Password',
          style: DesignTokens.sectionInnerTitle,
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
              const SizedBox(height: DesignTokens.s24),
              TextFormField(
                controller: _currentPasswordController,
                enabled: !_isLoading,
                obscureText: _obscureCurrent,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.inputFieldData,
                ),
                cursorColor: DesignTokens.primaryGreen,
                decoration: DesignTokens.inputDecoration(
                  hintText: 'Current Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: DesignTokens.textMuted,
                      size: DesignTokens.iconSmall,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscureCurrent = !_obscureCurrent,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              TextFormField(
                controller: _newPasswordController,
                enabled: !_isLoading,
                obscureText: _obscureNew,
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
                      _obscureNew
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: DesignTokens.textMuted,
                      size: DesignTokens.iconSmall,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscureNew = !_obscureNew,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              TextFormField(
                controller: _confirmPasswordController,
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
                  label: 'Change Password',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  disabled: _isLoading,
                  isLoadingInitially: _isLoading,
                  onPressed: _handleChange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
