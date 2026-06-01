import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PaymentMethodScreen extends ConsumerWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(checkoutRepositoryProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Payment Method', style: DesignTokens.titleLarge),
        centerTitle: false,
      ),
      body: FutureBuilder<List<PaymentMethod>>(
        future: repository.getPaymentMethods().then(
              (either) => either.fold(
                (failure) => throw Exception(failure),
                (methods) => methods,
              ),
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load payment methods',
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  TextButton(
                    onPressed: () {
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final methods = snapshot.data ?? <PaymentMethod>[];

          return ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              ...methods.map((method) => _PaymentMethodTile(method: method)),
              const SizedBox(height: DesignTokens.s24),
              const _SectionHeader(title: 'Add New'),
              const SizedBox(height: DesignTokens.s8),
              _AddPaymentOption(
                icon: Icons.credit_card_rounded,
                label: 'Add New Card',
                onTap: () {
                  // Navigate to add card flow
                },
              ),
              const SizedBox(height: DesignTokens.s8),
              _AddPaymentOption(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Add eSewa',
                onTap: () {
                  // Navigate to eSewa setup
                },
              ),
              const SizedBox(height: DesignTokens.s8),
              _AddPaymentOption(
                icon: Icons.money_rounded,
                label: 'Cash on Delivery',
                onTap: () {
                  // Set COD as payment
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Text(title, style: DesignTokens.sectionInnerTitle),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({required this.method});

  final PaymentMethod method;

  IconData get _icon {
    switch (method.type) {
      case PaymentMethodType.card:
        return Icons.credit_card_rounded;
      case PaymentMethodType.eSewa:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethodType.cod:
        return Icons.money_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(method),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: DesignTokens.cardDecoration(
            borderColor: method.isDefault
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
          ),
          child: Row(
            children: [
              Radio<PaymentMethodType>(
                value: method.type,
                groupValue: method.type,
                onChanged: (_) => Navigator.of(context).pop(method),
                activeColor: DesignTokens.primaryGreen,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return DesignTokens.primaryGreen;
                  }
                  return DesignTokens.iconLight;
                }),
              ),
              const SizedBox(width: DesignTokens.s12),
              Icon(_icon, color: DesignTokens.primaryGreen, size: 24),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: DesignTokens.oneLinerSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    if (method.lastFour != null)
                      Text(
                        '•••• ${method.lastFour}',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (method.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreenLight,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                  child: Text(
                    'Default',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.primaryGreen,
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

class _AddPaymentOption extends StatelessWidget {
  const _AddPaymentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(
          borderColor: DesignTokens.borderDefault,
        ),
        child: Row(
          children: [
            Icon(icon, color: DesignTokens.iconLight, size: 24),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                label,
                style: DesignTokens.oneLinerSemibold.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
            const Icon(
              Icons.add_circle_outline_rounded,
              color: DesignTokens.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}
