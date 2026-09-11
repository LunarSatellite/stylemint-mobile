import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/entities/friend.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/presentation/notifiers/friends_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

typedef GroupCartInviteResult = ({String friendName, String token});

class GroupCartInviteSheet extends ConsumerStatefulWidget {
  const GroupCartInviteSheet({required this.cartId, super.key});

  final String cartId;

  @override
  ConsumerState<GroupCartInviteSheet> createState() =>
      _GroupCartInviteSheetState();
}

class _GroupCartInviteSheetState extends ConsumerState<GroupCartInviteSheet> {
  String? _invitingAccountId;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(
        () => ref.read(friendsNotifierProvider.notifier).loadFriends(),
      ),
    );
  }

  Future<void> _invite(Friend friend) async {
    setState(() {
      _invitingAccountId = friend.userId;
      _error = null;
    });
    final result = await ref
        .read(groupCartDetailNotifierProvider(widget.cartId).notifier)
        .invite(widget.cartId, friend.userId);
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _invitingAccountId = null;
        _error = 'Could not invite this friend.';
      }),
      (token) => Navigator.of(context).pop<GroupCartInviteResult>(
        (friendName: friend.displayName, token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsNotifierProvider).friendsState;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(DesignTokens.s16),
              child: Text(
                'Invite a Friend',
                style: DesignTokens.sectionInnerTitle,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                ),
                child: Text(
                  _error!,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ),
            const Divider(color: DesignTokens.borderDefault),
            Expanded(
              child: friendsState.when(
                initial: _loader,
                loadInProgress: _loader,
                loadFailure: (_) => const Center(
                  child: Text(
                    'Could not load friends.',
                    style: DesignTokens.mediumRegular,
                  ),
                ),
                loadSuccess: (friends, _, _) {
                  if (friends.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(DesignTokens.s24),
                        child: Text(
                          'Connect with someone in Friends before '
                          'inviting them.',
                          textAlign: TextAlign.center,
                          style: DesignTokens.mediumRegular,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                    ),
                    itemCount: friends.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: DesignTokens.borderDefault,
                    ),
                    itemBuilder: (_, index) {
                      final friend = friends[index];
                      final inviting = _invitingAccountId == friend.userId;
                      return ListTile(
                        enabled: _invitingAccountId == null,
                        leading: CircleAvatar(
                          backgroundImage: friend.avatarUrl.isEmpty
                              ? null
                              : NetworkImage(friend.avatarUrl),
                          child: friend.avatarUrl.isEmpty
                              ? const Icon(Icons.person_outline)
                              : null,
                        ),
                        title: Text(friend.displayName),
                        subtitle: friend.handle.isEmpty
                            ? null
                            : Text('@${friend.handle}'),
                        trailing: inviting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        onTap: inviting ? null : () => _invite(friend),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());
}
