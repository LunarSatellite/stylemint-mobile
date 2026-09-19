import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Coverage as a bar plus the same fact in words.
///
/// `coverageRatio` is a 0–1 decimal on the wire. A shopper should never have
/// to multiply it by anything, so the percentage and the raw counts are both
/// spelled out, and the bar carries no meaning the text does not.
class MissionCoverageBar extends StatelessWidget {
  const MissionCoverageBar({required this.mission, super.key});

  final ShoppingMission mission;

  static const Key barKey = Key('mission-coverage');

  @override
  Widget build(BuildContext context) {
    final percent = mission.coveragePercent;
    final label =
        '${mission.itemsResolvedCount} of ${mission.itemCount} sorted '
        '· $percent%';
    return Semantics(
      key: barKey,
      label:
          'Coverage, $percent percent. ${mission.itemsResolvedCount} of '
          '${mission.itemCount} items sorted, '
          '${mission.itemsAlreadyOwnedCount} already owned, '
          '${mission.itemsAcquiredCount} acquired.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: mission.coverageRatio,
              minHeight: 6,
              backgroundColor: DesignTokens.bgAppBodyLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                DesignTokens.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              height: 1.4,
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// An exceeded budget, stated plainly and impossible to skim past.
///
/// The Mall's danger tone carries a glyph as well as a colour, and the
/// overshoot is given as a figure so no subtraction is needed.
class MissionOverBudgetBanner extends StatelessWidget {
  const MissionOverBudgetBanner({required this.mission, super.key});

  final ShoppingMission mission;

  static const Key bannerKey = Key('mission-over-budget');

  @override
  Widget build(BuildContext context) {
    final over = mission.overBudgetBy;
    if (over == null) return const SizedBox.shrink();
    final overText = formatMoney(
      Money(amount: over, currency: mission.currency),
      decimalDigits: 0,
    );
    final budgetText = formatMoney(
      Money(amount: mission.budgetAmount ?? 0, currency: mission.currency),
      decimalDigits: 0,
    );
    final totalText = formatMoney(
      Money(amount: mission.totalEstimatedCost, currency: mission.currency),
      decimalDigits: 0,
    );
    return Container(
      key: bannerKey,
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.colorError.withValues(alpha: 0.5),
        ),
      ),
      child: Semantics(
        label: 'Over budget by $overText. Budget $budgetText.',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 2, DesignTokens.s8, 0),
              child: Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: DesignTokens.colorError,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Over budget by $overText',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: DesignTokens.colorError,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'This plan comes to $totalText against a budget of '
                    '$budgetText.',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      height: 1.45,
                      color: DesignTokens.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The money block: estimated cost, the budget, and the headroom or the
/// overshoot — all as figures, never as a ratio to interpret.
class MissionMoneyBlock extends StatelessWidget {
  const MissionMoneyBlock({required this.mission, super.key});

  final ShoppingMission mission;

  static const Key ledgerKey = Key('mission-money');

  @override
  Widget build(BuildContext context) {
    final currency = mission.currency;
    String money(double amount) => formatMoney(
      Money(amount: amount, currency: currency),
      decimalDigits: 0,
    );

    final budget = mission.budgetAmount;
    final over = mission.overBudgetBy;
    return MallMoneyLedger(
      key: ledgerKey,
      semanticLabel: 'What this mission is estimated to cost',
      amounts: [
        MallAmount(
          label: 'Estimated cost',
          value: money(mission.totalEstimatedCost),
          kind: MallAmountKind.total,
        ),
        if (budget != null)
          MallAmount(label: 'Your budget', value: money(budget)),
        if (budget != null && over != null)
          MallAmount(
            label: 'Over budget by',
            value: money(over),
            kind: MallAmountKind.due,
          )
        else if (budget != null)
          MallAmount(
            label: 'Left to spend',
            value: money(
              (budget - mission.totalEstimatedCost).clamp(0, double.infinity),
            ),
          ),
      ],
    );
  }
}
