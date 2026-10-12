import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// What the review needs: the signed quote, and enough about the item to
/// say what it is for.
class PlanReviewArgs {
  const PlanReviewArgs({
    required this.quote,
    required this.productName,
    required this.productId,
    required this.variantId,
  });

  final CreditQuote quote;
  final String productName;
  final String productId;
  final String variantId;
}

/// The plan as the server priced and signed it, for the buyer to accept.
///
/// Every figure here is the quote's; nothing is recomputed on the device.
/// Accepting sends the quote's token back unchanged and the server decides
/// there and then — approved, sent to the seller, or not approved, with its
/// reasons. The quote expires, and the screen says when.
class PlanReviewScreen extends ConsumerStatefulWidget {
  const PlanReviewScreen({required this.args, super.key});

  final PlanReviewArgs args;

  @override
  ConsumerState<PlanReviewScreen> createState() => _PlanReviewScreenState();
}

class _PlanReviewScreenState extends ConsumerState<PlanReviewScreen> {
  bool _agreed = false;
  bool _applying = false;
  EmiFailure? _failure;
  Timer? _ticker;

  /// One key for this acceptance. Tapping again after a timeout is the same
  /// application, not a second one.
  final String _key = const Uuid().v4();

  CreditQuote get _quote => widget.args.quote;

  @override
  void initState() {
    super.initState();
    // Re-render once the quote lapses, so Apply turns off at the right time.
    final remaining = _quote.expiresAt.difference(DateTime.now());
    if (!remaining.isNegative) {
      _ticker = Timer(remaining, () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() {
      _applying = true;
      _failure = null;
    });
    final result = await ref
        .read(creditRepositoryProvider)
        .apply(quoteToken: _quote.token, idempotencyKey: _key);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _applying = false;
        _failure = failure;
      }),
      (agreement) {
        refreshPaymentPlans(ref);
        context.pushReplacement(
          RouteNames.paymentPlanDetailPath(agreement.id),
          extra: PlanDetailArgs(
            productName: widget.args.productName,
            justApplied: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _quote;
    final expired = q.isExpiredAt(DateTime.now());
    final hasInterest = q.interest != PlanInterest.none;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text('Review your ${q.kind.label} plan'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s20),
          children: [
            Text(widget.args.productName, style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s4),
            Text(
              q.kind.explainer,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            PlanCard(
              child: Column(
                children: [
                  PlanRow(label: 'Price', value: planMoney(q.price)),
                  PlanRow(
                    label: switch (q.kind) {
                      PlanKind.prepay => 'Deposit (${q.downPaymentPercent}%)',
                      PlanKind.payLater =>
                        'First payment (${q.downPaymentPercent}%)',
                      PlanKind.instalment =>
                        'Down payment (${q.downPaymentPercent}%)',
                    },
                    value: planMoney(q.downPayment),
                  ),
                  PlanRow(
                    key: const Key('review-monthly'),
                    label: 'Then ${q.tenureMonths} monthly payments',
                    value: q.schedule.isEmpty
                        ? planMoney(q.financed)
                        : planMoney(q.schedule.first.amount),
                    emphasised: true,
                  ),
                  if (hasInterest)
                    PlanRow(
                      label: 'Interest',
                      value: planMoney(q.totalInterest),
                    ),
                  const Divider(color: DesignTokens.borderDefault, height: 24),
                  PlanRow(
                    key: const Key('review-total'),
                    label: 'Total you pay',
                    value: planMoney(q.totalPayable),
                  ),
                  PlanRow(
                    label: 'APR',
                    value: '${q.aprPercent.toStringAsFixed(2)}%',
                  ),
                  // Disclosed before accepting, as the signed quote states it.
                  // Prepay extends no credit and never carries one.
                  if (q.kind != PlanKind.prepay)
                    PlanRow(
                      key: const Key('review-late-fee'),
                      label: 'Late fee',
                      value: q.chargesLateFee
                          ? '${planMoney(q.lateFee!)} if more than '
                                '${q.lateFeeGraceDays} days late'
                          : 'None',
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            const Text('Payment schedule', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            PlanRow(
              label: 'To start the plan',
              value: planMoney(q.downPayment),
            ),
            for (final line in q.schedule)
              PlanRow(
                label: line.monthsAfterStart == 1
                    ? '1 month after it starts'
                    : '${line.monthsAfterStart} months after it starts',
                value: planMoney(line.amount),
              ),
            const SizedBox(height: DesignTokens.s16),
            PlanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Fact(
                    icon: Icons.local_shipping_outlined,
                    text: q.goodsBeforePaidInFull
                        ? 'Your item is sent once the plan starts.'
                        : 'Your item is sent after the last payment.',
                  ),
                  _Fact(
                    icon: Icons.handshake_outlined,
                    text: q.guarantor.statement,
                  ),
                  if (!hasInterest)
                    const _Fact(
                      icon: Icons.percent_rounded,
                      text: 'No interest: you pay the price and nothing more.',
                    ),
                  const _Fact(
                    icon: Icons.credit_card_outlined,
                    text:
                        'Payments are made online, by card, eSewa or '
                        'PayPal, from Payment plans in your profile.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            CheckboxListTile(
              key: const Key('review-agree'),
              value: _agreed,
              onChanged: expired || _applying
                  ? null
                  : (value) => setState(() => _agreed = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'I agree to pay ${planMoney(q.totalPayable)} on this '
                'schedule. A missed payment can add a late fee and may affect '
                'whether I can use payment plans again.',
                style: DesignTokens.smallRegular,
              ),
            ),
            if (_failure != null)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: Text(
                  creditFailureMessage(_failure!),
                  key: const Key('review-error'),
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ),
            Text(
              expired
                  ? 'This offer has expired. Go back and ask for a new one.'
                  : 'This offer is held until ${planInstant(q.expiresAt)}.',
              key: const Key('review-expiry'),
              style: DesignTokens.tiny.copyWith(
                color: expired
                    ? DesignTokens.colorError
                    : DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: FilledButton(
                key: const Key('review-apply'),
                onPressed: !_agreed || expired || _applying
                    ? null
                    : () => unawaited(_apply()),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.buttonPrimaryFill,
                  foregroundColor: DesignTokens.buttonPrimaryText,
                  disabledBackgroundColor: DesignTokens.buttonGrayFill,
                  disabledForegroundColor: DesignTokens.buttonGrayText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.buttonRadius,
                    ),
                  ),
                ),
                child: Text(_applying ? 'Applying…' : 'Apply for this plan'),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Nothing is charged when you apply. If you are approved, you '
              'pay the first amount to start the plan.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s8),
        Expanded(child: Text(text, style: DesignTokens.smallRegular)),
      ],
    ),
  );
}

/// What the detail screen is told when it is opened from the review.
class PlanDetailArgs {
  const PlanDetailArgs({this.productName, this.justApplied = false});

  final String? productName;

  /// Opened straight after applying: the decision is the headline.
  final bool justApplied;
}
