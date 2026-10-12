import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The buyer's payment plans, with what needs doing first, and their
/// standing: band, limit, and what moved the score.
class PaymentPlansScreen extends ConsumerWidget {
  const PaymentPlansScreen({super.key});

  /// Needing the buyer first, then running, then waiting, then finished.
  static int _rank(CreditAgreement a) {
    if (a.status == AgreementStatus.approved || a.hasOverdue) return 0;
    if (a.status == AgreementStatus.active) return 1;
    if (a.status == AgreementStatus.pendingApproval) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(myPaymentPlansProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Payment plans'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            refreshPaymentPlans(ref);
            await ref.read(myPaymentPlansProvider.future);
          },
          child: plans.when(
            loading: () => const SmPageLoader(),
            error: (error, _) => ListView(
              children: [
                SmErrorView(
                  message: error is EmiLoadException
                      ? creditFailureMessage(error.failure)
                      : 'We could not load your payment plans.',
                  onRetry: () => refreshPaymentPlans(ref),
                ),
              ],
            ),
            data: (agreements) {
              final sorted = [...agreements]
                ..sort((a, b) {
                  final byRank = _rank(a).compareTo(_rank(b));
                  if (byRank != 0) return byRank;
                  final at = a.appliedAt ?? DateTime(0);
                  final bt = b.appliedAt ?? DateTime(0);
                  return bt.compareTo(at);
                });
              return ListView(
                padding: const EdgeInsets.all(DesignTokens.s20),
                children: [
                  const _ProfileCard(),
                  const SizedBox(height: DesignTokens.s20),
                  if (sorted.isEmpty)
                    const SmEmptyState(
                      title: 'No payment plans yet',
                      message:
                          'Look for "Pay over time" under a product\'s price '
                          'to pay for it in instalments.',
                      icon: Icons.event_repeat_rounded,
                    )
                  else
                    for (final a in sorted) ...[
                      _PlanTile(agreement: a),
                      const SizedBox(height: DesignTokens.s12),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.agreement});

  final CreditAgreement agreement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = agreement;
    final name = ref.watch(planProductNameProvider(a.productId)).asData?.value;
    final next = a.nextDue;
    final subtitle = switch (a.status) {
      AgreementStatus.active when next?.dueDate != null =>
        'Next ${planMoney(next!.outstanding)} on ${planDate(next.dueDate!)}',
      AgreementStatus.approved when a.needsCheckout => 'Check out to start',
      AgreementStatus.approved => 'Pay ${planMoney(a.downPayment)} to start',
      AgreementStatus.reversed =>
        a.reversedForReturn
            ? 'Refunded — item returned'
            : 'Refunded — order cancelled',
      AgreementStatus.declined when a.reasons.isNotEmpty => reasonForBuyer(
        a.reasons.first,
      ),
      _ => '${planMoney(a.price)} over ${a.tenureMonths} months',
    };
    return InkWell(
      key: Key('plan-tile-${a.id}'),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => context.push(RouteNames.paymentPlanDetailPath(a.id)),
      child: PlanCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? '${a.kind.label} plan',
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '${a.kind.label} · $subtitle',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            PlanStatusChip(status: a.status, overdue: a.hasOverdue),
          ],
        ),
      ),
    );
  }
}

/// The buyer's standing. Hidden when it cannot be read, rather than shown
/// as zeros that would read as "no credit".
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(creditProfileProvider).asData?.value;
    if (profile == null) return const SizedBox.shrink();
    final band = profile.band;
    return PlanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: const Text(
                  'Your standing',
                  style: DesignTokens.mediumSemibold,
                ),
              ),
              if (band != null)
                Container(
                  key: const Key('plan-band'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s8,
                    vertical: DesignTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                  child: Text(
                    'Band ${band.letter}',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          PlanRow(
            key: const Key('plan-available'),
            label: 'Available for plans StyleMint guarantees',
            value: planMoney(profile.availableCredit),
            emphasised: true,
          ),
          PlanRow(label: 'Limit', value: planMoney(profile.creditLimit)),
          PlanRow(
            label: 'Still owed on your plans',
            value: planMoney(profile.outstandingPrincipal),
          ),
          if (!profile.identityVerified) ...[
            const SizedBox(height: DesignTokens.s8),
            InkWell(
              onTap: () => context.push(RouteNames.customerKyc),
              child: Text(
                'Verify your identity to use payment plans →',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (profile.factors.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: const Key('plan-factors'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text(
                  'What shapes your standing',
                  style: DesignTokens.smallRegular,
                ),
                children: [
                  for (final f in profile.factors)
                    PlanRow(
                      label: scoreFactorLabel(f.code),
                      value: f.points > 0 ? '+${f.points}' : '${f.points}',
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.s8),
                    child: Text(
                      'Completed orders, time with StyleMint and paying on '
                      'time all help. Sellers make their own decision on EMI.',
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
