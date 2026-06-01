import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/external_ids_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class LinkedAccountsScreen extends ConsumerStatefulWidget {
  const LinkedAccountsScreen({super.key});

  @override
  ConsumerState<LinkedAccountsScreen> createState() =>
      _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends ConsumerState<LinkedAccountsScreen> {
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
      ref.read(externalIdsProvider.notifier).load(_accountId!);
    }
  }

  Future<void> _unlink(String provider) async {
    if (_accountId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Unlink Account',
            style: TextStyle(color: DesignTokens.textWhite)),
        content: Text(
          'Are you sure you want to unlink your $provider account?',
          style: const TextStyle(color: DesignTokens.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: DesignTokens.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink',
                style: TextStyle(color: DesignTokens.colorError)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(externalIdsProvider.notifier).unlinkExternalId(
        accountId: _accountId!,
        provider: provider,
      );
      SmSnackbar.success(context, '$provider unlinked');
    }
  }

  static const _availableProviders = [
    {'name': 'Google', 'icon': Icons.g_mobiledata},
    {'name': 'Apple', 'icon': Icons.apple},
    {'name': 'Facebook', 'icon': Icons.facebook},
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(externalIdsProvider);

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
        title: const Text('Linked Accounts',
            style: TextStyle(color: DesignTokens.textWhite)),
      ),
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (linkedIds) {
            final linkedProviders =
                linkedIds.map((e) => e.provider).toSet();

            return ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: _availableProviders.map((provider) {
                final isLinked = linkedProviders.contains(provider['name']);

                return Container(
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
                      Icon(provider['icon'] as IconData,
                          size: DesignTokens.iconLarge,
                          color: DesignTokens.textWhite),
                      const SizedBox(width: DesignTokens.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider['name'] as String,
                              style: DesignTokens.oneLinerSemibold,
                            ),
                            const SizedBox(height: DesignTokens.s4),
                            Text(
                              isLinked ? 'Linked' : 'Not linked',
                              style: DesignTokens.smallRegular.copyWith(
                                color: isLinked
                                    ? DesignTokens.primaryGreen
                                    : DesignTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLinked)
                        GestureDetector(
                          onTap: () =>
                              _unlink(provider['name'] as String),
                          child: Text(
                            'Unlink',
                            style: DesignTokens.mediumSemibold.copyWith(
                                color: DesignTokens.colorError),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            SmSnackbar.info(
                                context, 'Linking coming soon');
                          },
                          child: Text(
                            'Link',
                            style: DesignTokens.mediumSemibold.copyWith(
                                color: DesignTokens.primaryGreen),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loadFailure: (failure) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: DesignTokens.colorError, size: 48),
                const SizedBox(height: DesignTokens.s16),
                Text('Failed to load linked accounts',
                    style: DesignTokens.bodyText),
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
