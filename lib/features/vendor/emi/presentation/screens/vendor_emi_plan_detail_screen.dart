import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/vendor_emi_plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One of the seller's EMI plans: the down payment and how it stands, what
/// was financed over how long, the full schedule with each instalment's
/// standing and late fee, what has been collected and what is left — and
/// the order it pays for. Where seller EMI notifications land.
class VendorEmiPlanDetailScreen extends ConsumerWidget {
  const VendorEmiPlanDetailScreen({required this.agreementId, super.key});

  final String agreementId;

  static const Key orderLinkKey = Key('vendor-emi-plan-order-link');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(vendorEmiPlanProvider(agreementId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('EMI plan'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(vendorEmiPlanProvider(agreementId));
            await ref.read(vendorEmiPlanProvider(agreementId).future);
          },
          // Not when(): while Riverpod retries a failed load the value is
          // loading-with-error, and a 404 must read as "being set up" at once.
          child: switch ((plan.value, plan.error)) {
            (final VendorEmiPlan p, _) => _PlanBody(
              plan: p,
              today: ref.watch(vendorEmiTodayProvider),
            ),
            (_, final Object error) => ListView(
              children: [
                if (vendorEmiPlansUnavailable(error))
                  const VendorEmiPlansSettingUp()
                else
                  SmErrorView(
                    message: error is EmiLoadException
                        ? creditFailureMessage(error.failure)
                        : 'We could not load this plan.',
                    onRetry: () =>
                        ref.invalidate(vendorEmiPlanProvider(agreementId)),
                  ),
              ],
            ),
            _ => const SmPageLoader(),
          },
        ),
      ),
    );
  }
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.plan, required this.today});

  final VendorEmiPlan plan;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final a = p.agreement;
    final muted = DesignTokens.tiny.copyWith(color: DesignTokens.textMuted);
    final subOrderId = p.vendorSubOrderId;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                p.productName.isEmpty ? 'EMI plan' : p.productName,
                style: DesignTokens.h3,
              ),
            ),
            if (p.isOverdue)
              const VendorEmiOverdueBadge()
            else
              PlanStatusChip(status: p.status),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        Text('Buyer: ${p.buyerDisplayName}', style: muted),
        if (p.orderNumber != null || subOrderId != null) ...[
          const SizedBox(height: DesignTokens.s8),
          InkWell(
            key: VendorEmiPlanDetailScreen.orderLinkKey,
            onTap: subOrderId == null
                ? null
                : () => context.push(
                    '/vendor/orders/${Uri.encodeComponent(subOrderId)}',
                  ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: DesignTokens.primaryGreen,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Text(
                      p.orderNumber == null
                          ? 'View order'
                          : 'Order ${p.orderNumber}',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ),
                  if (subOrderId != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: DesignTokens.primaryGreen,
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        PlanCard(
          child: Column(
            children: [
              PlanRow(label: 'Item price', value: planMoney(a.price)),
              PlanRow(
                key: const Key('vendor-emi-plan-down-payment'),
                label: 'Down payment',
                value:
                    '${planMoney(a.downPayment)} · '
                    '${p.downPaymentStatus.label}',
              ),
              PlanRow(label: 'Financed', value: planMoney(p.financed)),
              PlanRow(label: 'Tenure', value: '${a.tenureMonths} months'),
              PlanRow(
                label: 'Monthly instalment',
                value: planMoney(p.monthlyInstalment),
              ),
              const Divider(height: DesignTokens.s16),
              PlanRow(
                key: const Key('vendor-emi-plan-collected'),
                label: 'Collected so far',
                value: planMoney(p.collected),
              ),
              PlanRow(
                key: const Key('vendor-emi-plan-remaining'),
                label: 'Remaining',
                value: planMoney(p.remaining),
                emphasised: true,
              ),
              if (p.lateFeesOutstanding.amount > 0)
                PlanRow(
                  label: 'Late fees unpaid',
                  value: planMoney(p.lateFeesOutstanding),
                ),
              PlanRow(label: 'Next due', value: vendorNextDueText(p)),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        const Text('Schedule', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s8),
        PlanCard(
          child: a.instalments.isEmpty
              ? Text('No schedule yet.', style: muted)
              : Column(
                  children: [
                    for (final i in a.instalments)
                      _ScheduleRow(instalment: i, today: today),
                  ],
                ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'StyleMint collects every instalment online and passes it on to '
          'you. You carry what goes unpaid on this plan.',
          style: muted,
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.instalment, required this.today});

  final PlanInstalment instalment;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final i = instalment;
    final standing = instalmentStanding(i, today);
    final colour = vendorStandingColour(standing);
    final due = i.dueDate;
    final amount = switch (standing) {
      VendorInstalmentStanding.paid when i.paid.amount > 0 => i.paid,
      VendorInstalmentStanding.paid => i.scheduled,
      _ when i.outstanding.amount > 0 => i.outstanding,
      _ => i.scheduled,
    };
    return Padding(
      key: Key('vendor-emi-instalment-${i.number}'),
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  due == null
                      ? 'Payment ${i.number}'
                      : 'Payment ${i.number} · ${planDate(due)}',
                  style: DesignTokens.smallRegular,
                ),
                Text(
                  standing.label,
                  style: DesignTokens.tiny.copyWith(color: colour),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(planMoney(amount), style: DesignTokens.smallRegular),
              if (i.lateFeeDue.amount > 0)
                Text(
                  'incl. ${planMoney(i.lateFeeDue)} late fee',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
