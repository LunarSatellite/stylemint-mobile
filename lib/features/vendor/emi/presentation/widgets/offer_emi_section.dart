import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/emi_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/notifiers/vendor_emi_terms_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

String _money(Money money) => formatMoney(money, decimalDigits: 0);

/// "Offer EMI" for one listing: the switch, the minimum down payment
/// (20–90 % in 5 % steps), the tenures, a live sample of what a buyer would
/// pay, and a save of its own — separate from the product form's, because
/// these are separate terms on a separate endpoint.
///
/// When the endpoint is not there yet (404 — the app ships before the
/// backend) the section draws nothing if [hideWhenUnavailable], or a short
/// "not available yet" note otherwise.
class OfferEmiSection extends ConsumerWidget {
  const OfferEmiSection({
    required this.productId,
    this.hideWhenUnavailable = true,
    super.key,
  });

  final String productId;
  final bool hideWhenUnavailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = vendorEmiTermsNotifierProvider(productId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    if (state.isUnavailable) {
      return hideWhenUnavailable
          ? const SizedBox.shrink()
          : const _Card(
              child: Text(
                'EMI is not available yet. You will be able to offer it on '
                'this product soon.',
                style: DesignTokens.smallRegular,
              ),
            );
    }
    if (state.loading && state.saved == null) {
      return const _Card(child: LinearProgressIndicator());
    }
    final saved = state.saved;
    final failure = state.loadFailure;
    if (saved == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              failure == null
                  ? 'EMI terms could not be loaded.'
                  : emiCommonMessage(failure) ??
                        serverMessageOr(
                          failure,
                          'EMI terms could not be loaded.',
                        ),
              style: DesignTokens.smallRegular,
            ),
            TextButton(
              onPressed: notifier.load,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final busy = state.saving;
    final steps =
        (emiMaxDownPaymentPercent - emiMinDownPaymentPercent) ~/
        emiDownPaymentStep;
    final effective = state.previewEffectiveMin;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            key: const Key('offer-emi-switch'),
            contentPadding: EdgeInsets.zero,
            value: state.enabled,
            onChanged: busy ? null : notifier.setEnabled,
            title: const Text('Offer EMI', style: DesignTokens.mediumSemibold),
            subtitle: Text(
              'Buyers pay a down payment, get the product, and pay you the '
              'rest monthly — interest-free.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ),
          if (saved.eligibleVariantCount <= 0)
            _Note(
              icon: Icons.info_outline_rounded,
              text:
                  'No variant is priced at '
                  '${_money(saved.minimumPrice ?? const Money(amount: emiMinimumPriceAmount, currency: 'NPR'))}'
                  ' or more, so EMI cannot be switched on yet.',
            ),
          if (state.enabled) ...[
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Minimum down payment',
                    style: DesignTokens.smallRegular,
                  ),
                ),
                Text(
                  '${state.minDownPaymentPercent}%',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ],
            ),
            Slider(
              key: const Key('offer-emi-min-down'),
              value: state.minDownPaymentPercent.toDouble(),
              min: emiMinDownPaymentPercent.toDouble(),
              max: emiMaxDownPaymentPercent.toDouble(),
              divisions: steps,
              label: '${state.minDownPaymentPercent}%',
              activeColor: DesignTokens.primaryGreen,
              onChanged: busy
                  ? null
                  : (value) => notifier.setMinDownPaymentPercent(value.round()),
            ),
            if (effective > state.minDownPaymentPercent)
              _Note(
                icon: Icons.trending_up_rounded,
                text:
                    'Buyers will pay at least $effective% down. The down '
                    'payment must cover StyleMint’s commission on this '
                    'product, which raises your '
                    '${state.minDownPaymentPercent}% minimum.',
              ),
            const SizedBox(height: DesignTokens.s12),
            const Text('Months', style: DesignTokens.smallRegular),
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                for (final months in emiAllowedTenures)
                  FilterChip(
                    key: Key('offer-emi-tenure-$months'),
                    label: Text('$months months'),
                    selected: state.tenures.contains(months),
                    selectedColor: DesignTokens.chipsSelectedFill,
                    onSelected: busy
                        ? null
                        : (_) => notifier.toggleTenure(months),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            _SampleQuote(state: state, saved: saved, effectiveMin: effective),
            const SizedBox(height: DesignTokens.s12),
            const _Note(
              icon: Icons.how_to_reg_outlined,
              text:
                  'Each EMI order needs your approval. StyleMint verifies the '
                  'buyer, collects the instalments and handles recovery.',
            ),
          ],
          if (state.error case final String error) ...[
            const SizedBox(height: DesignTokens.s12),
            Text(
              error,
              key: const Key('offer-emi-error'),
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              if (state.justSaved && !state.isDirty)
                Expanded(
                  child: Text(
                    'Saved',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                )
              else
                const Spacer(),
              FilledButton(
                key: const Key('offer-emi-save'),
                onPressed: busy || !state.isDirty ? null : notifier.save,
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.buttonPrimaryFill,
                  foregroundColor: DesignTokens.buttonPrimaryText,
                ),
                child: Text(busy ? 'Saving…' : 'Save EMI terms'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What a buyer would pay for the cheapest eligible variant at the minimum
/// down payment over the longest tenure.
///
/// While the draft matches what is saved, this is the server's
/// `sampleQuote`. While it is being edited, the same figures are worked out
/// on the device from the sample's price, with the contract's rounding, and
/// labelled as a preview.
class _SampleQuote extends StatelessWidget {
  const _SampleQuote({
    required this.state,
    required this.saved,
    required this.effectiveMin,
  });

  final VendorEmiTermsState state;
  final VendorEmiTerms saved;
  final int effectiveMin;

  @override
  Widget build(BuildContext context) {
    final sample = saved.sampleQuote;
    if (sample == null) {
      return const _Note(
        icon: Icons.calculate_outlined,
        text: 'Save to see what a buyer would pay each month.',
      );
    }
    if (state.tenures.isEmpty) return const SizedBox.shrink();
    final longest = state.tenures.reduce((a, b) => a > b ? a : b);
    final fromServer =
        !state.isDirty && saved.enabled && sample.tenureMonths > 0;
    final plan = EmiPlan.compute(
      price: sample.price,
      downPaymentPercent: effectiveMin,
      tenureMonths: longest,
    );
    final down = fromServer ? sample.downPayment : plan.downPayment;
    final monthly = fromServer
        ? sample.monthlyInstallment
        : plan.monthlyInstallment;
    final months = fromServer ? sample.tenureMonths : longest;
    final percent = fromServer ? sample.downPaymentPercent : effectiveMin;

    return Container(
      key: const Key('offer-emi-sample'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fromServer ? 'Sample quote' : 'Preview — save to confirm',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'On ${_money(sample.price)}: ${_money(down)} down ($percent%), '
            'then ${_money(monthly)}/month for $months months.',
            style: DesignTokens.smallRegular,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      border: Border.all(color: DesignTokens.borderDefault),
    ),
    child: child,
  );
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: DesignTokens.s8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            text,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ),
      ],
    ),
  );
}
