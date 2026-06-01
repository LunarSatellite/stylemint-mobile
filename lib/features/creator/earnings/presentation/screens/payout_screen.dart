import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  final _amountController = TextEditingController();
  String? _selectedMethodId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestPayoutNotifierProvider);
    final earningsState = ref.watch(earningsNotifierProvider);
    final methods =
        earningsState.maybeWhen(
          loadSuccess: (_, __, m) => m,
          orElse: () => const <PayoutMethod>[],
        );

    ref.listen<RequestPayoutState>(requestPayoutNotifierProvider, (_, next) {
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
        actions: [
          IconButton(
            tooltip: 'Payment methods',
            icon: const Icon(Icons.account_balance_wallet_outlined,
                color: DesignTokens.textWhite),
            onPressed: () => context.push(RouteNames.creatorPaymentMethods),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                ref
                    .read(requestPayoutNotifierProvider.notifier)
                    .setAmount(amount);
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
                          .read(requestPayoutNotifierProvider.notifier)
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
            state.maybeWhen(
              submitting: () => const Center(
                child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
              ),
              orElse: () => SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  onPressed:
                      _selectedMethodId != null &&
                              _amountController.text.isNotEmpty
                          ? () => ref
                              .read(requestPayoutNotifierProvider.notifier)
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
