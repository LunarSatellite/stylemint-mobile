import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/notifiers/vendor_earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorPayoutScreen extends ConsumerStatefulWidget {
  const VendorPayoutScreen({super.key});

  @override
  ConsumerState<VendorPayoutScreen> createState() => _VendorPayoutScreenState();
}

class _VendorPayoutScreenState extends ConsumerState<VendorPayoutScreen> {
  final _amountController = TextEditingController();
  String? _selectedMethodId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payoutState = ref.watch(payoutNotifierProvider);
    final earningsState = ref.watch(vendorEarningsNotifierProvider);
    final availableBalance = earningsState.maybeWhen(
      loadSuccess: (s) => s.availableBalance,
      orElse: () => Money(amount: 0, currency: 'NPR'),
    );
    final methodsState = ref.watch(payoutMethodsNotifierProvider);
    final methods = methodsState.maybeWhen(
      loadSuccess: (m) => m,
      orElse: () => const <VendorPayoutMethod>[],
    );

    ref.listen<PayoutState>(payoutNotifierProvider, (_, next) {
      next.maybeWhen(
        success: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payout requested!')),
          );
          context.pop();
        },
        failure: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to request payout')),
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Request Payout', style: DesignTokens.titleMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Balance', style: DesignTokens.smallRegular),
                MoneyText(
                  availableBalance,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            Text('Amount (NPR)', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: DesignTokens.titleLarge,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'Rs ',
                filled: true,
                fillColor: DesignTokens.bgAppBody,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                final amount = double.tryParse(val) ?? 0;
                ref.read(payoutNotifierProvider.notifier).setAmount(amount);
              },
            ),
            const SizedBox(height: DesignTokens.s24),
            Text('Payout Method', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s8),
            if (methods.isEmpty)
              Text(
                'No payout methods configured',
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              )
            else
              ...methods.map(
                (method) => RadioListTile<String>(
                  value: method.id,
                  groupValue: _selectedMethodId,
                  onChanged: (val) {
                    setState(() => _selectedMethodId = val);
                    if (val != null) {
                      ref
                          .read(payoutNotifierProvider.notifier)
                          .setSelectedMethod(val);
                    }
                  },
                  title: Text(method.label, style: DesignTokens.oneLinerRegular),
                  subtitle: Text(
                    method.type.name,
                    style: DesignTokens.smallRegular,
                  ),
                  activeColor: DesignTokens.primaryGreen,
                  tileColor: DesignTokens.bgAppBody,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                  ),
                ),
              ),
            const Spacer(),
            payoutState.maybeWhen(
              submitting: () => const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
              orElse: () => SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  onPressed:
                      _selectedMethodId != null &&
                              _amountController.text.isNotEmpty
                          ? () => ref
                              .read(payoutNotifierProvider.notifier)
                              .submit()
                          : null,
                  style: DesignTokens.primaryButtonStyle(),
                  child: const Text('Confirm Payout'),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
          ],
        ),
      ),
    );
  }
}
