import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/handle_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class HandleSetupScreen extends ConsumerStatefulWidget {
  const HandleSetupScreen({super.key});

  @override
  ConsumerState<HandleSetupScreen> createState() => _HandleSetupScreenState();
}

class _HandleSetupScreenState extends ConsumerState<HandleSetupScreen> {
  final _handleController = TextEditingController();
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  void _load() {
    final session = ref.read(sessionControllerProvider);
    _accountId = session.maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    if (_accountId != null) {
      ref.read(handleListProvider.notifier).load(_accountId!);
    }
  }

  Future<void> _claimHandle() async {
    if (_accountId == null) return;
    final handle = _handleController.text.trim();
    if (handle.isEmpty) {
      SmSnackbar.error(context, 'Please enter a handle');
      return;
    }
    if (!handle.startsWith('@')) {
      SmSnackbar.error(context, 'Handle must start with @');
      return;
    }
    final cleanHandle = handle.substring(1);
    if (cleanHandle.isEmpty) {
      SmSnackbar.error(context, 'Handle cannot be empty');
      return;
    }
    await ref.read(handleActionProvider.notifier).registerHandle(
      accountId: _accountId!,
      handle: cleanHandle,
    );
  }

  Future<void> _activateHandle(String handleId) async {
    if (_accountId == null) return;
    await ref.read(handleActionProvider.notifier).activateHandle(
      accountId: _accountId!,
      handleId: handleId,
    );
  }

  Future<void> _deactivateHandle(String handleId) async {
    if (_accountId == null) return;
    await ref.read(handleActionProvider.notifier).deactivateHandle(
      accountId: _accountId!,
      handleId: handleId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final handleList = ref.watch(handleListProvider);
    final action = ref.watch(handleActionProvider);

    ref.listen<HandleActionState>(handleActionProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess: (handle) {
          _load();
          _handleController.clear();
          ref.read(handleActionProvider.notifier).reset();
          if (handle != null) {
            SmSnackbar.success(context, 'Handle @${handle.handle} claimed!');
          } else {
            SmSnackbar.success(context, 'Done');
          }
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
        title: const Text('Your Handle',
            style: TextStyle(color: DesignTokens.textWhite)),
      ),
      body: SafeArea(
        child: handleList.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (handles) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose your @handle',
                      style: DesignTokens.titleMedium),
                  const SizedBox(height: DesignTokens.s8),
                  Text(
                    'Your handle is your unique identifier on Style Mint.',
                    style: DesignTokens.bodyText,
                  ),
                  const SizedBox(height: DesignTokens.s24),

                  Row(
                    children: [
                      Container(
                        height: DesignTokens.inputHeight,
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s16),
                        decoration: BoxDecoration(
                          color: DesignTokens.inputFieldFill,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(DesignTokens.inputRadius),
                            bottomLeft:
                                Radius.circular(DesignTokens.inputRadius),
                          ),
                          border: Border.all(
                              color: DesignTokens.inputFieldBorder),
                        ),
                        child: Center(
                          child: Text('@',
                              style: DesignTokens.oneLinerSemibold.copyWith(
                                  color: DesignTokens.textMuted)),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: DesignTokens.inputHeight,
                          child: TextField(
                            controller: _handleController,
                            enabled: !action.isLoading,
                            style: DesignTokens.bodyText,
                            decoration:
                                DesignTokens.inputDecoration(hintText: 'sarahp'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  SizedBox(
                    width: double.infinity,
                    child: SmPrimaryButton(
                      label: 'Claim Handle',
                      onPressed: _claimHandle,
                      isLoadingInitially: action.isLoading,
                      height: DesignTokens.buttonHeight,
                      borderRadius: DesignTokens.buttonRadius,
                      color: DesignTokens.primaryGreen,
                      labelColor: DesignTokens.buttonPrimaryText,
                    ),
                  ),

                  if (handles.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.s32),
                    Text('Your Handles',
                        style: DesignTokens.sectionInnerTitle),
                    const SizedBox(height: DesignTokens.s12),
                    ...handles.map((h) => Container(
                      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
                      padding: const EdgeInsets.all(DesignTokens.s16),
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBody,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.cardRadius),
                        border: Border.all(color: DesignTokens.borderDefault),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('@${h.handle}',
                                    style:
                                        DesignTokens.oneLinerSemibold),
                                const SizedBox(height: DesignTokens.s4),
                                Text(
                                  h.isActive == true
                                      ? 'Active'
                                      : 'Inactive',
                                  style: DesignTokens.smallRegular.copyWith(
                                    color: h.isActive == true
                                        ? DesignTokens.primaryGreen
                                        : DesignTokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (h.isActive == true)
                            GestureDetector(
                              onTap: () => _deactivateHandle(h.id),
                              child: Text('Deactivate',
                                  style: DesignTokens.mediumSemibold.copyWith(
                                      color: DesignTokens.colorError)),
                            )
                          else
                            GestureDetector(
                              onTap: () => _activateHandle(h.id),
                              child: Text('Activate',
                                  style: DesignTokens.mediumSemibold.copyWith(
                                      color: DesignTokens.primaryGreen)),
                            ),
                        ],
                      ),
                    )),
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
                Text('Failed to load handles', style: DesignTokens.bodyText),
                const SizedBox(height: DesignTokens.s16),
                GestureDetector(
                  onTap: _load,
                  child: Text('Retry',
                      style: TextStyle(color: DesignTokens.primaryGreen)),
                ),
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
