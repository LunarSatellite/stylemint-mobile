import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "View return" on order detail, once a return exists: right after the buyer
/// submits one here (links to that return), or when the care plan already
/// shows an item with a return in progress or completed (links to My returns).
class OrderReturnLink extends ConsumerWidget {
  const OrderReturnLink({required this.order, super.key});

  final OrderDetail order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submittedId = order.submittedReturnId;
    final carePlan = ref
        .watch(orderCarePlanProvider(order.orderNumber))
        .asData
        ?.value;
    final hasReturn =
        carePlan?.items.any(
          (i) =>
              i.stage == CareStage.returnInProgress ||
              i.stage == CareStage.returned,
        ) ??
        false;
    if (submittedId == null && !hasReturn) return const SizedBox.shrink();

    final target = submittedId != null && submittedId.isNotEmpty
        ? RouteNames.returnDetail.replaceFirst(':returnId', submittedId)
        : RouteNames.myReturns;

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Material(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          onTap: () => context.push(target),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DesignTokens.warningFillDark,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                    ),
                    child: const Icon(
                      Icons.assignment_return_outlined,
                      size: 20,
                      color: DesignTokens.warningTextLight,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submittedId != null
                              ? 'Return submitted'
                              : 'Return on this order',
                          style: DesignTokens.mediumSemibold,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Follow the seller’s decision and refund.',
                          style: DesignTokens.smallRegular,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Text(
                    'View return',
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
