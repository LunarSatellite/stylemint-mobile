import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/plan_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// One payment plan: where it stands, what is owed, the schedule, and the
/// one thing to do next.
///
/// A payment is confirmed by the provider to the server, not to this app, so
/// after the buyer comes back from the provider's page the plan is read
/// again — on return to the app, and on pull to refresh.
class PaymentPlanDetailScreen extends ConsumerStatefulWidget {
  const PaymentPlanDetailScreen({
    required this.agreementId,
    this.args = const PlanDetailArgs(),
    super.key,
  });

  final String agreementId;
  final PlanDetailArgs args;

  @override
  ConsumerState<PaymentPlanDetailScreen> createState() =>
      _PaymentPlanDetailScreenState();
}

class _PaymentPlanDetailScreenState
    extends ConsumerState<PaymentPlanDetailScreen> {
  late final AppLifecycleListener _lifecycle;
  bool _paymentStarted = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    refreshPaymentPlans(ref, agreementId: widget.agreementId);
  }

  Future<void> _pay(
    CreditAgreement agreement,
    PaymentPurpose purpose,
    double amount,
  ) async {
    final started = await payOnPlan(
      context,
      agreement: agreement,
      purpose: purpose,
      amount: _inPlanCurrency(agreement, amount),
    );
    if (!mounted || !started) return;
    setState(() => _paymentStarted = true);
    _refresh();
  }

  /// An approved plan starts with the order that delivers its item, so its
  /// next step is checkout. Placing there starts the first payment, or the
  /// plan itself when nothing is due up front.
  Future<void> _checkOut(CreditAgreement agreement, String? productName) async {
    final placed = await context.push<PlanCheckoutPlaced>(
      RouteNames.paymentPlanCheckoutPath(agreement.id),
      extra: PlanDetailArgs(productName: productName),
    );
    if (!mounted || placed == null) return;
    setState(() => _paymentStarted = placed.redirectUrl != null);
    _refresh();
  }

  Future<void> _cancel(CreditAgreement agreement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cancel this plan?'),
        content: Text(
          agreement.orderId == null
              ? 'Nothing has been paid, so nothing is owed. You can apply '
                    'again later.'
              : 'Nothing has been paid, so nothing is owed. The order waiting '
                    'for this plan is cancelled too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: const Key('plan-cancel-confirm'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Cancel plan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(creditRepositoryProvider)
        .cancel(agreementId: agreement.id, idempotencyKey: const Uuid().v4());
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(creditFailureMessage(failure))),
      ),
      (_) => _refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(paymentPlanProvider(widget.agreementId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Payment plan'),
      ),
      body: SafeArea(
        child: plan.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => SmErrorView(
            message: error is EmiLoadException
                ? creditFailureMessage(error.failure)
                : 'We could not load this plan.',
            onRetry: _refresh,
          ),
          data: (agreement) => RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await ref.read(paymentPlanProvider(widget.agreementId).future);
            },
            child: _body(agreement),
          ),
        ),
      ),
    );
  }

  Widget _body(CreditAgreement a) {
    final name =
        widget.args.productName ??
        ref.watch(planProductNameProvider(a.productId)).asData?.value;
    final next = a.nextDue;
    final primary = a.primaryPayment;
    final dueNow = _dueNow(a);
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name ?? '${a.kind.label} plan',
                style: DesignTokens.h3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PlanStatusChip(status: a.status, overdue: a.hasOverdue),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          '${a.kind.label} · ${planMoney(a.price)} over '
          '${a.tenureMonths} months',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        _Headline(agreement: a, justApplied: widget.args.justApplied),
        if (_paymentStarted) ...[
          const SizedBox(height: DesignTokens.s12),
          const PlanCard(
            child: Text(
              'Payment started. This plan updates as soon as the payment '
              'provider confirms it — pull down to check.',
              key: Key('plan-payment-started'),
              style: DesignTokens.smallRegular,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        if (a.needsCheckout)
          _ActionButton(
            key: const Key('plan-checkout'),
            label: 'Continue to checkout',
            onPressed: () => unawaited(_checkOut(a, name)),
          ),
        if (primary != null)
          _ActionButton(
            key: const Key('plan-pay-primary'),
            label: primary == PaymentPurpose.activation
                ? 'Pay ${planMoney(a.downPayment)} to start'
                : 'Pay ${planMoney(_inPlanCurrency(a, dueNow))}',
            onPressed: () => _pay(
              a,
              primary,
              primary == PaymentPurpose.activation
                  ? a.downPayment.amount
                  : dueNow,
            ),
          ),
        if (a.status == AgreementStatus.active && a.payoffToday != null) ...[
          const SizedBox(height: DesignTokens.s8),
          _ActionButton(
            key: const Key('plan-pay-off'),
            label: 'Pay off ${planMoney(a.payoffToday!)} now',
            outlined: true,
            onPressed: () =>
                _pay(a, PaymentPurpose.payoff, a.payoffToday!.amount),
          ),
        ],
        if (a.canCancel) ...[
          const SizedBox(height: DesignTokens.s8),
          TextButton(
            key: const Key('plan-cancel'),
            onPressed: () => unawaited(_cancel(a)),
            child: const Text('Cancel this plan'),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        PlanCard(
          child: Column(
            children: [
              if (a.status == AgreementStatus.active ||
                  a.status == AgreementStatus.defaulted) ...[
                PlanRow(
                  key: const Key('plan-outstanding'),
                  label: 'Still to pay',
                  value: planMoney(a.outstanding),
                  emphasised: true,
                ),
                if (next != null && next.dueDate != null)
                  PlanRow(
                    label: 'Next payment',
                    value:
                        '${planMoney(next.outstanding)} · '
                        '${planDate(next.dueDate!)}',
                  ),
                const Divider(color: DesignTokens.borderDefault, height: 24),
              ],
              PlanRow(label: 'Price', value: planMoney(a.price)),
              PlanRow(
                label: a.kind == PlanKind.prepay ? 'Deposit' : 'Down payment',
                value: planMoney(a.downPayment),
              ),
              if (a.interest != PlanInterest.none)
                PlanRow(label: 'Interest', value: planMoney(a.totalInterest)),
              PlanRow(label: 'Total', value: planMoney(a.totalPayable)),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        const Text('Schedule', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s4),
        for (final i in a.instalments) PlanInstalmentTile(instalment: i),
        const SizedBox(height: DesignTokens.s16),
        Text(
          a.guarantor.statement,
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
      ],
    );
  }

  /// Everything already due; failing that, the next instalment — the same
  /// rule the server uses to set the amount, so the button shows what will
  /// be charged.
  double _dueNow(CreditAgreement a) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    var due = 0.0;
    for (final i in a.instalments) {
      final d = i.dueDate;
      if (i.status.isSettled || d == null) continue;
      if (!DateTime(d.year, d.month, d.day).isAfter(todayDate)) {
        due += i.outstanding.amount;
      }
    }
    return due > 0 ? due : (a.nextDue?.outstanding.amount ?? 0);
  }
}

Money _inPlanCurrency(CreditAgreement a, double amount) =>
    Money(amount: amount, currency: a.price.currency);

/// The state, said as what it means for the buyer.
class _Headline extends StatelessWidget {
  const _Headline({required this.agreement, required this.justApplied});

  final CreditAgreement agreement;
  final bool justApplied;

  @override
  Widget build(BuildContext context) {
    final a = agreement;
    final (icon, colour, title, body) = switch (a.status) {
      AgreementStatus.pendingApproval => (
        Icons.hourglass_top_rounded,
        DesignTokens.colorWarning,
        justApplied ? 'Sent to the seller' : 'Waiting for approval',
        'The seller reviews this request. Check back here for their decision.',
      ),
      AgreementStatus.approved => (
        Icons.verified_rounded,
        DesignTokens.primaryGreen,
        justApplied ? 'You are approved' : 'Approved',
        a.needsCheckout
            ? (a.approvalExpiresAt == null
                  ? 'Check out to choose where it goes and start the plan.'
                  : 'Check out by ${planInstant(a.approvalExpiresAt!)} to '
                        'choose where it goes and start the plan.')
            : (a.approvalExpiresAt == null
                  ? 'Your order is placed. Pay the first amount to start the '
                        'plan.'
                  : 'Your order is placed. Pay the first amount by '
                        '${planInstant(a.approvalExpiresAt!)} to start the '
                        'plan.'),
      ),
      AgreementStatus.active => (
        a.hasOverdue ? Icons.error_rounded : Icons.event_repeat_rounded,
        a.hasOverdue ? DesignTokens.colorError : DesignTokens.primaryGreen,
        a.hasOverdue ? 'A payment is overdue' : 'Your plan is running',
        a.hasOverdue
            ? 'Pay what is due to keep the plan in good standing'
                  '${a.daysPastDue > 0 ? ' (${a.daysPastDue} days late)' : ''}.'
            : a.goodsReleasedAt != null
            ? 'Your item is on its way. Pay each month as scheduled.'
            : 'Pay each month as scheduled. Your item is sent after the last '
                  'payment.',
      ),
      AgreementStatus.completed => (
        Icons.celebration_rounded,
        DesignTokens.primaryGreen,
        'Paid off',
        'Everything is paid. Thank you.',
      ),
      AgreementStatus.declined => (
        Icons.info_outline_rounded,
        DesignTokens.colorError,
        'Not approved',
        a.reasons.isEmpty
            ? 'This plan was not approved.'
            : a.reasons.map(reasonForBuyer).join('\n'),
      ),
      AgreementStatus.defaulted => (
        Icons.report_rounded,
        DesignTokens.colorError,
        'Unpaid',
        'This plan went unpaid for too long. Contact support to settle it.',
      ),
      AgreementStatus.cancelled => (
        Icons.block_rounded,
        DesignTokens.textMuted,
        'Cancelled',
        'This plan was cancelled before anything was paid.',
      ),
      AgreementStatus.expired => (
        Icons.history_rounded,
        DesignTokens.textMuted,
        'Expired',
        'The first payment was not made in time. You can apply again.',
      ),
    };
    final referredFor = a.status == AgreementStatus.pendingApproval
        ? a.reasons.where((r) => r != 'manual_review_required').toList()
        : const <String>[];
    return PlanCard(
      borderColor: colour.withValues(alpha: 0.6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colour, size: 32),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const Key('plan-headline'),
                  style: DesignTokens.h3,
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(body, style: DesignTokens.smallRegular),
                for (final r in referredFor)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.s4),
                    child: Text(
                      reasonForBuyer(r),
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
    );
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.primaryGreen,
                side: const BorderSide(color: DesignTokens.primaryGreen),
                shape: shape,
              ),
              child: Text(label),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.buttonPrimaryFill,
                foregroundColor: DesignTokens.buttonPrimaryText,
                shape: shape,
              ),
              child: Text(label),
            ),
    );
  }
}
