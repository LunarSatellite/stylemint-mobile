import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/notifiers/group_cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/widgets/group_cart_item_tile.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/widgets/group_cart_invite_sheet.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class GroupCartDetailScreen extends ConsumerWidget {
  const GroupCartDetailScreen({super.key, required this.cartId});

  final String cartId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupCartDetailNotifierProvider(cartId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Group Cart', style: DesignTokens.sectionInnerTitle),
        actions: [
          IconButton(
            tooltip: 'Invite a friend',
            onPressed: () => _showInviteFriends(context),
            icon: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (cart) => _buildContent(context, ref, cart),
        loadFailure: (failure) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Failed to load cart',
                style: DesignTokens.mediumRegular,
              ),
              const SizedBox(height: DesignTokens.s12),
              ElevatedButton(
                onPressed: () => ref
                    .read(groupCartDetailNotifierProvider(cartId).notifier)
                    .loadCart(cartId),
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, GroupCart cart) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cart.name, style: DesignTokens.titleMedium),
              const SizedBox(height: DesignTokens.s8),
              Row(
                children: [
                  ...cart.participants.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Tooltip(
                        message: p.userName,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(p.userAvatarUrl),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${cart.items.length} items',
                    style: DesignTokens.mediumRegular,
                  ),
                ],
              ),
              if (cart.inviteCode.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s12,
                          vertical: DesignTokens.s8,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppBodyLight,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.inputRadius,
                          ),
                        ),
                        child: Text(
                          'Code: ${cart.inviteCode}',
                          style: DesignTokens.mediumRegular,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: DesignTokens.primaryGreen,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: cart.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite code copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(color: DesignTokens.borderDefault, height: 1),
        Expanded(
          child: cart.items.isEmpty
              ? const Center(
                  child: Text(
                    'No items yet. Add something!',
                    style: DesignTokens.mediumRegular,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                      child: GroupCartItemTile(
                        item: cart.items[index],
                        onRemove: () {
                          ref
                              .read(
                                groupCartDetailNotifierProvider(
                                  cartId,
                                ).notifier,
                              )
                              .removeItem(cart.id, cart.items[index].id);
                        },
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          key: const Key('group-cart-bottom-safe-area'),
          top: false,
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              border: const Border(
                top: BorderSide(color: DesignTokens.borderDefault),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total', style: DesignTokens.smallRegular),
                    Text(
                      formatMoney(cart.subtotal),
                      style: DesignTokens.sectionInnerTitle.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: cart.status == GroupCartStatus.active
                      ? () => _closeCart(context, ref, cart)
                      : null,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Close Group Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryGreen,
                    foregroundColor: DesignTokens.buttonPrimaryText,
                    minimumSize: const Size(
                      0,
                      DesignTokens.buttonHeight,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s20,
                      vertical: DesignTokens.s12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.buttonRadius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showInviteFriends(BuildContext context) async {
    final result = await showModalBottomSheet<GroupCartInviteResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      builder: (_) => GroupCartInviteSheet(cartId: cartId),
    );
    if (result == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Invite ${result.friendName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send this one-time invite code to your friend:'),
            const SizedBox(height: DesignTokens.s12),
            SelectableText(result.token, style: DesignTokens.mediumSemibold),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.token));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite code copied!')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeCart(
    BuildContext context,
    WidgetRef ref,
    GroupCart cart,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close Group Cart?'),
        content: const Text(
          'Friends will no longer be able to join or vote on this cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(groupCartDetailNotifierProvider(cartId).notifier)
        .checkout(cart.id);
    if (!context.mounted) return;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not close group cart.')),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group cart closed.')),
      ),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());
}
