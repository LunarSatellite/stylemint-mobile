
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/subscription_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/providers/subscription_providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/widgets/upgrade_confirmation_sheet.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';



class UpgradeSubscriptionScreen extends ConsumerStatefulWidget {
  const UpgradeSubscriptionScreen({super.key});

  @override
  ConsumerState<UpgradeSubscriptionScreen> createState() =>
      _UpgradeSubscriptionScreenState();
}

class _UpgradeSubscriptionScreenState
    extends ConsumerState<UpgradeSubscriptionScreen> {
  BillingCycle _billing = BillingCycle.monthly;

  /// Tier currently highlighted for the upgrade. `null` until plans load.
  int? _selectedTier;

  bool _submitting = false;
  bool _subDumped = false;
  bool _initialized = false;

  /// Picks the plan row matching [tier] + the current [billing] cycle.
  SubscriptionPlanDto? _planFor(
    List<SubscriptionPlanDto> plans,
    int tier,
    BillingCycle cycle,
  ) {
    final cadence = cycle == BillingCycle.monthly ? 1 : 2;
    for (final p in plans) {
      if (p.tier == tier && p.cadence == cadence) return p;
    }
    return null;
  }

  Future<void> _proceed(List<SubscriptionPlanDto> plans) async {
    final tier = _selectedTier;
    if (tier == null) return;
    final plan = _planFor(plans, tier, _billing);
    if (plan == null) {
      SmSnackbar.error(context, 'Plan not available for that cycle.');
      return;
    }

    // Show the confirmation sheet first; the API call only fires when the
    // user explicitly confirms.
    final confirmed = await showUpgradeConfirmationSheet(
      context,
      plan: plan,
      cycle: _billing,
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    final result =
        await ref.read(subscriptionRepositoryProvider).upgrade(planId: plan.id);
    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      (err) => SmSnackbar.error(context, _messageFor(err)),
      (sub) {
        SmSnackbar.success(context, 'Subscription updated.');
        context.pop(sub);
      },
    );
  }

  String _messageFor(Object err) {
    final s = err.toString();
    return s.isEmpty ? 'Could not upgrade. Please try again.' : s;
  }

  List<_PlanGroup> _groupByTier(List<SubscriptionPlanDto> plans) {
    final byTier = <int, List<SubscriptionPlanDto>>{};
    for (final p in plans) {
      byTier.putIfAbsent(p.tier, () => []).add(p);
    }
    final groups = byTier.entries
        .map((e) => _PlanGroup(tier: e.key, plans: e.value))
        .toList();
    groups.sort((a, b) => a.tier.compareTo(b.tier));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final currentSubAsync = ref.watch(currentSubscriptionProvider);
    // Preselect only when the API actually returned a subscription. null
    // means either "no active sub" or "request errored" - both leave
    // nothing selected so the user must pick.
    final currentTier = currentSubAsync.value?.tier;

    // DEBUG: one-shot print of the current subscription so we can verify
    // what the backend actually returns. Remove once confirmed.
    if (!_subDumped) {
      _subDumped = true;
      currentSubAsync.whenData((sub) {
        // ignore: avoid_print
        print('CURRENT_SUB: ' +
            (sub == null
                ? 'null (no active subscription on backend)'
                : 'tier=${sub.tier} cadence=${sub.cadence} planId=${sub.planId} status=${sub.status}'));
      });
    }

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
      body: plansAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s24),
            child: Text(
              'Could not load plans: $err',
              style: const TextStyle(color: DesignTokens.textLight),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (plans) {
          // Preselect the tier the user is currently subscribed to, but only
          // on the first build (so the user's manual choice afterwards
          // persists). If they have no active subscription, nothing is
          // preselected and they must pick.
          if (!_initialized) {
            _initialized = true;
            _selectedTier = currentTier;
          }
          final tierGroups = _groupByTier(plans);
          return Column(
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
                  itemCount: tierGroups.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DesignTokens.s16),
                  itemBuilder: (context, i) {
                    final group = tierGroups[i];
                    final selected =
                        _planFor(plans, group.tier, _billing);
                    return _PlanCard(
                      planGroup: group,
                      selectedPlan: selected,
                      isYearly: _billing == BillingCycle.yearly,
                      isSelected: _selectedTier == group.tier,
                      onTap: () =>
                          setState(() => _selectedTier = group.tier),
                    );
                  },
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
                    onPressed: _selectedTier == null || _submitting
                        ? null
                        : () => _proceed(plans),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryGreen,
                      foregroundColor: DesignTokens.baseBlack,
                      disabledBackgroundColor: DesignTokens.primaryGreen
                          .withValues(alpha: 0.4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DesignTokens.baseBlack,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Proceed',
                                style: TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.baseBlack,
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
          );
        },
      ),
    );
  }
}

/// One tier's plans (one row per cadence), pre-sorted by sortOrder.
class _PlanGroup {
  _PlanGroup({required this.tier, required this.plans});
  final int tier;
  final List<SubscriptionPlanDto> plans;

  String get displayName => plans.first.name ?? 'Tier $tier';

  String? get marketingTag {
    for (final p in plans) {
      final t = p.marketingTag;
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }

  String get badgeAsset {
    switch (tier) {
      case 1:
        return 'assets/images/creatordash/copper_medal.png';
      case 2:
        return 'assets/images/creatordash/silver_medal.png';
      case 3:
      default:
        return 'assets/images/creatordash/gold_medal.png';
    }
  }
}

// ── Billing toggle ───────────────────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.value, required this.onChanged});

  final BillingCycle value;
  final ValueChanged<BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Row(
        children: [
          _ToggleChip(
            label: 'Billed Monthly',
            selected: value == BillingCycle.monthly,
            onTap: () => onChanged(BillingCycle.monthly),
          ),
          _ToggleChip(
            label: 'Billed Yearly',
            selected: value == BillingCycle.yearly,
            onTap: () => onChanged(BillingCycle.yearly),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? DesignTokens.primaryGreen
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? DesignTokens.baseBlack
                    : DesignTokens.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Plan card ───────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.planGroup,
    required this.selectedPlan,
    required this.isYearly,
    required this.isSelected,
    required this.onTap,
  });

  final _PlanGroup planGroup;
  final SubscriptionPlanDto? selectedPlan;
  final bool isYearly;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = selectedPlan?.priceAmount ?? 0;
    final totalPrice = price;
    final monthlyFromYearly = isYearly ? (price / 12).round() : price.round();
    final marketingTag = planGroup.marketingTag;
    final features = _featuresFor(planGroup);

    // Selected plans get a *light* green tint on the title band — strong
    // enough to read as the active card, but not so saturated that it
    // overwhelms the body. Title text is rendered in the primary green so
    // it stays legible against the lighter band. Unselected plans collapse
    // the band into the body so no extra chrome shows.
    final titleBandBg = isSelected
        ? DesignTokens.primaryGreen.withValues(alpha: 0.18)
        : DesignTokens.bgAppBody;
    final titleBandFg =
        isSelected ? DesignTokens.primaryGreen : DesignTokens.textWhite;
    final tagFg =
        isSelected ? DesignTokens.primaryGreen : DesignTokens.primaryGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          // Outer shell — border + radius only. Title band and body each
          // own their own backgrounds.
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBody,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? DesignTokens.primaryGreen
                  : DesignTokens.borderDefault,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title band — own container with own color.
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: titleBandBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleBandFg,
                      ),
                      children: [
                        TextSpan(text: '${planGroup.displayName} Plan'),
                        if (marketingTag != null)
                          TextSpan(
                            text: ' ($marketingTag)',
                            style: TextStyle(
                              color: tagFg,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body container.
              Padding(
                padding: const EdgeInsets.all(DesignTokens.s16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppFoundation,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        planGroup.badgeAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.military_tech_rounded,
                          color: DesignTokens.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Yearly: "Rs 5860 per year (480 per month)" on a
                          // single line. No "k" abbreviation on the annual
                          // total so the customer sees the exact billing
                          // amount up front; the monthly equivalent is in
                          // brackets next to it.
                          // Monthly: "Rs 900 per month".
                          if (isYearly)
                            Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  color: DesignTokens.textWhite,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Rs ${totalPrice.round()}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' per year ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DesignTokens.textMuted,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '(${monthlyFromYearly.round()} per month)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: DesignTokens.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'Rs ${totalPrice.round()}',
                                  style: const TextStyle(
                                    fontFamily: DesignTokens.fontFamily,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: DesignTokens.textWhite,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'per month',
                                  style: TextStyle(
                                    fontFamily: DesignTokens.fontFamily,
                                    fontSize: 12,
                                    color: DesignTokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: DesignTokens.s8),
                          ...features.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_rounded,
                                      size: 14,
                                      color: DesignTokens.primaryGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        fontFamily: DesignTokens.fontFamily,
                                        fontSize: 12,
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
                    const SizedBox(width: DesignTokens.s8),
                    _RadioDot(isSelected: isSelected),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _featuresFor(_PlanGroup g) {
    final p = selectedPlan;
    if (p == null) return const [];
    final out = <String>[];
    if (p.maxCampaigns == SubscriptionPlanDto.unlimited) {
      out.add('Unlimited Campaigns');
    } else {
      out.add('${p.maxCampaigns} Campaigns');
    }
    if (p.maxProducts == SubscriptionPlanDto.unlimited) {
      out.add('Unlimited Products');
    } else {
      out.add('${p.maxProducts} Products');
    }
    if (p.orderManagement) out.add('Order Management');
    return out;
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