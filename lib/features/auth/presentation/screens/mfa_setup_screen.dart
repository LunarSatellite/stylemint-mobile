import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/mfa_method_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/totp_enrollment_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/mfa_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final session = ref.read(sessionControllerProvider);
    _accountId = session.maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    if (_accountId != null) {
      ref.read(mfaListProvider.notifier).load(_accountId!);
    }
  }

  Future<void> _beginEnrollment() async {
    if (_accountId == null) return;
    await ref.read(totpEnrollmentProvider.notifier).beginEnrollment(_accountId!);
  }

  Future<void> _confirmEnrollment(String methodId, String code) async {
    if (_accountId == null) return;
    await ref.read(totpEnrollmentProvider.notifier).confirm(
      accountId: _accountId!,
      methodId: methodId,
      code: code,
    );
  }

  Future<void> _disableMethod(String methodId) async {
    if (_accountId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Disable MFA Method',
            style: TextStyle(color: DesignTokens.textWhite)),
        content: const Text(
          'Are you sure you want to disable this MFA method?',
          style: TextStyle(color: DesignTokens.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: DesignTokens.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable',
                style: TextStyle(color: DesignTokens.colorError)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(mfaActionProvider.notifier).disableMfa(
        accountId: _accountId!,
        methodId: methodId,
      );
    }
  }

  Future<void> _setPrimary(String methodId) async {
    if (_accountId == null) return;
    ref.read(mfaActionProvider.notifier).setPrimary(
      accountId: _accountId!,
      methodId: methodId,
    );
  }

  void _showRenameDialog(String methodId, String currentLabel) {
    final controller = TextEditingController(text: currentLabel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Rename Method',
            style: TextStyle(color: DesignTokens.textWhite)),
        content: TextField(
          controller: controller,
          style: DesignTokens.bodyText,
          decoration: DesignTokens.inputDecoration(hintText: 'Label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: DesignTokens.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(mfaActionProvider.notifier).renameLabel(
                accountId: _accountId!,
                methodId: methodId,
                label: controller.text.trim(),
              );
            },
            child: const Text('Save',
                style: TextStyle(color: DesignTokens.primaryGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mfaState = ref.watch(mfaListProvider);
    final enrollmentState = ref.watch(totpEnrollmentProvider);
    ref.listen<MfaActionState>(mfaActionProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess: () {
          SmSnackbar.success(context, 'Done');
          _load();
        },
        loadFailure: (_) => SmSnackbar.error(context, 'Action failed'),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: DesignTokens.textWhite, size: DesignTokens.iconMedium),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Two-Factor Authentication',
            style: TextStyle(color: DesignTokens.textWhite)),
      ),
      body: SafeArea(
        child: mfaState.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (methods) {
            final totpMethod = enrollmentState.maybeWhen(
              loadSuccess: (enrollment) => enrollment,
              orElse: () => null,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Security Methods',
                      style: DesignTokens.sectionInnerTitle),
                  const SizedBox(height: DesignTokens.s16),

                  if (methods.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: DesignTokens.s24),
                      child: Text('No MFA methods configured yet.',
                          style: TextStyle(color: DesignTokens.textMuted)),
                    ),

                  ...methods.map((m) => _MfaMethodTile(
                    method: m,
                    onSetPrimary: () => _setPrimary(m.id),
                    onDisable: () => _disableMethod(m.id),
                    onRename: () =>
                        _showRenameDialog(m.id, m.label ?? ''),
                  )),

                  const SizedBox(height: DesignTokens.s32),

                  Text('Add Method', style: DesignTokens.sectionInnerTitle),
                  const SizedBox(height: DesignTokens.s16),

                  SmPrimaryButton(
                    label: 'Enable Authenticator App',
                    onPressed: _beginEnrollment,
                    isLoadingInitially: enrollmentState.isLoading,
                    height: DesignTokens.buttonHeight,
                    borderRadius: DesignTokens.buttonRadius,
                    color: DesignTokens.primaryGreen,
                    labelColor: DesignTokens.buttonPrimaryText,
                  ),

                  if (totpMethod != null) ...[
                    const SizedBox(height: DesignTokens.s24),
                    _TotpVerificationCard(
                      enrollment: totpMethod,
                      onVerify: _confirmEnrollment,
                      isLoading: enrollmentState.isLoading,
                    ),
                  ],
                ],
              ),
            );
          },
          loadFailure: (failure) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: DesignTokens.colorError, size: 48),
                const SizedBox(height: DesignTokens.s16),
                Text('Failed to load MFA methods',
                    style: DesignTokens.bodyText),
                const SizedBox(height: DesignTokens.s16),
                SmTextButton(label: 'Retry', onPressed: _load),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loader() =>
      const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen));
}

class _MfaMethodTile extends StatelessWidget {
  final MfaMethodDto method;
  final VoidCallback onSetPrimary;
  final VoidCallback onDisable;
  final VoidCallback onRename;

  const _MfaMethodTile({
    required this.method,
    required this.onSetPrimary,
    required this.onDisable,
    required this.onRename,
  });

  String get _methodTypeLabel {
    switch (method.methodType) {
      case 1:
        return 'Authenticator App (TOTP)';
      default:
        return 'Method ${method.methodType}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  method.label ?? _methodTypeLabel,
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
              if (method.isPrimary == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreenDark,
                    borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
                  ),
                  child: Text('Primary',
                      style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.primaryGreen)),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(_methodTypeLabel, style: DesignTokens.smallRegular),
          if (method.confirmedUtc != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Confirmed: ${method.confirmedUtc!.toLocal().toString().split('.')[0]}',
              style: DesignTokens.tiny,
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SmTextButton(label: 'Rename', onPressed: onRename),
              const SizedBox(width: DesignTokens.s8),
              if (method.isPrimary != true)
                SmTextButton(label: 'Set Primary', onPressed: onSetPrimary),
              const SizedBox(width: DesignTokens.s8),
              SmTextButton(
                label: 'Disable',
                onPressed: onDisable,
                color: DesignTokens.colorError,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotpVerificationCard extends StatefulWidget {
  final TotpEnrollmentDto enrollment;
  final Future<void> Function(String methodId, String code) onVerify;
  final bool isLoading;

  const _TotpVerificationCard({
    required this.enrollment,
    required this.onVerify,
    required this.isLoading,
  });

  @override
  State<_TotpVerificationCard> createState() => _TotpVerificationCardState();
}

class _TotpVerificationCardState extends State<_TotpVerificationCard> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set up Authenticator', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s12),

          SizedBox(
            height: 200,
            width: 200,
            child: widget.enrollment.qrCodeUrl.isNotEmpty
                ? Image.network(
                    widget.enrollment.qrCodeUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 200,
                        color: DesignTokens.textMuted),
                  )
                : const Icon(Icons.qr_code, size: 200,
                    color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s12),

          Text('Manual secret:', style: DesignTokens.smallRegular),
          const SizedBox(height: DesignTokens.s4),
          SelectableText(
            widget.enrollment.secret,
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          TextField(
            controller: _codeController,
            enabled: !widget.isLoading,
            maxLength: 6,
            keyboardType: TextInputType.number,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              hintText: 'Enter 6-digit code',
            ),
          ),
          const SizedBox(height: DesignTokens.s12),

          SizedBox(
            width: double.infinity,
            child: SmPrimaryButton(
              label: 'Verify',
              onPressed: () async {
                final code = _codeController.text.trim();
                if (code.length != 6) {
                  SmSnackbar.error(context, 'Please enter a 6-digit code');
                  return;
                }
                await widget.onVerify(
                    widget.enrollment.methodId ?? '', code);
              },
              isLoadingInitially: widget.isLoading,
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.primaryGreen,
              labelColor: DesignTokens.buttonPrimaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class SmTextButton extends StatelessWidget {
  const SmTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Text(
        label,
        style: DesignTokens.mediumSemibold.copyWith(
          color: color ?? DesignTokens.primaryGreen,
        ),
      ),
    );
  }
}
