import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The vendor's way into their payment plans, leading with how many are
/// waiting for a decision. Draws nothing while it cannot tell — a count of
/// zero it never read would tell a vendor nobody is waiting.
class VendorPlanRequestsCard extends ConsumerWidget {
  const VendorPlanRequestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref
        .watch(vendorPaymentPlansProvider(AgreementStatus.pendingApproval))
        .asData
        ?.value;
    if (waiting == null) return const SizedBox.shrink();
    final count = waiting.length;
    return InkWell(
      key: const Key('vendor-plan-requests'),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => context.push(RouteNames.vendorPaymentPlans),
      child: PlanCard(
        borderColor: count > 0
            ? DesignTokens.colorWarning.withValues(alpha: 0.6)
            : null,
        child: Row(
          children: [
            Icon(
              count > 0
                  ? Icons.mark_email_unread_outlined
                  : Icons.event_repeat_rounded,
              color: count > 0
                  ? DesignTokens.colorWarning
                  : DesignTokens.textMuted,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 0
                        ? 'No requests waiting'
                        : count == 1
                        ? '1 request needs your decision'
                        : '$count requests need your decision',
                    style: DesignTokens.mediumSemibold,
                  ),
                  Text(
                    'See every payment plan on your products',
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
