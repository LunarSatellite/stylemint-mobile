import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The way into the seller's running EMI plans, next to the requests card:
/// how many are running, overdue and due soon. Draws nothing while loading
/// or when the plans endpoint is not there yet (404) — the feature stays
/// out of sight until the backend has it.
class VendorEmiPlansCard extends ConsumerWidget {
  const VendorEmiPlansCard({super.key});

  static const Key cardKey = Key('vendor-emi-plans-card');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(vendorEmiPlansProvider).asData?.value;
    if (plans == null) return const SizedBox.shrink();
    final today = ref.watch(vendorEmiTodayProvider);
    final running = plans.where((p) => p.isRunning).length;
    final overdue = plans.where((p) => p.isOverdue).length;
    final dueSoon = plans.where((p) => p.isDueSoon(today)).length;
    final collected = plans.fold<double>(
      0,
      (sum, p) => sum + p.collected.amount,
    );
    final total = Money(
      amount: collected,
      currency: plans.isEmpty ? 'NPR' : plans.first.collected.currency,
    );
    final parts = <String>[
      '$running running',
      if (overdue > 0) '$overdue overdue',
      if (dueSoon > 0) '$dueSoon due soon',
    ];
    return InkWell(
      key: cardKey,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => context.push(RouteNames.vendorEmiPlans),
      child: PlanCard(
        borderColor: overdue > 0
            ? DesignTokens.colorError.withValues(alpha: 0.6)
            : null,
        child: Row(
          children: [
            Icon(
              Icons.payments_outlined,
              color: overdue > 0
                  ? DesignTokens.colorError
                  : DesignTokens.primaryGreen,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EMI plans · ${parts.join(' · ')}',
                    style: DesignTokens.mediumSemibold,
                  ),
                  Text(
                    plans.isEmpty
                        ? 'Collections from your buyers will show here'
                        : '${planMoney(total)} collected so far',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
