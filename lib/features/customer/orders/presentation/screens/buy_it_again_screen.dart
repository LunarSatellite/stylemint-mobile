import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/orders_load_error_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/refill_plan_entry.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// "Buy it again" (`/orders/buy-it-again`) — the replenishment *estimates*
/// the Orders module already computed, listed in full.
///
/// Three rules shape every line on this screen.
///
/// **A prediction is not a fact.** `ReorderPredictionService` returns rows
/// above its own confidence floor (0.4) whose expected next purchase falls
/// inside its window. That is a guess about *timing*, drawn from how often
/// this customer has bought before. The platform has no idea what is in
/// anyone's home, so nothing here says a customer has run out — the backend's
/// own `reason` line hedges ("may be out", "likely running low") and is shown
/// as it was sent, under a header that says plainly these are estimates.
///
/// **Only the server's figures are drawn.** Product name, price, the
/// suggested quantity, the days until expected and the reason line all come
/// off the DTO. Nothing on this screen computes a consumption rate, a
/// deadline, an urgency rank or a scarcity count. Confidence is a model
/// internal and is not shown as a percentage: a shopper cannot act on 0.62.
///
/// **Reordering is the customer's move.** Nothing is added to a cart by
/// opening this screen, scrolling it or refreshing it. Every add is one tap
/// on one row, through the guarded cart path; prices, stock and money are the
/// server's business (§5.9).
class BuyItAgainScreen extends ConsumerWidget {
  const BuyItAgainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(personalizationAllowedProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Buy it again'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            semanticLabel: 'Back',
          ),
          onPressed: () => context.popOrHome(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: allowed.when(
          // Consent is read before anything is asked for, so a paused
          // customer never even triggers the prediction fetch.
          loading: () => const _BuyItAgainSkeleton(),
          error: (_, _) => const _PausedView(),
          data: (isAllowed) =>
              isAllowed ? const _PredictionsView() : const _PausedView(),
        ),
      ),
    );
  }
}

/// The signed-in, not-paused branch: the feature's own opt-in, then the list.
class _PredictionsView extends ConsumerWidget {
  const _PredictionsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(replenishmentPreferenceNotifierProvider);

    return switch (preference) {
      ReplenishmentPreferenceLoading() => const _BuyItAgainSkeleton(),
      // A preference that cannot be read is not a preference to override:
      // predicting anyway would be predicting without consent.
      ReplenishmentPreferenceFailed() => const OrdersScrollableState(
        child: MallEmptyState(
          icon: Icons.cloud_off_rounded,
          title: "We couldn't check your settings",
          body:
              "Restock estimates stay off until we can read whether you've "
              'turned them on. Pull down to try again.',
        ),
      ),
      ReplenishmentPreferenceLoaded(:final enabled, :final saving) =>
        enabled ? const _SuggestionsList() : _OptInView(saving: saving),
    };
  }
}

class _SuggestionsList extends ConsumerStatefulWidget {
  const _SuggestionsList();

  @override
  ConsumerState<_SuggestionsList> createState() => _SuggestionsListState();
}

class _SuggestionsListState extends ConsumerState<_SuggestionsList> {
  static const _uuid = Uuid();

  /// Product ids with an add-to-cart call in flight, so one row's button can
  /// disable itself without freezing the rest of the list.
  final Set<String> _adding = <String>{};

  /// The only path from this screen into a cart, and it runs on a tap and
  /// nothing else — not on build, not on scroll, not on refresh.
  Future<void> _addToCart(ReorderSuggestionDto suggestion) async {
    if (_adding.contains(suggestion.productId)) return;
    setState(() => _adding.add(suggestion.productId));
    final ok = await ref
        .read(cartNotifierProvider.notifier)
        .addItem(
          productId: suggestion.productId,
          quantity: suggestion.suggestedQuantity,
          idempotencyKey: _uuid.v4(),
        );
    if (!mounted) return;
    setState(() => _adding.remove(suggestion.productId));
    if (ok) {
      SmSnackbar.success(context, 'Added ${suggestion.productName} to cart');
    } else {
      SmSnackbar.error(context, "Couldn't add to cart. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reorderSuggestionsNotifierProvider);
    final notifier = ref.read(reorderSuggestionsNotifierProvider.notifier);

    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: notifier.load,
      child: state.when(
        initial: () => const _BuyItAgainSkeleton(),
        loadInProgress: () => const _BuyItAgainSkeleton(),
        loadFailure: (failure) => OrdersScrollableState(
          child: OrdersLoadErrorView(
            failure: failure,
            onRetry: notifier.load,
            subject: 'your restock estimates',
          ),
        ),
        loadSuccess: (suggestions) {
          if (suggestions.isEmpty) return const _EmptyView();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s8,
              DesignTokens.s16,
              DesignTokens.s24,
            ),
            itemCount: suggestions.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s4),
            itemBuilder: (_, index) {
              // The header, then the way through to the prepared basket
              // and the rules behind it. The entry renders nothing at all
              // unless the customer's own rules say it can (see
              // [RefillPlanEntry]), so it never dangles.
              if (index == 0) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [_EstimateHeader(), RefillPlanEntry()],
                );
              }
              final suggestion = suggestions[index - 1];
              return _SuggestionRow(
                key: ValueKey('buy-it-again-${suggestion.productId}'),
                suggestion: suggestion,
                busy: _adding.contains(suggestion.productId),
                onAdd: () => _addToCart(suggestion),
              );
            },
          );
        },
      ),
    );
  }
}

/// The framing, stated once at the top rather than repeated on every row:
/// what these rows are, what the platform does not know, and that nothing
/// happens without a tap.
class _EstimateHeader extends StatelessWidget {
  const _EstimateHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: DesignTokens.s4,
      bottom: DesignTokens.s12,
    ),
    child: Text(
      'Estimated from your past orders. These are guesses about timing — we '
      "don't know what you still have. Nothing is added to your cart unless "
      'you tap.',
      style: DesignTokens.smallRegular.copyWith(
        color: DesignTokens.textMuted,
        height: 1.4,
      ),
    ),
  );
}

/// One estimate. A typographic Mall row — the Mall is video-first and a
/// product photograph belongs to product detail — carrying the server's own
/// reason line and its own day count, and one explicit add button.
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.busy,
    required this.onAdd,
    super.key,
  });

  final ReorderSuggestionDto suggestion;
  final bool busy;
  final VoidCallback onAdd;

  /// The server's `daysUntilExpected`, said as the number it is. Never
  /// rounded, bucketed or turned into an urgency of our own.
  String get _timing => switch (suggestion.daysUntilExpected) {
    0 => 'Estimated for around today',
    1 => 'Estimated in about 1 day',
    final days => 'Estimated in about $days days',
  };

  @override
  Widget build(BuildContext context) {
    // The quantity the server said this customer usually buys — not a
    // quantity the client picked for them.
    final addLabel = 'Add ${suggestion.suggestedQuantity} to cart';

    return MallResultRow(
      product: MallProductVm(
        id: suggestion.productId,
        name: suggestion.productName,
        price: Money(
          amount: suggestion.price,
          currency: suggestion.currency,
        ),
      ),
      onTap: () => context.push(
        RouteNames.productDetail.replaceFirst(
          ':productId',
          suggestion.productId,
        ),
      ),
      signal: MallSignal(
        label: _timing,
        icon: Icons.schedule_rounded,
      ),
      // The word "estimate" is spoken before the product, so a screen-reader
      // user hears what kind of row this is before they hear what it sells.
      semanticPrefix: 'Restock estimate',
      semanticExtras: [suggestion.reason],
      footer: Padding(
        padding: const EdgeInsets.only(top: DesignTokens.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The backend's own wording for why it expects this, shown as it
            // was sent. The client does not rewrite it and does not sharpen
            // it.
            Text(
              suggestion.reason,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                key: ValueKey('buy-it-again-add-${suggestion.productId}'),
                onPressed: busy ? null : onAdd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.textWhite,
                  side: const BorderSide(color: DesignTokens.borderDefault),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s12,
                    vertical: DesignTokens.s6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.buttonRadius,
                    ),
                  ),
                ),
                child: Semantics(
                  button: true,
                  label: '$addLabel, ${suggestion.productName}',
                  excludeSemantics: true,
                  child: Text(
                    busy ? 'Adding' : addLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Most customers, most of the time. Nothing is wrong and nobody should buy
/// anything because of this screen — so it says so, and offers no purchase.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const OrdersScrollableState(
    child: Padding(
      padding: EdgeInsets.all(DesignTokens.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MallEmptyState(
            icon: Icons.event_repeat_outlined,
            title: 'Nothing to suggest right now',
            body:
                'We only estimate a repeat once your past orders show a '
                'rhythm we can read. An empty list is the normal one — there '
                'is nothing to fix and nothing you need to buy.',
          ),
          SizedBox(height: DesignTokens.s16),
          // Reachable even with nothing due, so a customer can still change
          // the rules that decide what "due" means. Renders nothing when
          // those rules say it should not be here.
          RefillPlanEntry(),
        ],
      ),
    ),
  );
}

/// Personalisation is paused in the Memory Vault. No estimates are fetched
/// and none are shown; the screen says where the switch is and stops there.
class _PausedView extends StatelessWidget {
  const _PausedView();

  @override
  Widget build(BuildContext context) => OrdersScrollableState(
    child: MallEmptyState(
      icon: Icons.pause_circle_outline_rounded,
      title: 'Restock estimates are paused',
      body:
          "You've paused being remembered, so we're not predicting anything "
          'for you. You can change that in your Memory Vault whenever you '
          'like.',
      actionLabel: 'Open Memory Vault',
      onAction: () => context.push(RouteNames.settingsMemory),
    ),
  );
}

/// The feature's own opt-in, for a customer who has never turned it on or has
/// switched it off. Same consent the Orders screen's rail asks for.
class _OptInView extends ConsumerStatefulWidget {
  const _OptInView({required this.saving});

  final bool saving;

  @override
  ConsumerState<_OptInView> createState() => _OptInViewState();
}

class _OptInViewState extends ConsumerState<_OptInView> {
  @override
  Widget build(BuildContext context) => OrdersScrollableState(
    child: MallEmptyState(
      icon: Icons.autorenew_rounded,
      title: 'Restock estimates are off',
      body:
          'Turn them on and we can estimate when something you buy regularly '
          'might be due again, from your own order history. We never order '
          'anything for you.',
      actionLabel: widget.saving ? 'Saving' : 'Turn on estimates',
      onAction: widget.saving ? null : _enable,
    ),
  );

  Future<void> _enable() async {
    final saved = await ref
        .read(replenishmentPreferenceNotifierProvider.notifier)
        .setEnabled(true);
    if (!mounted) return;
    if (!saved) {
      SmSnackbar.error(context, "Couldn't save your preference. Try again.");
      return;
    }
    await ref.read(reorderSuggestionsNotifierProvider.notifier).load();
  }
}

class _BuyItAgainSkeleton extends StatelessWidget {
  const _BuyItAgainSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(DesignTokens.s16),
    children: [
      for (var i = 0; i < 4; i++)
        const Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.s12),
          child: SmSkeleton.box(height: 84),
        ),
    ],
  );
}
