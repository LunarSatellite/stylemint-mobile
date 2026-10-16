import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/vendor_emi_plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// On the seller's order Payment card: how far the buyer's EMI has got —
/// collected, remaining, next due — and the way to the plan. Draws nothing
/// while loading, or when the plan cannot be read (not deployed yet, or not
/// a seller-funded EMI), so the card never shows a figure it does not have.
class VendorOrderPlanProgress extends ConsumerWidget {
  const VendorOrderPlanProgress({required this.agreementId, super.key});

  final String agreementId;

  static const Key sectionKey = Key('vendor-order-plan-progress');
  static const Key linkKey = Key('vendor-order-plan-link');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(vendorEmiPlanProvider(agreementId)).asData?.value;
    if (plan == null) return const SizedBox.shrink();
    Widget row(String label, String value, {Color? colour}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                color: DesignTokens.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colour ?? DesignTokens.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Collected so far', planMoney(plan.collected)),
        row('Remaining', planMoney(plan.remaining)),
        row(
          'Next due',
          vendorNextDueText(plan),
          colour: plan.isOverdue ? DesignTokens.colorError : null,
        ),
        if (plan.isOverdue)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: VendorEmiOverdueBadge(),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: linkKey,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: DesignTokens.primaryGreen,
            ),
            onPressed: () =>
                context.push(RouteNames.vendorEmiPlanDetailPath(agreementId)),
            icon: const Icon(Icons.event_repeat_rounded, size: 18),
            label: const Text('View EMI plan and schedule'),
          ),
        ),
      ],
    );
  }
}
