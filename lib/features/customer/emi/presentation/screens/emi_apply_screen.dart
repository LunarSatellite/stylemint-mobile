import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/checkout_emi_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What the product page hands the EMI application.
class EmiApplyArgs {
  const EmiApplyArgs({
    required this.productId,
    required this.variantId,
    required this.productName,
  });

  final String productId;
  final String variantId;
  final String productName;
}

/// Applying for EMI from the product page: the same seller-approved flow as
/// checkout — choose the plan, add identity and financial proof, send the
/// request to the seller, wait, then pay the down payment. Never StyleMint
/// identity verification.
class EmiApplyScreen extends ConsumerWidget {
  const EmiApplyScreen({required this.args, super.key});

  final EmiApplyArgs args;

  static const Key unavailableKey = Key('emi-apply-unavailable');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(planOptionsProvider(args.variantId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(title: const Text('Apply for EMI')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Message(
            text: 'Could not load the EMI plans.',
            onRetry: () => ref.invalidate(planOptionsProvider(args.variantId)),
          ),
          data: (options) {
            if (options.of(PlanKind.instalment) == null) {
              return const _Message(
                key: unavailableKey,
                text: 'EMI is not offered on this item right now.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: [
                CheckoutEmiPlans(
                  item: CartItem(
                    id: 'emi-${args.variantId}',
                    productId: args.productId,
                    productName: args.productName,
                    productImageUrl: '',
                    variantName: '',
                    quantity: 1,
                    unitPrice: options.price,
                    isInStock: true,
                    variantId: args.variantId,
                  ),
                  options: options,
                  onlyKind: PlanKind.instalment,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry, super.key});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: DesignTokens.smallRegular),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
