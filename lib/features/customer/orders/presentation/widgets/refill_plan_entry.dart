import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/replenishment_rules_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The way from "Buy it again" to the prepared refill basket and to the rules
/// behind it.
///
/// **This entry point must never dangle.** It renders nothing at all when
/// personalisation is paused or refused in the Memory Vault, when the rule set
/// cannot be read, when the customer has not switched restock estimates on, or
/// while they are inside a pause they set — the same "no" the Buy-It-Again
/// rail already gives, for the same reason. A link that could only lead to
/// "you're paused" is a link that should not be drawn.
///
/// The basket link itself appears only at the `prepareBasket` automation
/// level, because that is the only level at which a basket is ever built: at
/// `remindOnly` the plan endpoint answers 204 by design, so the card offers
/// the rules instead of a door that always opens onto an empty room.
class RefillPlanEntry extends ConsumerWidget {
  const RefillPlanEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Consent first, before anything is read or offered.
    if (ref.watch(personalizationAllowedProvider).asData?.value != true) {
      return const SizedBox.shrink();
    }

    final rules = ref.watch(replenishmentRulesNotifierProvider);
    if (rules is! ReplenishmentRulesLoaded) return const SizedBox.shrink();

    final preference = rules.preference;
    if (!preference.enabled || preference.paused) {
      return const SizedBox.shrink();
    }

    final prepares = preference.prepares;

    return Container(
      key: const ValueKey('refill-plan-entry'),
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prepares ? 'Refill basket' : 'Want a basket put together?',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            prepares
                ? 'We check prices and stock and put the due items in one '
                      'basket that you approve. Nothing is ordered.'
                : "You're set to reminders only. You can ask us to assemble a "
                      'basket instead — you still approve it, and we never '
                      'order.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              if (prepares)
                OutlinedButton(
                  key: const ValueKey('refill-plan-open'),
                  onPressed: () => context.push(RouteNames.refillPlan),
                  style: _buttonStyle,
                  child: Semantics(
                    button: true,
                    label: 'Open your refill basket',
                    excludeSemantics: true,
                    child: const Text('Open refill basket'),
                  ),
                ),
              OutlinedButton(
                key: const ValueKey('refill-plan-open-rules'),
                onPressed: () => context.push(RouteNames.replenishmentRules),
                style: _buttonStyle,
                child: Semantics(
                  button: true,
                  label: 'Open your restock rules',
                  excludeSemantics: true,
                  child: const Text('Restock rules'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final ButtonStyle _buttonStyle = OutlinedButton.styleFrom(
    foregroundColor: DesignTokens.textWhite,
    side: const BorderSide(color: DesignTokens.borderDefault),
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s12,
      vertical: DesignTokens.s8,
    ),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}
