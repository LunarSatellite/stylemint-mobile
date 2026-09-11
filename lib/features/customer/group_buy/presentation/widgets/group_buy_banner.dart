import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/domain/entities/group_buy.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Product-detail card for Group Buy — "buy together for a group discount".
/// Shows the first open campaign for this product with a Join button, or a
/// "Start a Group Buy" CTA when none is running. Renders nothing while
/// loading or on error, same passive-upsell pattern as the urgency banner.
class GroupBuyBanner extends ConsumerWidget {
  const GroupBuyBanner({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(activeGroupBuysForProductProvider(productId));
    return campaigns.when(
      data: (list) {
        final open = list.where((g) => g.isOpen).toList();
        if (open.isEmpty) {
          return _StartCard(productId: productId);
        }
        return _ActiveCard(groupBuy: open.first);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ActiveCard extends ConsumerWidget {
  const _ActiveCard({required this.groupBuy});

  final GroupBuy groupBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        border: Border.all(color: DesignTokens.primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, size: 18, color: DesignTokens.primaryGreen),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  'Group Buy: ${groupBuy.discountPercent.toStringAsFixed(0)}% off '
                  'when ${groupBuy.targetBuyerCount} people join',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: groupBuy.progress,
              minHeight: 6,
              backgroundColor: DesignTokens.bgAppBodyLight,
              valueColor: const AlwaysStoppedAnimation(DesignTokens.primaryGreen),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${groupBuy.commitCount}/${groupBuy.targetBuyerCount} joined · '
                  '${groupBuy.slotsRemaining} spots left',
                  style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                ),
              ),
              TextButton(
                onPressed: () => _join(context, ref),
                child: const Text('Join'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final either = await ref.read(groupBuyRepositoryProvider).join(groupBuy.id);
    if (!context.mounted) return;
    ref.invalidate(activeGroupBuysForProductProvider(groupBuy.productId));
    either.fold(
      (_) => SmSnackbar.error(context, "Couldn't join this group buy. Please try again."),
      (_) => SmSnackbar.success(context, 'You joined the group buy!'),
    );
  }
}

class _StartCard extends ConsumerWidget {
  const _StartCard({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _start(context, ref),
      icon: const Icon(Icons.groups_outlined, size: 18),
      label: const Text('Start a Group Buy for a discount'),
      style: OutlinedButton.styleFrom(
        foregroundColor: DesignTokens.primaryGreen,
        side: const BorderSide(color: DesignTokens.primaryGreen),
        minimumSize: const Size(double.infinity, 40),
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final either = await ref.read(groupBuyRepositoryProvider).start(
          productId: productId,
          targetBuyerCount: 5,
          discountPercent: 10,
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 3)),
        );
    if (!context.mounted) return;
    ref.invalidate(activeGroupBuysForProductProvider(productId));
    either.fold(
      (_) => SmSnackbar.error(context, "Couldn't start a group buy. Please try again."),
      (_) => SmSnackbar.success(context, 'Group buy started — share it with friends!'),
    );
  }
}
