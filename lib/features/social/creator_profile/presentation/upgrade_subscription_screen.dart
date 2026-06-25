import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum _BillingCycle { monthly, yearly }

class UpgradeSubscriptionScreen extends StatefulWidget {
  const UpgradeSubscriptionScreen({super.key});

  @override
  State<UpgradeSubscriptionScreen> createState() =>
      _UpgradeSubscriptionScreenState();
}

class _UpgradeSubscriptionScreenState
    extends State<UpgradeSubscriptionScreen> {
  _BillingCycle _billing = _BillingCycle.monthly;
  int _selectedPlan = 1; // 0 = Basic, 1 = Pro, 2 = Enterprise

  static const _plans = [
    _PlanData(
      name: 'Basic Plan',
      badge: 'assets/images/creatordash/copper_medal.png',
      monthlyPrice: 600,
      yearlyPrice: 500,
      features: ['10 Campaigns', '10 Products'],
      tag: null,
    ),
    _PlanData(
      name: 'Pro Plan',
      badge: 'assets/images/creatordash/silver_medal.png',
      monthlyPrice: 900,
      yearlyPrice: 750,
      features: ['1000 Campaigns', 'Order Management', '1000 Products'],
      tag: 'Most Popular',
    ),
    _PlanData(
      name: 'Enterprise Plan',
      badge: 'assets/images/creatordash/gold_medal.png',
      monthlyPrice: 1600,
      yearlyPrice: 1300,
      features: [
        'Unlimited Campaigns',
        'Order Management',
        'Unlimited Products',
      ],
      tag: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Upgrade Subscription Plan',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s24,
            ),
            child: _BillingToggle(
              value: _billing,
              onChanged: (v) => setState(() => _billing = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16),
              itemCount: _plans.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.s16),
              itemBuilder: (context, i) => _PlanCard(
                plan: _plans[i],
                isSelected: _selectedPlan == i,
                isYearly: _billing == _BillingCycle.yearly,
                onTap: () => setState(() => _selectedPlan = i),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              bottomPadding,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.textWhite,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: DesignTokens.s8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Billing toggle ───────────────────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.value, required this.onChanged});

  final _BillingCycle value;
  final ValueChanged<_BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleTab(
            label: 'Billed Monthly',
            isActive: value == _BillingCycle.monthly,
            onTap: () => onChanged(_BillingCycle.monthly),
          ),
          _ToggleTab(
            label: 'Billed Yearly',
            isActive: value == _BillingCycle.yearly,
            onTap: () => onChanged(_BillingCycle.yearly),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isActive
                ? DesignTokens.primaryGreen
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? DesignTokens.textWhite
                  : DesignTokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Plan card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isYearly,
    required this.onTap,
  });

  final _PlanData plan;
  final bool isSelected;
  final bool isYearly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = isYearly ? plan.yearlyPrice : plan.monthlyPrice;
    final hasMostPopularTag = plan.tag != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(
            color: isSelected
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header label
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? DesignTokens.primaryGreen.withValues(alpha: 0.12)
                    : DesignTokens.bgAppBodyLight,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.cardRadius - 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasMostPopularTag
                        ? '${plan.name} (${plan.tag})'
                        : plan.name,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textLight,
                    ),
                  ),
                ],
              ),
            ),
            // Content row
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Row(
                children: [
                  // Badge icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: DesignTokens.bgAppBodyLight,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      plan.badge,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.military_tech_rounded,
                        color: DesignTokens.textMuted,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  // Price + features
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Rs ${_formatPrice(price)}',
                              style: const TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: DesignTokens.textWhite,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isYearly
                                  ? 'per month, billed yearly'
                                  : 'per month',
                              style: const TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 11,
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.s8),
                        ...plan.features.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_rounded,
                                    size: 14,
                                    color: DesignTokens.primaryGreen),
                                const SizedBox(width: 6),
                                Text(
                                  f,
                                  style: const TextStyle(
                                    fontFamily: DesignTokens.fontFamily,
                                    fontSize: 12,
                                    color: DesignTokens.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  // Radio
                  _RadioDot(isSelected: isSelected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k';
    }
    return price.toString();
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? DesignTokens.primaryGreen
              : DesignTokens.textMuted,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.primaryGreen,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Plan data ────────────────────────────────────────────────────────────────

class _PlanData {
  const _PlanData({
    required this.name,
    required this.badge,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.tag,
  });

  final String name;
  final String badge;
  final int monthlyPrice;
  final int yearlyPrice;
  final List<String> features;
  final String? tag;
}
