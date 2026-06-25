import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  int _strength = 0; // 0–4

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onNewPasswordChanged(String value) {
    var score = 0;
    if (value.length >= 8) score++;
    if (value.contains(RegExp('[A-Z]'))) score++;
    if (value.contains(RegExp('[0-9]'))) score++;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    setState(() => _strength = score);
  }

  Future<void> _handleSubmit() async {
    final current = _currentCtrl.text.trim();
    final newPwd = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty) {
      SmSnackbar.error(context, 'Please enter your current password');
      return;
    }
    if (newPwd.isEmpty || newPwd.length < 8) {
      SmSnackbar.error(
          context, 'New password must be at least 8 characters');
      return;
    }
    if (newPwd != confirm) {
      SmSnackbar.error(context, 'New passwords do not match');
      return;
    }
    if (newPwd == current) {
      SmSnackbar.error(
          context, 'New password must differ from current password');
      return;
    }

    setState(() => _isLoading = true);

    final session = ref.read(sessionControllerProvider);
    final accountId =
        session.maybeWhen(authenticated: (id) => id, orElse: () => '');

    if (accountId.isEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SmSnackbar.error(context, 'Not authenticated');
      return;
    }

    final result = await ref.read(authRepositoryProvider).changePassword(
          accountId: accountId,
          currentPassword: current,
          newPassword: newPwd,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (_) => SmSnackbar.error(context, 'Failed to change password'),
      (_) {
        SmSnackbar.success(context, 'Password changed successfully');
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s24,
                DesignTokens.s16,
                DesignTokens.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PasswordField(
                    controller: _currentCtrl,
                    hint: 'Current Password',
                    obscure: _obscureCurrent,
                    enabled: !_isLoading,
                    onToggle: () => setState(
                        () => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _PasswordField(
                    controller: _newCtrl,
                    hint: 'New Password',
                    obscure: _obscureNew,
                    enabled: !_isLoading,
                    onToggle: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    onChanged: _onNewPasswordChanged,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _PasswordField(
                    controller: _confirmCtrl,
                    hint: 'Confirm New Password',
                    obscure: _obscureConfirm,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    onToggle: () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  _StrengthBars(strength: _strength),
                  const SizedBox(height: DesignTokens.s12),
                  const Text(
                    'Your password must have 8+ characters, with a capital'
                    ' letter, a lowercase letter, a number, & a special'
                    ' character',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      color: DesignTokens.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s8,
              DesignTokens.s16,
              bottomPadding,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.textWhite,
                  disabledBackgroundColor:
                      DesignTokens.primaryGreen.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DesignTokens.textWhite,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: DesignTokens.s8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Password field ───────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.enabled,
    required this.onToggle,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool enabled;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      textInputAction: textInputAction,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        color: DesignTokens.inputFieldData,
      ),
      cursorColor: DesignTokens.primaryGreen,
      decoration: DesignTokens.inputDecoration(
        hintText: hint,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: DesignTokens.iconSmall,
          color: DesignTokens.textMuted,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: DesignTokens.textMuted,
            size: DesignTokens.iconSmall,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ── Strength bars ────────────────────────────────────────────────────────────

class _StrengthBars extends StatelessWidget {
  const _StrengthBars({required this.strength});
  final int strength; // 0–4

  static const List<Color> _colors = [
    Color(0xFFFF4C4C), // 1 – weak (red)
    Color(0xFFFF8C00), // 2 – fair (orange)
    Color(0xFFF1C40F), // 3 – good (yellow)
    DesignTokens.primaryGreen, // 4 – strong (green)
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final filled = i < strength;
        final color =
            filled ? _colors[strength - 1] : DesignTokens.bgAppBodyLight;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? DesignTokens.s8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
