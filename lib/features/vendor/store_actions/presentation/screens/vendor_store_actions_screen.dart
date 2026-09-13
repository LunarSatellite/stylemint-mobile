import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/entities/store_actions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Voyager "Autonomous Retail Operations" for vendors: a ranked list of
/// things worth doing in the store now — restock what is selling out, add
/// photos to live products, promote stock that isn't moving — each opening
/// the product so the vendor can act. Nothing changes automatically.
class VendorStoreActionsScreen extends ConsumerWidget {
  const VendorStoreActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeActionsNotifierProvider);
    final notifier = ref.read(storeActionsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Store to-do', style: DesignTokens.oneLinerSemibold),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          StoreActionsLoading() => const SmPageLoader(),
          StoreActionsFailed() => SmErrorView(
            message: 'Could not load your store to-do list.',
            onRetry: notifier.load,
          ),
          StoreActionsLoaded(:final queue) when queue.isEmpty =>
            const _AllClearView(),
          StoreActionsLoaded(:final queue) => RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: notifier.refresh,
            child: _ActionList(
              actions: queue.actions,
              onOpenProduct: (action) =>
                  _openProduct(context, notifier, action),
            ),
          ),
        },
      ),
    );
  }

  /// Photos go straight to the image editor; everything else opens the
  /// product editor (stock and price live there). The list is re-checked on
  /// return so fixed items drop off.
  Future<void> _openProduct(
    BuildContext context,
    StoreActionsNotifier notifier,
    StoreAction action,
  ) async {
    if (action.kind == StoreActionKind.addProductImages) {
      await context.push<Object?>(
        RouteNames.vendorEditProductImages,
        extra: action.productId,
      );
    } else {
      await context.push<Object?>(
        RouteNames.vendorEditProduct.replaceFirst(
          ':productId',
          action.productId,
        ),
      );
    }
    if (context.mounted) unawaited(notifier.refresh());
  }
}

class _ActionList extends StatelessWidget {
  const _ActionList({required this.actions, required this.onOpenProduct});

  final List<StoreAction> actions;
  final ValueChanged<StoreAction> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s24,
      ),
      itemCount: actions.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'Suggestions from your stock and sales, most urgent first. '
            'Nothing changes until you act.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          );
        }
        final action = actions[index - 1];
        return _StoreActionCard(
          key: ValueKey('store-action-${index - 1}'),
          action: action,
          onOpenProduct: action.productId.isEmpty
              ? null
              : () => onOpenProduct(action),
        );
      },
    );
  }
}

class _StoreActionCard extends StatelessWidget {
  const _StoreActionCard({
    required this.action,
    required this.onOpenProduct,
    super.key,
  });

  final StoreAction action;
  final VoidCallback? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final color = storeActionSeverityColor(action.severity);
    final value = action.valueAtStake;

    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Container(
        decoration: DesignTokens.cardDecoration(),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SeverityChip(severity: action.severity),
                      const SizedBox(height: DesignTokens.s8),
                      if (action.productName.isNotEmpty)
                        Text(
                          action.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.textWhite,
                            fontSize: 14,
                          ),
                        ),
                      if (action.sku != null)
                        Text(
                          'SKU ${action.sku}',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      const SizedBox(height: DesignTokens.s4),
                      Text(
                        action.recommendation,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                      if (action.evidence.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.s6),
                        Text(
                          action.evidence.join(' · '),
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ],
                      if (value != null) ...[
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          '${valueAtStakeLabel(action.kind)}: '
                          '${formatMoney(value)}',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (onOpenProduct != null) ...[
                        const SizedBox(height: DesignTokens.s12),
                        OutlinedButton(
                          onPressed: onOpenProduct,
                          style: DesignTokens.outlinedButtonStyle(),
                          child: Text(
                            storeActionButtonLabel(action.kind),
                            style: DesignTokens.smallRegular.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.severity});

  final StoreActionSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = storeActionSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        storeActionSeverityLabel(severity),
        style: DesignTokens.smallRegular.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AllClearView extends StatelessWidget {
  const _AllClearView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.task_alt_rounded,
              size: 56,
              color: DesignTokens.primaryGreen,
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'Nothing needs your attention right now',
              textAlign: TextAlign.center,
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s6),
            Text(
              "We'll list things here when stock runs low, something sells "
              'out, or a product needs photos.',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// High is red-ish, Medium amber, Low neutral.
Color storeActionSeverityColor(StoreActionSeverity severity) =>
    switch (severity) {
      StoreActionSeverity.high => DesignTokens.colorError,
      StoreActionSeverity.medium => DesignTokens.warning500,
      StoreActionSeverity.low => DesignTokens.textMuted,
    };

String storeActionSeverityLabel(StoreActionSeverity severity) =>
    switch (severity) {
      StoreActionSeverity.high => 'Urgent',
      StoreActionSeverity.medium => 'Soon',
      StoreActionSeverity.low => 'When you can',
    };

String storeActionButtonLabel(StoreActionKind kind) => switch (kind) {
  StoreActionKind.restockSoon ||
  StoreActionKind.soldOutWhileSelling => 'Update stock',
  StoreActionKind.addProductImages => 'Add photos',
  StoreActionKind.slowMovingStock => 'Edit product',
  StoreActionKind.unknown => 'Open product',
};

String valueAtStakeLabel(StoreActionKind kind) => switch (kind) {
  StoreActionKind.restockSoon ||
  StoreActionKind.soldOutWhileSelling => 'Sales at risk',
  StoreActionKind.slowMovingStock => 'Stock sitting unsold',
  StoreActionKind.addProductImages || StoreActionKind.unknown => 'At stake',
};
