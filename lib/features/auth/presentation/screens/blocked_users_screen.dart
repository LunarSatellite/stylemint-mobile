import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/blocked_users_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() =>
      _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
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
      ref.read(blockedUsersProvider.notifier).load(_accountId!);
    }
  }

  Future<void> _unblockUser(String blockedAccountId) async {
    if (_accountId == null) return;
    await ref.read(blockedUsersProvider.notifier).unblockUser(
      accountId: _accountId!,
      blockedAccountId: blockedAccountId,
    );
    SmSnackbar.success(context, 'User unblocked');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blockedUsersProvider);

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
        title: const Text('Blocked Users',
            style: TextStyle(color: DesignTokens.textWhite)),
      ),
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (blockedUsers) {
            if (blockedUsers.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.s32),
                  child: Text('No blocked users',
                      style: TextStyle(color: DesignTokens.textMuted)),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.s16),
              itemCount: blockedUsers.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: DesignTokens.s8),
              itemBuilder: (context, index) {
                final user = blockedUsers[index];
                return Container(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  decoration: BoxDecoration(
                    color: DesignTokens.bgAppBody,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.cardRadius),
                    border: Border.all(color: DesignTokens.borderDefault),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: DesignTokens.avatarSmall / 2,
                        backgroundColor: DesignTokens.bgAppBodyLight,
                        backgroundImage:
                            user.blockedUserAvatarUrl != null
                                ? NetworkImage(user.blockedUserAvatarUrl!)
                                : null,
                        child: user.blockedUserAvatarUrl == null
                            ? const Icon(Icons.person,
                                size: DesignTokens.iconSmall,
                                color: DesignTokens.textMuted)
                            : null,
                      ),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.blockedUserName ?? 'Unknown User',
                              style: DesignTokens.oneLinerSemibold,
                            ),
                            const SizedBox(height: DesignTokens.s4),
                            Text(
                              user.blockedUtc != null
                                  ? 'Blocked: ${user.blockedUtc!.toLocal().toString().split('.')[0]}'
                                  : '',
                              style: DesignTokens.tiny,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _unblockUser(user.blockedAccountId),
                        child: Text('Unblock',
                            style: DesignTokens.mediumSemibold.copyWith(
                                color: DesignTokens.primaryGreen)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loadFailure: (failure) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: DesignTokens.colorError, size: 48),
                const SizedBox(height: DesignTokens.s16),
                Text('Failed to load blocked users',
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
