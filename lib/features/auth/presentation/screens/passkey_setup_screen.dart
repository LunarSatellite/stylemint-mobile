import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/widgets/passkey_how_it_works.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Biometric variant for passkey setup.
enum PasskeyType { face, fingerprint }

/// Passkey Setup screen — pixel-matched to Figma frames
/// `9704:9705` (Face) and `9704:14248` (Fingerprint).
///
/// Handles the full register ceremony: challenge → platform biometric → complete.
class PasskeySetupScreen extends ConsumerStatefulWidget {
  const PasskeySetupScreen({super.key, required this.type});

  final PasskeyType type;

  @override
  ConsumerState<PasskeySetupScreen> createState() => _PasskeySetupScreenState();
}

class _PasskeySetupScreenState extends ConsumerState<PasskeySetupScreen> {
  String get _subtitle =>
      widget.type == PasskeyType.face
          ? 'Sign in with just your face. Password-less, secure and works '
              'across all devices'
          : 'Sign in with just your finger print. Password-less, secure and works '
              'across all devices';

  String get _illustrationAsset =>
      widget.type == PasskeyType.face
          ? 'assets/images/auth/auth_passkey_face.png'
          : 'assets/images/auth/auth_passkey_fingerprint.png';

  Future<void> _onSetup() async {
    final accountId = await ref.read(tokenStorageProvider).accountId;
    if (accountId == null || accountId.isEmpty) {
      if (mounted) SmSnackbar.error(context, 'Please log in first');
      return;
    }
    await ref
        .read(passkeyRegisterProvider.notifier)
        .register(accountId: accountId);
  }

  String _errorMessage(NetworkExceptions failure) => failure.maybeWhen(
        validation: (code) => switch (code) {
          'PASSKEY_DEVICE_NOT_SUPPORTED' =>
            'Passkeys are not supported on this device',
          'PASSKEY_NO_CREDENTIALS' => 'No passkey credentials found',
          'PASSKEY_OPTIONS_INVALID' =>
            'Server returned invalid passkey options',
          _ => 'Passkey setup failed. Please try again',
        },
        auth: () => 'Passkey setup was cancelled',
        noInternetConnection: () => 'Network error. Please check your connection',
        orElse: () => 'Passkey setup failed. Please try again',
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passkeyRegisterProvider);
    final isLoading = state.isLoading;

    ref.listen<PasskeyRegisterState>(passkeyRegisterProvider, (_, next) {
      next.maybeWhen(
        loadSuccess: (_) {
          SmSnackbar.success(context, 'Passkey registered successfully!');
          context.go(RouteNames.home);
        },
        loadFailure: (failure) =>
            SmSnackbar.error(context, _errorMessage(failure)),
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
          onPressed: isLoading
              ? null
              : () => context.canPop() ? context.pop() : null,
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
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          _illustrationAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s24),
                      Column(
                        children: [
                          Text(
                            'Setup a Passkey',
                            textAlign: TextAlign.center,
                            style: DesignTokens.titleLarge,
                          ),
                          const SizedBox(height: DesignTokens.s8),
                          Text(
                            _subtitle,
                            textAlign: TextAlign.center,
                            style: DesignTokens.bodyText,
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.s24),
                      const PasskeyHowItWorks(),
                    ],
                  ),
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
                  label: 'Setup Passkey',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  disabled: isLoading,
                  isLoadingInitially: isLoading,
                  suffixIcon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: DesignTokens.iconSmall,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                  onPressed: _onSetup,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
