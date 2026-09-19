import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/refill_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/refill_plan_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/replenishment_rules_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/orders_load_error_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/refill_plan_line_tile.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// "Refill basket" (`/orders/refill-plan`) — the Prepare stage of predictive
/// replenishment, and the sibling of "Buy it again".
///
/// Buy-It-Again lists the *estimates* the predictor already computed, one row
/// at a time, and every add is its own tap. This screen is what the customer
/// gets when they raise their automation level to `prepareBasket`: the same
/// estimates, **verified** against today's catalogue and assembled into one
/// basket they approve or throw away as a whole. It shares that screen's
/// consent gate, its voice and its Mall kit, and it does not replace it.
///
/// The rules that shape every pixel here:
///
/// **The platform never orders.** There are exactly two automation levels and
/// no third. Approving a plan records a yes and hands back lines *for the
/// customer's own cart* — it creates no order, no hold and no charge, and the
/// screen says so in plain words at the point of approval.
///
/// **A prediction is not a fact.** The plan's own `headline` and `caveat` come
/// off the payload and are rendered verbatim, in the same voice the
/// Buy-It-Again header already uses: these are estimates, and the platform
/// cannot see what the customer has at home.
///
/// **Excluded means excluded.** An unverifiable line is left out of the
/// basket, its price is null, and it is drawn as left out — not as nearly in.
///
/// **No confidence figure.** The steadiness rule the customer set is the only
/// form that gate takes; no score is on the payload and none is reconstructed.
///
/// **204 is an answer.** When the customer's own rules say no basket, the
/// screen is calm and says nothing is wrong.
class RefillPlanScreen extends ConsumerWidget {
  const RefillPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(personalizationAllowedProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Refill basket'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            semanticLabel: 'Back',
          ),
          onPressed: () => context.popOrHome(),
        ),
        actions: [
          IconButton(
            key: const ValueKey('refill-plan-rules'),
            tooltip: 'Restock rules',
            icon: const Icon(
              Icons.tune_rounded,
              color: DesignTokens.textWhite,
              semanticLabel: 'Restock rules',
            ),
            onPressed: () => context.push(RouteNames.replenishmentRules),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: allowed.when(
          // Consent is read before anything is asked for, exactly as on
          // Buy-It-Again: a paused customer never triggers the plan fetch.
          loading: () => const _RefillSkeleton(),
          error: (_, _) => const _PausedView(),
          data: (isAllowed) =>
              isAllowed ? const _RefillPlanBody() : const _PausedView(),
        ),
      ),
    );
  }
}

/// The consented branch: the customer's rules decide what can be shown before
/// the plan itself is consulted.
class _RefillPlanBody extends ConsumerWidget {
  const _RefillPlanBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(replenishmentRulesNotifierProvider);

    return switch (rules) {
      ReplenishmentRulesLoading() => const _RefillSkeleton(),
      // Rules that cannot be read are not rules to act on.
      ReplenishmentRulesFailed() => const OrdersScrollableState(
        child: MallEmptyState(
          icon: Icons.cloud_off_rounded,
          title: "We couldn't check your settings",
          body:
              "Refill baskets stay off until we can read whether you've asked "
              'for them. Pull down to try again.',
        ),
      ),
      ReplenishmentRulesLoaded(:final preference) => switch (preference) {
        // The feature's own opt-in, and the customer's own pause. Both are a
        // "no" and neither is an error.
        _ when !preference.enabled => const _OffView(),
        _ when preference.paused => const _PausedByRuleView(),
        // Reminders only is a rule, not a fault: the customer asked not to
        // have a basket built, so the screen offers the way to change that
        // rather than an empty basket.
        _ when !preference.prepares => const _RemindOnlyView(),
        _ => const _PlanView(),
      },
    };
  }
}

class _PlanView extends ConsumerStatefulWidget {
  const _PlanView();

  @override
  ConsumerState<_PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends ConsumerState<_PlanView> {
  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(refillPlanNotifierProvider);
    final notifier = ref.read(refillPlanNotifierProvider.notifier);

    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: notifier.load,
      child: switch (state) {
        RefillPlanLoading() => const _RefillSkeleton(),
        // A failed read is not the fact that there is no basket, so it gets
        // its own state and says what it is.
        RefillPlanFailed() => OrdersScrollableState(
          child: MallEmptyState(
            icon: Icons.cloud_off_rounded,
            title: "We couldn't load your refill basket",
            body:
                'Nothing has changed and nothing was approved — we just '
                "couldn't read it. Pull down or tap to try again.",
            actionLabel: 'Try again',
            onAction: notifier.load,
          ),
        ),
        // 204. The rules said no basket, which is the ordinary answer.
        RefillPlanNone() => _NoBasketView(
          onPrepare: notifier.prepare,
        ),
        RefillPlanReady(:final plan, :final busy) => _PreparedBasket(
          plan: plan,
          busy: busy,
          onConfirm: _confirm,
          onDismiss: _dismiss,
        ),
        RefillPlanConfirmed(:final handoff, :final addingToCart) =>
          _ConfirmedView(
            handoff: handoff,
            addingToCart: addingToCart,
            onAddToCart: () => _addToCart(handoff),
          ),
      },
    );
  }

  /// The approval boundary. It records the customer's yes and brings back the
  /// lines — it does not order, reserve or charge, and it does not touch the
  /// cart either. Moving the lines into the cart is its own tap afterwards.
  Future<void> _confirm() async {
    final ok = await ref.read(refillPlanNotifierProvider.notifier).confirm();
    if (!mounted || ok) return;
    SmSnackbar.error(context, "Couldn't save your approval. Please try again.");
  }

  Future<void> _dismiss() async {
    final ok = await ref.read(refillPlanNotifierProvider.notifier).dismiss();
    if (!mounted) return;
    if (ok) {
      SmSnackbar.success(context, 'Basket thrown away');
    } else {
      SmSnackbar.error(context, "Couldn't throw it away. Please try again.");
    }
  }

  /// The only path from this screen into a cart, and it runs on a tap and
  /// nothing else. Each line goes through the same guarded cart path every
  /// other add uses; prices and money stay the server's business.
  Future<void> _addToCart(RefillPlanHandoffDto handoff) async {
    final notifier = ref.read(refillPlanNotifierProvider.notifier)
      ..setAddingToCart(adding: true);
    final cart = ref.read(cartNotifierProvider.notifier);
    var added = 0;
    for (final line in handoff.lines) {
      final ok = await cart.addItem(
        productId: line.productId,
        variantId: line.productVariantId,
        quantity: line.quantity,
        idempotencyKey: _uuid.v4(),
      );
      if (ok) added++;
    }
    if (!mounted) return;
    notifier.setAddingToCart(adding: false);
    if (added == handoff.lines.length) {
      SmSnackbar.success(context, 'Added $added item(s) to your cart');
    } else {
      SmSnackbar.error(
        context,
        "Couldn't add every item to your cart. Please try again.",
      );
    }
  }
}

/// The prepared basket: the server's framing, the lines, the consolidation
/// view, then the approval.
class _PreparedBasket extends StatelessWidget {
  const _PreparedBasket({
    required this.plan,
    required this.busy,
    required this.onConfirm,
    required this.onDismiss,
  });

  final RefillPlanDto plan;
  final bool busy;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final excluded = plan.lines.where((l) => !l.included).toList();
    final included = plan.lines.where((l) => l.included).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      children: [
        // The server's own words for what this is, and what it is not. Both
        // rendered verbatim — they are the reason this surface may exist.
        Text(
          plan.headline,
          style: DesignTokens.sectionInnerTitle.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s6),
        Text(
          plan.caveat,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        if (included.isNotEmpty) ...[
          const _GroupLabel('In this basket'),
          for (final line in included)
            RefillPlanLineTile(
              key: ValueKey('refill-line-${line.productVariantId}'),
              line: line,
              onOpenProduct: () => _openProduct(context, line),
            ),
        ],
        if (excluded.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          const _GroupLabel('Left out'),
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s8),
            child: Text(
              'These are not in the basket and are not counted in the total. '
              "We left each one out for the reason under it — we don't add "
              "something we couldn't check.",
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                height: 1.35,
              ),
            ),
          ),
          for (final line in excluded)
            RefillPlanLineTile(
              key: ValueKey('refill-line-${line.productVariantId}'),
              line: line,
              onOpenProduct: () => _openProduct(context, line),
            ),
        ],
        if (plan.deliveryGroups.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          _DeliveryGroups(plan: plan),
        ],
        const SizedBox(height: DesignTokens.s16),
        MallMoneyLedger(
          semanticLabel: 'Basket total',
          amounts: [
            MallAmount(
              label: '${plan.includedLineCount} item(s) in this basket',
              value: formatMoney(
                Money(amount: plan.includedSubtotal, currency: plan.currency),
              ),
              kind: MallAmountKind.total,
              note: 'Only the items above that we could check are counted.',
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),
        _ConfirmBlock(busy: busy, onConfirm: onConfirm, onDismiss: onDismiss),
      ],
    );
  }

  void _openProduct(BuildContext context, RefillPlanLineDto line) =>
      context.push(
        RouteNames.productDetail.replaceFirst(':productId', line.productId),
      );
}

/// The approval, and the sentence that has to sit next to it.
///
/// **This is the exact copy the §5.9 boundary requires at the point of
/// approval.** The platform never places an order; approving records a yes
/// and hands the lines to the customer's own cart. A button that said
/// "Order now" — or a screen that let the customer assume it — would be the
/// contract broken in the one place it matters.
class _ConfirmBlock extends StatelessWidget {
  const _ConfirmBlock({
    required this.busy,
    required this.onConfirm,
    required this.onDismiss,
  });

  static const String confirmCopy =
      'Approving records your yes and hands these items to your own cart. '
      'StyleMint never places an order on your behalf: nothing here is '
      'ordered, '
      'reserved or paid for, and no money moves until you check out yourself.';

  final bool busy;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) => Container(
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
          confirmCopy,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
            height: 1.45,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('refill-confirm'),
            onPressed: busy ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.primaryGreen,
              foregroundColor: DesignTokens.bgAppFoundation,
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.s12,
              ),
            ),
            child: Semantics(
              button: true,
              label: busy
                  ? 'Saving your approval'
                  : 'Approve this basket. Nothing is ordered',
              excludeSemantics: true,
              child: Text(
                busy ? 'Saving' : 'Approve this basket',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const ValueKey('refill-dismiss'),
            onPressed: busy ? null : onDismiss,
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.textWhite,
              side: const BorderSide(color: DesignTokens.borderDefault),
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
            ),
            child: Semantics(
              button: true,
              label: 'Throw this basket away',
              excludeSemantics: true,
              child: const Text('No thanks, throw it away'),
            ),
          ),
        ),
      ],
    ),
  );
}

/// After approval. The server's own note is shown verbatim, because the next
/// thing that reads this could otherwise assume an order exists.
///
/// Moving the lines into the cart is a separate, explicit tap: approving and
/// adding are two different things and the screen keeps them two.
class _ConfirmedView extends StatelessWidget {
  const _ConfirmedView({
    required this.handoff,
    required this.addingToCart,
    required this.onAddToCart,
  });

  final RefillPlanHandoffDto handoff;
  final bool addingToCart;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(DesignTokens.s16),
    children: [
      const MallStatusPill(
        label: 'Approved',
        tone: MallStatusTone.success,
        semanticLabel: 'Approved',
      ),
      const SizedBox(height: DesignTokens.s12),
      Text(
        handoff.note,
        style: DesignTokens.bodyText.copyWith(
          color: DesignTokens.textWhite,
          height: 1.45,
        ),
      ),
      const SizedBox(height: DesignTokens.s12),
      MallMoneyLedger(
        amounts: [
          MallAmount(
            label: '${handoff.lines.length} item(s) ready to add',
            value: formatMoney(
              Money(amount: handoff.subtotal, currency: handoff.currency),
            ),
            kind: MallAmountKind.total,
          ),
        ],
      ),
      const SizedBox(height: DesignTokens.s16),
      FilledButton(
        key: const ValueKey('refill-add-to-cart'),
        onPressed: addingToCart ? null : onAddToCart,
        style: FilledButton.styleFrom(
          backgroundColor: DesignTokens.primaryGreen,
          foregroundColor: DesignTokens.bgAppFoundation,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
        ),
        child: Semantics(
          button: true,
          label: addingToCart
              ? 'Adding these items to your cart'
              : 'Move these items to my cart',
          excludeSemantics: true,
          child: Text(
            addingToCart ? 'Adding' : 'Move these to my cart',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(height: DesignTokens.s8),
      Text(
        'You can change quantities, remove anything, or leave the cart alone.',
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      ),
    ],
  );
}

/// The Prepare stage's consolidation view: which included lines come from the
/// same seller. This groups what Orders already knows — it is not a delivery
/// quote, a carrier choice or an arrival estimate, and nothing here implies
/// one.
class _DeliveryGroups extends StatelessWidget {
  const _DeliveryGroups({required this.plan});

  static String _money(double amount, String currency) =>
      formatMoney(Money(amount: amount, currency: currency));

  final RefillPlanDto plan;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const _GroupLabel('Likely to travel together'),
      for (final group in plan.deliveryGroups)
        Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s4),
          child: Text(
            '${group.vendorName} — ${group.lineCount} item(s), '
            '${_money(group.subtotal, group.currency)}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
      Text(
        'Items from one seller usually ship together. This is not a delivery '
        'estimate.',
        style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
      ),
    ],
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s8),
    child: Text(
      label,
      style: DesignTokens.smallRegular.copyWith(
        color: DesignTokens.textWhite,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    ),
  );
}

/// 204 — the rules said no basket. Nothing is wrong, nothing failed, and
/// nobody should buy anything because of this screen.
class _NoBasketView extends StatelessWidget {
  const _NoBasketView({required this.onPrepare});

  final Future<void> Function() onPrepare;

  @override
  Widget build(BuildContext context) => OrdersScrollableState(
    child: MallEmptyState(
      icon: Icons.shopping_basket_outlined,
      title: 'No refill basket right now',
      body:
          'Your rules decide when we put one together — how far ahead to look, '
          'how often, and how even a buying pattern has to be. Nothing is due '
          'under them today. An empty basket is the normal one.',
      actionLabel: 'Check again now',
      onAction: onPrepare,
    ),
  );
}

/// Reminders only. Two automation levels exist and this is the quieter one;
/// the screen names the other and points at the rules, and never suggests a
/// third.
class _RemindOnlyView extends StatelessWidget {
  const _RemindOnlyView();

  @override
  Widget build(BuildContext context) => OrdersScrollableState(
    child: MallEmptyState(
      icon: Icons.notifications_none_rounded,
      title: 'You asked for reminders only',
      body:
          "We're not putting a basket together. If you'd like one "
          'ready to look over, change that in your restock rules. Even then '
          'we only prepare it — you approve it, and we never order.',
      actionLabel: 'Open restock rules',
      onAction: () => context.push(RouteNames.replenishmentRules),
    ),
  );
}

/// The customer's own quiet period, which lifts itself.
class _PausedByRuleView extends StatelessWidget {
  const _PausedByRuleView();

  @override
  Widget build(BuildContext context) => OrdersScrollableState(
    child: MallEmptyState(
      icon: Icons.pause_circle_outline_rounded,
      title: 'Restock is paused',
      body:
          "You've paused restock for now, so we're not preparing anything. It "
          'lifts by itself when the pause ends, and you can end it early in '
          'your restock rules.',
      actionLabel: 'Open restock rules',
      onAction: () => context.push(RouteNames.replenishmentRules),
    ),
  );
}

/// The feature's own opt-in is off.
class _OffView extends StatelessWidget {
  const _OffView();

  @override
  Widget build(BuildContext context) => const OrdersScrollableState(
    child: MallEmptyState(
      icon: Icons.autorenew_rounded,
      title: 'Restock estimates are off',
      body:
          'Turn them on from "Buy it again" and we can estimate when something '
          'you buy regularly might be due again, from your own order history. '
          'We never order anything on your behalf.',
    ),
  );
}

/// Personalisation is paused in the Memory Vault. Same answer as the
/// Buy-It-Again screen gives, for the same reason.
class _PausedView extends StatelessWidget {
  const _PausedView();

  @override
  Widget build(BuildContext context) => OrdersScrollableState(
    child: MallEmptyState(
      icon: Icons.pause_circle_outline_rounded,
      title: 'Restock estimates are paused',
      body:
          "You've paused being remembered, so we're not predicting "
          'anything. You can change that in your Memory Vault whenever you '
          'like.',
      actionLabel: 'Open Memory Vault',
      onAction: () => context.push(RouteNames.settingsMemory),
    ),
  );
}

class _RefillSkeleton extends StatelessWidget {
  const _RefillSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(DesignTokens.s16),
    children: [
      for (var i = 0; i < 4; i++)
        const Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.s12),
          child: SmSkeleton.box(height: 96),
        ),
    ],
  );
}
