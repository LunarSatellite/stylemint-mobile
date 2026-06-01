import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/entities/payment_method.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/presentation/notifiers/payment_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  IconData _iconForType(PaymentType type) => switch (type) {
    PaymentType.card => Icons.credit_card_rounded,
    PaymentType.eSewa => Icons.account_balance_wallet_rounded,
    PaymentType.cod => Icons.money_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentNotifierProvider);
    final notifier = ref.read(paymentNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push<bool>('/payment/add-card');
          if (result == true) {
            notifier.load();
          }
        },
        backgroundColor: DesignTokens.primaryGreen,
        label: const Text('Add Card'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: state.when(
        initial: () => const _Loader(),
        loadInProgress: () => const _Loader(),
        loadSuccess: (methods) {
          if (methods.isEmpty) {
            return const Center(
              child: Text(
                'No payment methods yet',
                style: DesignTokens.bodyText,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.s16),
            itemCount: methods.length,
            itemBuilder: (_, i) => _PaymentMethodCard(
              method: methods[i],
              icon: _iconForType(methods[i].type),
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: DesignTokens.bgAppBody,
                    title: const Text('Remove Payment Method'),
                    content: const Text(
                      'Are you sure you want to remove this payment method?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => ctx.pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => ctx.pop(true),
                        child: const Text(
                          'Remove',
                          style: TextStyle(color: DesignTokens.colorError),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await notifier.delete(methods[i].id);
                }
              },
              onSetDefault: () => notifier.setDefault(methods[i].id),
            ),
          );
        },
        loadFailure:
            (failure) => SmErrorView(
              message: 'Failed to load payment methods.',
              onRetry: () => notifier.load(),
            ),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.icon,
    required this.onDelete,
    required this.onSetDefault,
  });

  final PaymentMethod method;
  final IconData icon;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(
        borderColor:
            method.isDefault ? DesignTokens.primaryGreen : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.primaryGreen, size: 28),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(method.label, style: DesignTokens.mediumSemibold),
                    if (method.isDefault) ...[
                      const SizedBox(width: DesignTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s8,
                          vertical: DesignTokens.s4,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.buttonRadius,
                          ),
                        ),
                        child: Text(
                          'Default',
                          style: DesignTokens.tiny.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (method.lastFour != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '•••• ${method.lastFour}',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
                if (method.expiryDate != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    'Expires ${method.expiryDate}',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: DesignTokens.bgAppBodyLight,
            onSelected: (v) {
              switch (v) {
                case 'delete':
                  onDelete();
                case 'default':
                  onSetDefault();
              }
            },
            itemBuilder: (ctx) => [
              if (!method.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Set as Default'),
                ),
              const PopupMenuItem(value: 'delete', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}
