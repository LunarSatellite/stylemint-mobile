import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/notifiers/group_cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/screens/group_cart_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class GroupCartListScreen extends ConsumerWidget {
  const GroupCartListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupCartsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title:
            const Text('Group Carts', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (carts) => _buildBody(context, ref, carts),
        loadFailure: (failure) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load group carts',
                  style: DesignTokens.mediumRegular),
              const SizedBox(height: DesignTokens.s12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(groupCartsNotifierProvider.notifier).loadAll(),
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            backgroundColor: DesignTokens.bgAppBodyLight,
            onPressed: () => _showJoinDialog(context, ref),
            child: const Icon(Icons.group_add, color: DesignTokens.textWhite),
          ),
          const SizedBox(width: DesignTokens.s12),
          FloatingActionButton.extended(
            heroTag: 'create-cart',
            backgroundColor: DesignTokens.primaryGreen,
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add, color: DesignTokens.buttonPrimaryText),
            label: const Text('Create Group Cart',
                style: TextStyle(color: DesignTokens.buttonPrimaryText)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, List<GroupCart> carts) {
    if (carts.isEmpty) {
      return const Center(
        child: Text('No active group carts',
            style: DesignTokens.mediumRegular),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(groupCartsNotifierProvider.notifier).loadAll(),
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.s16),
        itemCount: carts.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: DesignTokens.s12),
        itemBuilder: (context, index) {
          final cart = carts[index];
          return _buildCartTile(context, cart);
        },
      ),
    );
  }

  Widget _buildCartTile(BuildContext context, GroupCart cart) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupCartDetailScreen(cartId: cart.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(cart.name,
                      style: DesignTokens.oneLinerSemibold),
                ),
                _statusBadge(cart.status),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...cart.participants.take(3).map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundImage:
                                  NetworkImage(p.userAvatarUrl),
                            ),
                          ),
                        ),
                    if (cart.participants.length > 3)
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: DesignTokens.bgAppBodyLight,
                        child: Text(
                          '+${cart.participants.length - 3}',
                          style: DesignTokens.tiny,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: DesignTokens.s12),
                Text('${cart.items.length} items',
                    style: DesignTokens.mediumRegular),
                const Spacer(),
                Text(formatMoney(cart.subtotal),
                    style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.primaryGreen)),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Text('Code: ${cart.inviteCode}',
                style: DesignTokens.smallRegular),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(GroupCartStatus status) {
    Color color;
    String label;
    switch (status) {
      case GroupCartStatus.active:
        color = DesignTokens.primaryGreen;
        label = 'Active';
      case GroupCartStatus.checkout:
        color = DesignTokens.colorInfo;
        label = 'Checkout';
      case GroupCartStatus.completed:
        color = DesignTokens.textMuted;
        label = 'Completed';
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Text(label,
          style: DesignTokens.tiny.copyWith(color: color)),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Create Group Cart'),
        content: TextField(
          controller: controller,
          decoration: DesignTokens.inputDecoration(hintText: 'Cart name'),
          style: DesignTokens.oneLinerRegular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(groupCartsNotifierProvider.notifier)
                    .create(name);
                Navigator.of(ctx).pop();
              }
            },
            style: DesignTokens.primaryButtonStyle(),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Join Group Cart'),
        content: TextField(
          controller: controller,
          decoration:
              DesignTokens.inputDecoration(hintText: 'Enter invite code'),
          style: DesignTokens.oneLinerRegular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                ref
                    .read(groupCartsNotifierProvider.notifier)
                    .join(code);
                Navigator.of(ctx).pop();
              }
            },
            style: DesignTokens.primaryButtonStyle(),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());
}
