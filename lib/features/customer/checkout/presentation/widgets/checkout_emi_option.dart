import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/plan_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// "Pay with EMI", inline on the checkout screen.
///
/// Every cart line whose variant has plan options (`GET /v1/credit/offers/
/// {variantId}`) gets a card that shows the plans right here: each kind on
/// offer, its tenures as chips, the down payment (adjustable when the offer
/// allows), the monthly amount and the total. The figures come from the same
/// arithmetic and quote endpoint as the product page's plan sheet.
///
/// The card's button follows the buyer: sign in, get verified (opens the KYC
/// flow and comes back here), verification in review, or — once verified —
/// "Pay down payment Rs X with EMI", which asks for a signed quote, applies
/// (a verified buyer is approved automatically unless there is a real risk
/// reason), and opens the plan checkout where the down payment is paid.
///
/// A plan covers one item and checks it out on its own
/// (`POST /v1/checkout/sessions/payment-plan`); the rest of the cart stays.
class CheckoutEmiOption extends ConsumerWidget {
  const CheckoutEmiOption({required this.items, super.key});

  final List<CartItem> items;

  static const Key cardKey = Key('checkout-emi-card');
  static const Key noteKey = Key('checkout-emi-note');
  static const Key loadingKey = Key('checkout-emi-loading');
  static const Key payKey = Key('checkout-emi-pay');
  static const Key verifyKey = Key('checkout-emi-verify');
  static const Key inReviewKey = Key('checkout-emi-in-review');
  static const Key errorKey = Key('checkout-emi-error');

  /// Whether a plan-options failure just means "no plan on this item"
  /// (draw nothing) rather than "could not ask" (offer a retry).
  static bool _meansNoPlan(EmiFailure f) =>
      f.isNotFound || f.kind == EmiFailureKind.rejected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = <Widget>[];
    var plans = 0;
    for (final item in items) {
      final id = item.variantId;
      if (id == null || id.isEmpty) continue;
      final async = ref.watch(planOptionsProvider(id));
      async.when(
        loading: () => children.add(
          _LoadingRow(key: ValueKey('checkout-emi-loading-$id')),
        ),
        error: (error, _) {
          final failure = error is EmiLoadException ? error.failure : null;
          if (failure != null && _meansNoPlan(failure)) return;
          // Not silently nothing: a buyer whose plans could not be fetched
          // can try again rather than conclude there are none.
          children.add(
            _RetryRow(
              key: ValueKey('checkout-emi-error-$id'),
              onRetry: () => ref.invalidate(planOptionsProvider(id)),
            ),
          );
        },
        data: (options) {
          if (options.options.isEmpty) return;
          plans++;
          children.add(
            CheckoutEmiPlans(
              key: ValueKey('checkout-emi-plans-$id'),
              item: item,
              options: options,
              named: items.length > 1,
            ),
          );
        },
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        if (plans > 0 && (items.length > 1 || items.any((i) => i.quantity > 1)))
          Padding(
            key: noteKey,
            padding: const EdgeInsets.only(bottom: DesignTokens.s16),
            child: const Text(
              'A payment plan covers one item: paying with EMI checks out that '
              'item on its own, and the rest stays in your cart.',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: DesignTokens.s16),
    child: Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: DesignTokens.s8),
        Text(
          'Checking payment plans…',
          key: CheckoutEmiOption.loadingKey,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    ),
  );
}

class _RetryRow extends StatelessWidget {
  const _RetryRow({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s16),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Could not load payment plans.',
            key: CheckoutEmiOption.errorKey,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

/// One kind of plan, as the checkout card offers it.
class _Kind {
  _Kind(this.option)
    : minPercent = option.minDownPaymentPercent,
      maxPercent = option.downPaymentFixed
          ? option.minDownPaymentPercent
          : (option.maxDownPaymentPercent < option.minDownPaymentPercent
                ? option.minDownPaymentPercent
                : option.maxDownPaymentPercent);

  final PlanOption option;
  final int minPercent;
  final int maxPercent;

  PlanKind get kind => option.kind;
  bool get adjustable => maxPercent > minPercent;
}

/// The plans for one cart line, inline.
class CheckoutEmiPlans extends ConsumerStatefulWidget {
  const CheckoutEmiPlans({
    required this.item,
    required this.options,
    this.named = false,
    this.quoteDebounce = const Duration(milliseconds: 300),
    super.key,
  });

  final CartItem item;
  final PlanOptions options;
  final bool named;
  final Duration quoteDebounce;

  @override
  ConsumerState<CheckoutEmiPlans> createState() => _CheckoutEmiPlansState();
}

class _CheckoutEmiPlansState extends ConsumerState<CheckoutEmiPlans> {
  static const _uuid = Uuid();

  late final List<_Kind> _kinds = _orderedKinds();
  late _Kind _kind = _kinds.first;
  late int _percent = _kind.minPercent;
  late int _tenure = _kind.option.tenures.last;

  EmiQuote? _quote;
  Timer? _debounce;
  int _request = 0;

  bool _paying = false;
  String? _error;

  /// One key per selection the buyer means to pay for: a retry after a
  /// dropped connection is the same application, not a second one.
  String _applyKey = _uuid.v4();

  String get _variantId => widget.item.variantId!;

  /// EMI first, then pay later, then prepay.
  List<_Kind> _orderedKinds() {
    final kinds = [for (final o in widget.options.options) _Kind(o)];
    int rank(PlanKind k) => switch (k) {
      PlanKind.instalment => 0,
      PlanKind.payLater => 1,
      PlanKind.prepay => 2,
    };
    kinds.sort((a, b) => rank(a.kind).compareTo(rank(b.kind)));
    return kinds;
  }

  @override
  void initState() {
    super.initState();
    _scheduleQuote();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleQuote() {
    _debounce?.cancel();
    if (_kind.kind != PlanKind.instalment) return;
    _debounce = Timer(widget.quoteDebounce, () => unawaited(_fetchQuote()));
  }

  /// The server's figures for EMI (`GET /v1/emi/quote`), as the plan sheet
  /// uses. Until they arrive — or if they cannot — the device's own
  /// arithmetic (the same contract rounding) is shown.
  Future<void> _fetchQuote() async {
    final request = ++_request;
    final result = await ref
        .read(emiRepositoryProvider)
        .getQuote(
          variantId: _variantId,
          downPaymentPercent: _percent,
          tenureMonths: _tenure,
        );
    if (!mounted || request != _request) return;
    setState(() => _quote = result.fold((_) => null, (q) => q));
  }

  void _select({_Kind? kind, int? percent, int? tenure}) {
    setState(() {
      if (kind != null && !identical(kind, _kind)) {
        _kind = kind;
        _percent = kind.minPercent;
        _tenure = kind.option.tenures.last;
      }
      _percent = percent ?? _percent;
      _tenure = tenure ?? _tenure;
      _quote = null;
      _error = null;
      _applyKey = _uuid.v4();
      _request++;
    });
    _scheduleQuote();
  }

  Future<void> _openKyc() async {
    await context.push(RouteNames.customerKyc);
    // Back at checkout: read the buyer's standing again.
    if (mounted) ref.invalidate(emiEligibilityProvider);
  }

  Future<void> _signIn() async {
    final signedIn = await ensureAuth(context, ref, reason: AuthReason.general);
    if (signedIn && mounted) ref.invalidate(emiEligibilityProvider);
  }

  /// Quote → apply → plan checkout (where the down payment is paid online).
  Future<void> _pay() async {
    final router = GoRouter.of(context);
    setState(() {
      _paying = true;
      _error = null;
    });
    final repo = ref.read(creditRepositoryProvider);
    final quoted = await repo.createQuote(
      variantId: _variantId,
      kind: _kind.kind,
      downPaymentPercent: _kind.adjustable ? _percent : null,
      tenureMonths: _tenure,
    );
    if (!mounted) return;
    final quote = quoted.fold((f) {
      setState(() {
        _paying = false;
        _error = creditFailureMessage(f);
      });
      return null;
    }, (q) => q);
    if (quote == null) return;

    final applied = await repo.apply(
      quoteToken: quote.token,
      idempotencyKey: _applyKey,
    );
    if (!mounted) return;
    applied.fold(
      (f) => setState(() {
        _paying = false;
        _error = creditFailureMessage(f);
      }),
      (agreement) {
        refreshPaymentPlans(ref);
        final args = PlanDetailArgs(
          productName: widget.item.productName,
          justApplied: true,
        );
        switch (agreement.status) {
          case AgreementStatus.approved:
            setState(() => _paying = false);
            unawaited(
              router.push(
                RouteNames.paymentPlanCheckoutPath(agreement.id),
                extra: args,
              ),
            );
          case AgreementStatus.declined:
            setState(() {
              _paying = false;
              _error = agreement.reasons.isEmpty
                  ? 'This plan was not approved.'
                  : 'Not approved: '
                        '${agreement.reasons.map(reasonForBuyer).join(' ')}';
            });
          case AgreementStatus.pendingApproval ||
              AgreementStatus.active ||
              AgreementStatus.completed ||
              AgreementStatus.defaulted ||
              AgreementStatus.cancelled ||
              AgreementStatus.expired ||
              AgreementStatus.reversed:
            // Sent to the seller (a real risk reason), or anything else: the
            // plan's own screen says where it stands and what comes next.
            setState(() => _paying = false);
            unawaited(
              router.push(
                RouteNames.paymentPlanDetailPath(agreement.id),
                extra: args,
              ),
            );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.options.price;
    final local = EmiPlan.compute(
      price: price,
      downPaymentPercent: _percent,
      tenureMonths: _tenure,
    );
    final quote = _quote;
    final confirmed =
        _kind.kind == PlanKind.instalment &&
        quote != null &&
        quote.matches(
          variantId: _variantId,
          downPaymentPercent: _percent,
          tenureMonths: _tenure,
        );
    final down = confirmed ? quote.downPayment : local.downPayment;
    final monthly = confirmed
        ? quote.monthlyInstallment
        : local.monthlyInstallment;
    final total = confirmed ? quote.totalPayable : local.totalPayable;

    final title = widget.named
        ? 'Pay with EMI · ${widget.item.productName}'
        : 'Pay with EMI';

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
      child: Container(
        key: widget.named
            ? ValueKey('checkout-emi-card-${widget.item.variantId}')
            : CheckoutEmiOption.cardKey,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.primaryGreenDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: DesignTokens.primaryGreen,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
              ],
            ),
            if (_kinds.length > 1) ...[
              const SizedBox(height: DesignTokens.s12),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: [
                  for (final k in _kinds)
                    ChoiceChip(
                      key: Key('checkout-emi-kind-${k.kind.name}'),
                      label: Text(k.kind.label),
                      selected: identical(k, _kind),
                      selectedColor: DesignTokens.chipsSelectedFill,
                      onSelected: (_) => _select(kind: k),
                    ),
                ],
              ),
            ],
            const SizedBox(height: DesignTokens.s12),
            const _Label('Months'),
            const SizedBox(height: DesignTokens.s6),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                for (final months in _kind.option.tenures)
                  ChoiceChip(
                    key: Key('checkout-emi-tenure-$months'),
                    label: Text('$months months'),
                    selected: months == _tenure,
                    selectedColor: DesignTokens.chipsSelectedFill,
                    onSelected: (_) => _select(tenure: months),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                Expanded(
                  child: _Label(
                    _kind.adjustable
                        ? 'Down payment $_percent% (min ${_kind.minPercent}%)'
                        : 'Down payment $_percent%',
                  ),
                ),
                if (_kind.adjustable) ...[
                  IconButton(
                    key: const Key('checkout-emi-down-minus'),
                    tooltip: 'Lower down payment',
                    color: DesignTokens.textWhite,
                    onPressed: _percent - emiDownPaymentStep >= _kind.minPercent
                        ? () => _select(percent: _percent - emiDownPaymentStep)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    key: const Key('checkout-emi-down-plus'),
                    tooltip: 'Raise down payment',
                    color: DesignTokens.textWhite,
                    onPressed: _percent + emiDownPaymentStep <= _kind.maxPercent
                        ? () => _select(percent: _percent + emiDownPaymentStep)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ],
            ),
            _Figure(
              key: const Key('checkout-emi-down'),
              label: 'Down payment now',
              value: _money(down),
            ),
            _Figure(
              key: const Key('checkout-emi-monthly'),
              label: 'Then monthly',
              value: '${_money(monthly)} × $_tenure',
              emphasised: true,
            ),
            _Figure(
              key: const Key('checkout-emi-total'),
              label: 'Total',
              value: _money(total),
            ),
            const SizedBox(height: DesignTokens.s12),
            _Cta(
              requiresVerification: _kind.option.requiresVerifiedIdentity,
              downPayment: down,
              paying: _paying,
              onPay: _pay,
              onVerify: _openKyc,
              onSignIn: _signIn,
            ),
            if (_error != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                _error!,
                key: const Key('checkout-emi-pay-error'),
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.colorError,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Whole rupees without decimals, anything else with two.
String _money(Money money) => formatMoney(
  money,
  decimalDigits: money.amount == money.amount.roundToDouble() ? 0 : 2,
);

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: DesignTokens.textWhite,
    ),
  );
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.emphasised = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: emphasised ? 15 : 13,
            fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
            color: emphasised
                ? DesignTokens.primaryGreen
                : DesignTokens.textWhite,
          ),
        ),
      ],
    ),
  );
}

/// The card's button: sign in → get verified → in review → pay.
class _Cta extends ConsumerWidget {
  const _Cta({
    required this.requiresVerification,
    required this.downPayment,
    required this.paying,
    required this.onPay,
    required this.onVerify,
    required this.onSignIn,
  });

  final bool requiresVerification;
  final Money downPayment;
  final bool paying;
  final VoidCallback onPay;
  final VoidCallback onVerify;
  final VoidCallback onSignIn;

  Widget _payButton() => _Button(
    key: CheckoutEmiOption.payKey,
    label: paying
        ? 'Preparing your plan…'
        : 'Pay down payment ${_money(downPayment)} with EMI',
    onPressed: paying ? null : onPay,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(emiSignedInProvider)) {
      return _Button(label: 'Sign in to pay with EMI', onPressed: onSignIn);
    }
    if (!requiresVerification) return _payButton();

    return ref
        .watch(emiEligibilityProvider)
        .when(
          loading: () => const _Button(
            label: 'Checking your verification…',
            onPressed: null,
          ),
          error: (_, _) => _Button(
            label: 'Could not check your verification — try again',
            outlined: true,
            onPressed: () => ref.invalidate(emiEligibilityProvider),
          ),
          data: (value) => switch (value.cta) {
            EmiCta.eligible => _payButton(),
            EmiCta.inReview => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your verification is in review. You can pay with EMI as '
                  'soon as it is approved — we will let you know.',
                  key: CheckoutEmiOption.inReviewKey,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                _Button(
                  label: 'Verification in review',
                  outlined: true,
                  onPressed: onVerify,
                ),
              ],
            ),
            EmiCta.signIn || EmiCta.getVerified => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'EMI needs a verified identity. It takes a few minutes, '
                  'and you come straight back here.',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                _Button(
                  key: CheckoutEmiOption.verifyKey,
                  label: 'Get verified to pay with EMI',
                  onPressed: onVerify,
                ),
              ],
            ),
          },
        );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Text(label, textAlign: TextAlign.center);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
    );
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.primaryGreen,
                side: const BorderSide(color: DesignTokens.primaryGreen),
                shape: shape,
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.buttonPrimaryFill,
                foregroundColor: DesignTokens.buttonPrimaryText,
                disabledBackgroundColor: DesignTokens.buttonGrayFill,
                disabledForegroundColor: DesignTokens.buttonGrayText,
                shape: shape,
              ),
              child: child,
            ),
    );
  }
}
