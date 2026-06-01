import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/notifiers/group_cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/widgets/group_cart_item_tile.dart';
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
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (cart) => _buildContent(context, ref, cart),
        loadFailure: (failure) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load cart',
                  style: DesignTokens.mediumRegular),
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

  Widget _buildContent(
      BuildContext context, WidgetRef ref, GroupCart cart) {
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
                  ...cart.participants.map((p) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: p.userName,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                NetworkImage(p.userAvatarUrl),
                          ),
                        ),
                      )),
                  const Spacer(),
                  Text('${cart.items.length} items',
                      style: DesignTokens.mediumRegular),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s12,
                          vertical: DesignTokens.s8),
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        borderRadius: BorderRadius.circular(
                            DesignTokens.inputRadius),
                      ),
                      child: Text('Code: ${cart.inviteCode}',
                          style: DesignTokens.mediumRegular),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  IconButton(
                    icon: const Icon(Icons.copy,
                        color: DesignTokens.primaryGreen),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: cart.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Invite code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: DesignTokens.borderDefault, height: 1),
        Expanded(
          child: cart.items.isEmpty
              ? const Center(
                  child: Text('No items yet. Add something!',
                      style: DesignTokens.mediumRegular))
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
                              .read(groupCartDetailNotifierProvider(cartId)
                                  .notifier)
                              .removeItem(cart.id, cart.items[index].id);
                        },
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBody,
            border: const Border(
                top: BorderSide(color: DesignTokens.borderDefault)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total', style: DesignTokens.smallRegular),
                  Text(formatMoney(cart.subtotal),
                      style: DesignTokens.sectionInnerTitle.copyWith(
                          color: DesignTokens.primaryGreen)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: cart.items.isNotEmpty &&
                        cart.status == GroupCartStatus.active
                    ? () {
                        ref
                            .read(groupCartDetailNotifierProvider(cartId)
                                .notifier)
                            .checkout(cart.id);
                      }
                    : null,
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Checkout Together'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.buttonPrimaryText,
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s20,
                      vertical: DesignTokens.s12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());
}
