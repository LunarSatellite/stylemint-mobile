import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Where a running plan stands, in figures: paid so far, still to pay, the
/// next instalment and how many are left. Shared by the order screen's
/// "Payment plan" card and the plan's own screen.
class PlanProgressRows extends ConsumerWidget {
  const PlanProgressRows({required this.agreement, super.key});

  final CreditAgreement agreement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = agreement;
    final next = a.nextInstalment;
    final total = a.instalmentsPaid + a.instalmentsRemaining;
    final today = kathmanduToday(ref.watch(planClockProvider)());
    final phase = next == null ? null : instalmentPhase(next, today);
    return Column(
      children: [
        PlanRow(
          key: const Key('plan-paid-so-far'),
          label: 'Paid so far',
          value: planMoney(a.paidToDate),
        ),
        PlanRow(
          key: const Key('plan-remaining'),
          label: 'Remaining',
          value: planMoney(a.outstanding),
          emphasised: true,
        ),
        if (next != null && a.status != AgreementStatus.completed)
          PlanRow(
            key: const Key('plan-next-instalment'),
            label: phase == InstalmentPhase.overdue
                ? 'Overdue instalment'
                : 'Next instalment',
            value: next.dueDate == null
                ? planMoney(next.outstanding)
                : '${planMoney(next.outstanding)} · '
                      '${planDate(next.dueDate!)}',
          ),
        if (total > 0)
          PlanRow(
            key: const Key('plan-instalments-left'),
            label: 'Instalments left',
            value: '${a.instalmentsRemaining} of $total',
          ),
        if (a.lateFeesOutstanding.amount > 0)
          PlanRow(
            key: const Key('plan-late-fees'),
            label: 'Late fees owed',
            value: planMoney(a.lateFeesOutstanding),
          ),
      ],
    );
  }
}

/// A small red "Overdue" badge.
class PlanOverdueBadge extends StatelessWidget {
  const PlanOverdueBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s8,
      vertical: DesignTokens.s4,
    ),
    decoration: BoxDecoration(
      color: DesignTokens.colorError.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
    ),
    child: Text(
      'Overdue',
      style: DesignTokens.tiny.copyWith(
        color: DesignTokens.colorError,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// The order screen's "Payment plan" card, for an order bought on EMI (or
/// another plan). Draws nothing for an order paid outright, while the plan
/// loads, or when it cannot be read.
class OrderPaymentPlanCard extends ConsumerWidget {
  const OrderPaymentPlanCard({
    required this.orderId,
    this.creditAgreementId,
    super.key,
  });

  /// The order's id (GUID), which a plan names as its `orderId`.
  final String orderId;

  /// The plan the order names: null when the server did not say, empty when
  /// it said there is none.
  final String? creditAgreementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref
        .watch(
          orderPaymentPlanProvider((
            orderId: orderId,
            creditAgreementId: creditAgreementId,
          )),
        )
        .asData
        ?.value;
    if (plan == null) return const SizedBox.shrink();
    final figures =
        plan.isRepaying || plan.status == AgreementStatus.completed;
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: PlanCard(
        key: const Key('order-payment-plan-card'),
        borderColor: plan.hasOverdue
            ? DesignTokens.colorError.withValues(alpha: 0.6)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_repeat_rounded,
                  size: 20,
                  color: DesignTokens.primaryGreen,
                ),
                const SizedBox(width: DesignTokens.s8),
                const Expanded(
                  child: Text(
                    'Payment plan',
                    style: DesignTokens.mediumSemibold,
                  ),
                ),
                if (plan.hasOverdue)
                  const PlanOverdueBadge(key: Key('order-plan-overdue'))
                else
                  PlanStatusChip(status: plan.status),
              ],
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              '${plan.kind.label} · ${planMoney(plan.price)} over '
              '${plan.tenureMonths} months',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s8),
            if (figures)
              PlanProgressRows(agreement: plan)
            else if (plan.status == AgreementStatus.approved &&
                plan.downPaymentOnDelivery)
              Text(
                'Pay the rider ${planMoney(plan.downPayment)} in cash when it '
                'arrives. Your instalments start that day.',
                style: DesignTokens.smallRegular,
              ),
            const SizedBox(height: DesignTokens.s8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('order-plan-open'),
                onPressed: () => unawaited(
                  context.push(RouteNames.paymentPlanDetailPath(plan.id)),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: DesignTokens.primaryGreen,
                  padding: EdgeInsets.zero,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View plan and schedule'),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Instalment due in 2 days" / "Instalment overdue": shown on Home and My
/// Orders when a plan payment is due within three days or late. Tapping it
/// opens the plan; the cross hides this reminder for the session.
class PlanDueBanner extends ConsumerWidget {
  const PlanDueBanner({this.padding = EdgeInsets.zero, super.key});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(planDueAlertProvider);
    if (alert == null) return const SizedBox.shrink();
    final i = alert.instalment;
    final overdue = alert.isOverdue;
    final colour = overdue
        ? DesignTokens.colorError
        : DesignTokens.colorWarning;
    final title = switch (alert.phase) {
      InstalmentPhase.overdue => 'Instalment overdue',
      InstalmentPhase.dueToday when alert.daysUntil < 0 => 'Instalment due now',
      InstalmentPhase.dueToday => 'Instalment due today',
      _ when alert.daysUntil == 1 => 'Instalment due tomorrow',
      _ => 'Instalment due in ${alert.daysUntil} days',
    };
    final due = i.dueDate;
    final body = due == null
        ? 'Pay ${planMoney(i.outstanding)} on your payment plan.'
        : overdue
        ? 'Pay ${planMoney(i.outstanding)} (due ${planDate(due)}) to keep '
              'your plan in good standing.'
        : 'Pay ${planMoney(i.outstanding)} by ${planDate(due)}.';
    return Padding(
      padding: padding,
      child: Material(
        key: const Key('plan-due-banner'),
        color: colour.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          side: BorderSide(color: colour.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          onTap: () => unawaited(
            context.push(
              RouteNames.paymentPlanDetailPath(alert.agreement.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s12,
              DesignTokens.s8,
              DesignTokens.s4,
              DesignTokens.s8,
            ),
            child: Row(
              children: [
                Icon(
                  overdue ? Icons.error_rounded : Icons.schedule_rounded,
                  color: colour,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        key: const Key('plan-due-banner-title'),
                        style: DesignTokens.smallRegular.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        body,
                        style: DesignTokens.tiny,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('plan-due-banner-dismiss'),
                  tooltip: 'Hide',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    final notifier = ref.read(
                      dismissedPlanAlertsProvider.notifier,
                    );
                    notifier.state = {...notifier.state, alert.key};
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
