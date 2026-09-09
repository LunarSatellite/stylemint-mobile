import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/subscription_plan_dto.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Public billing-cycle enum so the screen and this sheet share one type.
enum BillingCycle { monthly, yearly }

/// Shows the "Do you want to proceed?" confirmation sheet for the upgrade
/// flow. Returns `true` when the user confirms, `false` (or null) on cancel.
Future<bool?> showUpgradeConfirmationSheet(
  BuildContext context, {
  required SubscriptionPlanDto plan,
  required BillingCycle cycle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (_) => _UpgradeSheet(plan: plan, cycle: cycle),
  );
}

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet({required this.plan, required this.cycle});

  final SubscriptionPlanDto plan;
  final BillingCycle cycle;

  // ── Display helpers ───────────────────────────────────────────────────────

  String get _billingLabel =>
      cycle == BillingCycle.monthly ? 'per month' : 'per year';

  String get _cycleLabel =>
      cycle == BillingCycle.monthly ? 'Billed Monthly' : 'Billed Yearly';

  String get _planTitle => '${plan.name ?? "Plan"} Plan';

  /// Monthly equivalent shown in brackets next to the annual figure when
  /// the user is on the yearly cycle, e.g. "(720 per month)".
  String get _yearlyEquivalent {
    final monthly = (plan.priceAmount / 12).round();
    return '($monthly per month)';
  }

  /// Pick the same medal asset the corresponding plan card uses, by tier.
  String get _badgeAsset {
    switch (plan.tier) {
      case 1:
        return 'assets/images/creatordash/copper_medal.png';
      case 2:
        return 'assets/images/creatordash/silver_medal.png';
      case 3:
      default:
        return 'assets/images/creatordash/gold_medal.png';
    }
  }

  List<String> _features() {
    final out = <String>[];
    if (plan.maxCampaigns == SubscriptionPlanDto.unlimited) {
      out.add('Unlimited Campaigns');
    } else {
      out.add('${plan.maxCampaigns} Campaigns');
    }
    if (plan.maxProducts == SubscriptionPlanDto.unlimited) {
      out.add('Unlimited Products');
    } else {
      out.add('${plan.maxProducts} Products');
    }
    if (plan.orderManagement) out.add('Order Management');
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;
    final features = _features();

    return Stack(
      children: [
        // Backdrop blur — sits behind the sheet card so the blurred view
        // of the underlying screen shows through any transparent margins.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: const SizedBox.shrink(),
          ),
        ),

        // Sheet card aligned to the bottom.
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s12,
                DesignTokens.s16,
                bottomPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DesignTokens.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s24),

                  // ── Plan header: medal + plan name + cycle chip.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DesignTokens.primaryGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Medal asset — same one the plan card uses.
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: DesignTokens.bgAppFoundation,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Image.asset(
                            _badgeAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.workspace_premium_rounded,
                              size: 24,
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _planTitle,
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: DesignTokens.textWhite,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _cycleLabel,
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 12,
                                  color: DesignTokens.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // ── Price summary.
                  Text(
                    cycle == BillingCycle.yearly
                        ? 'Rs ${plan.priceAmount.round()} $_billingLabel ${_yearlyEquivalent}'
                        : 'Rs ${plan.priceAmount.round()} $_billingLabel',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // ── Feature list.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Includes',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.textMuted,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s8),
                        ...features.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: DesignTokens.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: const TextStyle(
                                      fontFamily: DesignTokens.fontFamily,
                                      fontSize: 13,
                                      color: DesignTokens.textLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // ── Action buttons.
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryGreen,
                        foregroundColor: DesignTokens.baseBlack,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Proceed',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.baseBlack,
                            ),
                          ),
                          SizedBox(width: DesignTokens.s8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: DesignTokens.baseBlack,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.bgAppBodyLight,
                        foregroundColor: DesignTokens.textWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
