import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_scenarios.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/basket_scenarios_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Try other baskets" — Voyager "Counterfactual Basket Laboratory". Shows
/// the cart as it is next to alternatives: within a budget, for less, or
/// ready sooner. Read-only: nothing here changes the cart.
class CartScenariosScreen extends ConsumerStatefulWidget {
  const CartScenariosScreen({super.key});

  @override
  ConsumerState<CartScenariosScreen> createState() =>
      _CartScenariosScreenState();
}

class _CartScenariosScreenState extends ConsumerState<CartScenariosScreen> {
  final _budgetController = TextEditingController();
  final _keep = <String>{};
  String? _budgetError;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _showOptions(List<CartItem> items) {
    FocusScope.of(context).unfocus();
    final text = _budgetController.text.replaceAll(',', '').trim();
    final budget = text.isEmpty ? null : double.tryParse(text);
    if (text.isNotEmpty && (budget == null || budget <= 0)) {
      setState(() => _budgetError = budgetAboveZeroMessage);
      return;
    }
    setState(() => _budgetError = null);
    unawaited(
      ref
          .read(basketScenariosNotifierProvider.notifier)
          .load(
            budget: budget,
            keepLineIds: [
              for (final item in items)
                if (_keep.contains(item.id)) item.id,
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(basketScenariosNotifierProvider);
    final items = ref
        .watch(cartNotifierProvider)
        .maybeWhen(
          loadSuccess: (cart) => cart.items,
          orElse: () => const <CartItem>[],
        );
    final loading = state.maybeWhen(
      initial: () => true,
      loadInProgress: () => true,
      orElse: () => false,
    );
    final serverBudgetError = state.maybeWhen(
      loadFailure: budgetErrorOf,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Try other baskets',
          style: DesignTokens.sectionInnerTitle,
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s4,
          DesignTokens.s16,
          DesignTokens.s24 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          const _ReadOnlyNote(),
          const SizedBox(height: DesignTokens.s16),
          TextField(
            key: const ValueKey('scenario-budget-field'),
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _showOptions(items),
            onChanged: (_) {
              if (_budgetError != null) setState(() => _budgetError = null);
            },
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textWhite,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Your budget (Rs)',
              hintText: 'Optional',
            ).copyWith(errorText: _budgetError ?? serverBudgetError),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s20),
            const Text('Must keep', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s4),
            const Text(
              'Items you keep stay exactly as they are in every option.',
              style: DesignTokens.smallRegular,
            ),
            for (final item in items)
              SwitchListTile(
                key: ValueKey('keep-${item.id}'),
                contentPadding: EdgeInsets.zero,
                value: _keep.contains(item.id),
                activeThumbColor: DesignTokens.primaryGreen,
                onChanged: (keep) => setState(() {
                  if (keep) {
                    _keep.add(item.id);
                  } else {
                    _keep.remove(item.id);
                  }
                }),
                title: Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumSemibold,
                ),
                subtitle: item.variantName.isEmpty
                    ? null
                    : Text(item.variantName, style: DesignTokens.smallRegular),
              ),
          ],
          const SizedBox(height: DesignTokens.s16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: DesignTokens.primaryButtonStyle(),
              onPressed: loading ? null : () => _showOptions(items),
              child: const Text(
                'Show options',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          ...state.when(
            initial: _loader,
            loadInProgress: _loader,
            loadSuccess: (result) => result.scenarios.isEmpty
                ? const [
                    _Message('There are no other baskets to show right now.'),
                  ]
                : [
                    for (final scenario in result.scenarios)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.s12,
                        ),
                        child: _ScenarioCard(scenario: scenario),
                      ),
                  ],
            // A rejected budget is already shown on the field.
            loadFailure: (_) => serverBudgetError != null
                ? const <Widget>[]
                : [_LoadError(onRetry: () => _showOptions(items))],
          ),
        ],
      ),
    );
  }

  static List<Widget> _loader() => const [
    Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.s32),
      child: SmPageLoader(size: 48),
    ),
  ];
}

class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.infoFillDark,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: DesignTokens.infoIconLight,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              'See your cart within a budget, for less, or ready sooner. '
              'Nothing changes in your cart until you do it yourself.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.infoTextLight,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});

  final BasketScenario scenario;

  @override
  Widget build(BuildContext context) {
    final diff = scenario.difference.amount;
    final diffColor = diff.abs() < 0.005
        ? DesignTokens.textMuted
        : diff < 0
        ? DesignTokens.primaryGreen
        : DesignTokens.warning500;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(
        borderColor: DesignTokens.borderDefault,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  scenario.title,
                  style: DesignTokens.oneLinerSemibold.copyWith(height: 1.3),
                ),
              ),
              if (!scenario.feasible) ...[
                const SizedBox(width: DesignTokens.s8),
                const _NotPossibleTag(),
              ],
            ],
          ),
          if (scenario.summary.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              scenario.summary,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                formatMoney(scenario.grandTotal),
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.textWhite,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  scenarioDifferenceLabel(scenario.difference),
                  style: DesignTokens.smallRegular.copyWith(
                    color: diffColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          _Fact(
            icon: Icons.local_shipping_outlined,
            text: readyToShipLabel(scenario.dispatchDays),
          ),
          if (scenario.sellerCount > 0)
            _Fact(
              icon: Icons.storefront_outlined,
              text: sellerCountLabel(scenario.sellerCount),
            ),
          if (scenario.itemsAtStockRisk > 0)
            _Fact(
              icon: Icons.warning_amber_rounded,
              text: stockRiskLabel(scenario.itemsAtStockRisk),
              color: DesignTokens.warning500,
            ),
          if (scenario.changes.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            for (final change in scenario.changes)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: DesignTokens.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: Text(
                        change,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
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

    return scenario.feasible ? card : Opacity(opacity: 0.55, child: card);
  }
}

class _NotPossibleTag extends StatelessWidget {
  const _NotPossibleTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Not possible',
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textLight,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.text,
    this.color = DesignTokens.textLight,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: DesignTokens.s6),
          Expanded(
            child: Text(
              text,
              style: DesignTokens.smallRegular.copyWith(
                color: color,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: DesignTokens.smallRegular,
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Message('Could not build other baskets right now.'),
        TextButton(
          style: DesignTokens.textButtonStyle(),
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

/// "Rs 1,130.00 less" / "Rs 113.00 more" against the cart as it is now.
String scenarioDifferenceLabel(Money difference) {
  final amount = difference.amount;
  if (amount.abs() < 0.005) return 'Same as your cart now';
  final formatted = formatMoney(
    Money(amount: amount.abs(), currency: difference.currency),
  );
  return amount < 0 ? '$formatted less' : '$formatted more';
}

String readyToShipLabel(int days) => switch (days) {
  <= 0 => 'Ready to ship today',
  1 => 'Ready to ship in 1 day',
  _ => 'Ready to ship in $days days',
};

String sellerCountLabel(int count) =>
    count == 1 ? '1 seller' : '$count sellers';

String stockRiskLabel(int items) => items == 1
    ? '1 item may not have enough stock'
    : '$items items may not have enough stock';
