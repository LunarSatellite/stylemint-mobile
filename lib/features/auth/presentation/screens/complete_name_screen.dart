import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Post-sign-in "What's your name?" step.
///
/// Shown after any sign-in that authenticates without a confirmed display name
/// (magic-link, passkey, or an OTP account whose name wasn't captured inline).
/// On submit it persists the name via `PATCH /v1/accounts/{id}` and then enters
/// the onboarding journey (pick interests → follow creators → …) — reaching
/// this screen means a name was required, which always implies onboarding.
class CompleteNameScreen extends ConsumerStatefulWidget {
  const CompleteNameScreen({
    super.key,
    required this.accountId,
  });

  /// Account to update. May be empty if not routed with one — we then fall back
  /// to the id persisted in secure storage by the session that just signed in.
  final String accountId;

  @override
  ConsumerState<CompleteNameScreen> createState() => _CompleteNameScreenState();
}

class _CompleteNameScreenState extends ConsumerState<CompleteNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SmSnackbar.error(context, 'Please enter your name');
      _nameFocusNode.requestFocus();
      return;
    }

    var accountId = widget.accountId;
    if (accountId.isEmpty) {
      accountId = await ref.read(tokenStorageProvider).accountId ?? '';
    }
    if (accountId.isEmpty) {
      if (mounted) {
        SmSnackbar.error(context, 'Something went wrong. Please sign in again');
      }
      return;
    }

    await ref
        .read(displayNameProvider.notifier)
        .setDisplayName(accountId: accountId, displayName: name);
  }

  String _errorMessage(NetworkExceptions failure) => failure.maybeWhen(
        validation: (_) => 'Please enter a valid name',
        noInternetConnection: () =>
            'Network error. Please check your connection',
        serverUnavailable: () =>
            'StyleMint is temporarily unavailable. Please try again in a moment',
        orElse: () => 'Could not save your name. Please try again',
      );

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(displayNameProvider).isLoading;

    ref.listen<DisplayNameUpdateState>(displayNameProvider, (_, next) {
      next.maybeWhen(
        // A name was required to reach this screen → always continue into the
        // onboarding journey (pick interests → follow creators → …).
        loadSuccess: () => context.go(RouteNames.pickInterests),
        loadFailure: (failure) =>
            SmSnackbar.error(context, _errorMessage(failure)),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
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
                      Column(
                        children: [
                          Text(
                            "What's your name?",
                            textAlign: TextAlign.center,
                            style: DesignTokens.titleLarge,
                          ),
                          const SizedBox(height: DesignTokens.s8),
                          Text(
                            'Tell us what to call you. You can change this later.',
                            textAlign: TextAlign.center,
                            style: DesignTokens.bodyText,
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.s24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Your name',
                          style: DesignTokens.mediumSemibold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        enabled: !isLoading,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        maxLength: 64,
                        onFieldSubmitted: (_) => _submit(),
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: DesignTokens.inputFieldData,
                        ),
                        cursorColor: DesignTokens.primaryGreen,
                        decoration: DesignTokens.inputDecoration(
                          hintText: 'e.g. Alice',
                        ).copyWith(counterText: ''),
                      ),
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
                  label: 'Continue',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  disabled: isLoading,
                  isLoadingInitially: isLoading,
                  onPressed: _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
