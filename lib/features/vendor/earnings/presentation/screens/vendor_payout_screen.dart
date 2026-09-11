import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/models/payout_destination_dto.dart';
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/payouts/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/notifiers/vendor_earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

const _vendorRole = PayeeKind.vendor;

class VendorPayoutScreen extends ConsumerStatefulWidget {
  const VendorPayoutScreen({super.key});

  @override
  ConsumerState<VendorPayoutScreen> createState() => _VendorPayoutScreenState();
}

class _VendorPayoutScreenState extends ConsumerState<VendorPayoutScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(vendorBalanceNotifierProvider);
    final destinationsState = ref.watch(
      payoutDestinationsControllerProvider(_vendorRole.value),
    );
    final payoutState = ref.watch(payoutNotifierProvider);

    ref.listen<PayoutState>(payoutNotifierProvider, (_, next) {
      next.maybeWhen(
        success: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payout requested!')),
          );
          context.pop();
        },
        failure: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to request payout.')),
        ),
        orElse: () {},
      );
    });

    final selectedDestinationId = payoutState.maybeWhen(
      editing: (_, id, __) => id,
      orElse: () => null,
    );
    final isSubmitting = payoutState.maybeWhen(
      submitting: () => true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Request Payout', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            tooltip: 'Payment methods',
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
              color: DesignTokens.textWhite,
            ),
            onPressed: () => context.push(RouteNames.vendorPaymentMethods),
          ),
        ],
      ),
      body: Padding(
        key: const Key('vendor-payout-body-inset'),
        padding: EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available balance
            Container(
              padding: const EdgeInsets.all(DesignTokens.s16),
              decoration: DesignTokens.cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Balance',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  balanceState.maybeWhen(
                    loadSuccess: (balance) => Text(
                      'Rs ${balance.available.amount.toStringAsFixed(2)}',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                    loadFailure: (_) => Text(
                      'Unavailable',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.colorError,
                      ),
                    ),
                    orElse: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s20),
            Text('Amount (NPR)', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: DesignTokens.titleLarge,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'Rs ',
                filled: true,
                fillColor: DesignTokens.bgAppBody,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.inputRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => ref
                  .read(payoutNotifierProvider.notifier)
                  .setAmount(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: DesignTokens.s24),
            Text('Payout Method', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s8),
            Expanded(
              child: destinationsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen,
                      ),
                    )
                  : destinationsState.errorMessage != null
                  ? SmErrorView(
                      message: destinationsState.errorMessage!,
                      onRetry: () => ref
                          .read(
                            payoutDestinationsControllerProvider(
                              _vendorRole.value,
                            ).notifier,
                          )
                          .load(),
                    )
                  : destinationsState.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No payout methods yet.',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.s12),
                          TextButton(
                            onPressed: () =>
                                context.push(RouteNames.vendorPaymentMethods),
                            child: const Text('Add a payout method'),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: DesignTokens.cardDecoration(),
                      child: Column(
                        children: destinationsState.items
                            .asMap()
                            .entries
                            .map(
                              (e) => _DestinationTile(
                                destination: e.value,
                                showDivider: e.key > 0,
                                selected: selectedDestinationId == e.value.id,
                                onSelected: () => ref
                                    .read(payoutNotifierProvider.notifier)
                                    .setSelectedDestination(
                                      e.value.id,
                                      e.value.kind.value,
                                    ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed:
                    !isSubmitting &&
                        selectedDestinationId != null &&
                        (double.tryParse(_amountController.text) ?? 0) > 0
                    ? () => ref.read(payoutNotifierProvider.notifier).submit()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  disabledBackgroundColor: DesignTokens.primaryGreen.withValues(
                    alpha: 0.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Confirm Payout',
                        style: DesignTokens.smallRegular.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
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

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.destination,
    required this.showDivider,
    required this.selected,
    required this.onSelected,
  });

  final PayoutDestinationDto destination;
  final bool showDivider;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final kind = destination.kind;
    return Column(
      children: [
        if (showDivider)
          const Divider(color: DesignTokens.borderDefault, height: 1),
        RadioListTile<String>(
          value: destination.id,
          groupValue: selected ? destination.id : null,
          onChanged: (_) => onSelected(),
          title: Row(
            children: [
              Text(destination.label, style: DesignTokens.oneLinerRegular),
              const SizedBox(width: DesignTokens.s8),
              Text(
                kind.label,
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              if (destination.isDefault) ...[
                const SizedBox(width: DesignTokens.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A1A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Default',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            destination.accountIdentifierMasked,
            style: DesignTokens.smallRegular,
          ),
          activeColor: DesignTokens.primaryGreen,
          tileColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s12,
            vertical: DesignTokens.s4,
          ),
        ),
      ],
    );
  }
}
