import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/emi_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/product_emi_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/plan_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Opens the payment-plan sheet for one variant: phase 1's EMI calculator,
/// plus pay later and pay-now-buy-later when [planOptions] offers them.
Future<void> showEmiCalculatorSheet(
  BuildContext context, {
  required String productId,
  required String productName,
  required String variantId,
  required Money price,
  ProductEmiOffer? offer,
  List<PlanOption> planOptions = const <PlanOption>[],
  PlanKind? initialKind,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: DesignTokens.bgAppBodyLight,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => EmiCalculatorSheet(
    productId: productId,
    productName: productName,
    variantId: variantId,
    price: price,
    offer: offer,
    planOptions: planOptions,
    initialKind: initialKind,
  ),
);

/// Whole rupees without decimals, anything else with two.
String _money(Money money) => formatMoney(
  money,
  decimalDigits: money.amount == money.amount.roundToDouble() ? 0 : 2,
);

/// The EMI calculator: a down-payment slider (the vendor's effective minimum
/// to 90 %, in 5 % steps), the tenures on offer, and what that means month by
/// month.
///
/// The numbers are worked out on the device the moment anything moves, with
/// the contract's rounding ([EmiPlan]), then confirmed by `GET /v1/emi/quote`
/// once the buyer stops dragging. When the server's quote arrives it is what
/// the sheet shows — the server is the authority, the local figures are only
/// there so the slider never waits on a round trip.
///
/// Pay later and pay-now-buy-later, when the seller offers them, sit beside
/// EMI as further kinds of plan ([planOptions], from `/v1/credit/offers`).
/// Their figures are the same arithmetic on the device; the server prices
/// them for real when the buyer continues.
///
/// The button at the bottom gets a buyer signed in and verified, then asks
/// the server for a signed quote and opens its review. Nothing is agreed in
/// this sheet.
class EmiCalculatorSheet extends ConsumerStatefulWidget {
  const EmiCalculatorSheet({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.price,
    this.offer,
    this.planOptions = const <PlanOption>[],
    this.initialKind,
    this.quoteDebounce = const Duration(milliseconds: 400),
    super.key,
  });

  final String productId;
  final String productName;
  final String variantId;
  final Money price;

  /// Phase 1's EMI terms from the product payload, when it carried them.
  final ProductEmiOffer? offer;

  /// Every plan the Credit module offers on this variant. May be empty (an
  /// older server); EMI then runs on [offer] alone.
  final List<PlanOption> planOptions;
  final PlanKind? initialKind;

  /// How long the selection must sit still before the server is asked.
  final Duration quoteDebounce;

  @override
  ConsumerState<EmiCalculatorSheet> createState() => _EmiCalculatorSheetState();
}

/// One kind's choices: the down-payment range and the tenures.
class _KindTerms {
  const _KindTerms({
    required this.kind,
    required this.minPercent,
    required this.maxPercent,
    required this.tenures,
    required this.requiresVerification,
    this.option,
  });

  final PlanKind kind;
  final int minPercent;
  final int maxPercent;
  final List<int> tenures;
  final bool requiresVerification;
  final PlanOption? option;

  bool get fixed => minPercent >= maxPercent;
  int get longestTenure => tenures.isEmpty ? 0 : tenures.last;
}

class _EmiCalculatorSheetState extends ConsumerState<EmiCalculatorSheet> {
  late final List<_KindTerms> _kinds = _buildKinds();
  late _KindTerms _terms = _kinds.firstWhere(
    (k) => k.kind == widget.initialKind,
    orElse: () => _kinds.first,
  );
  late int _percent = _terms.minPercent;
  late int _tenure = _terms.longestTenure;

  EmiQuote? _quote;
  EmiFailure? _quoteFailure;
  bool _confirming = false;
  Timer? _debounce;

  /// Bumped per request so a slow answer for an old selection is dropped.
  int _request = 0;

  /// Asking the server for a signed quote, after Continue.
  bool _continuing = false;
  EmiFailure? _continueFailure;

  bool get _isEmi => _terms.kind == PlanKind.instalment;

  /// EMI from phase 1's terms when the product carried them, else from the
  /// Credit module's option; then pay later and prepay from their options.
  List<_KindTerms> _buildKinds() {
    final kinds = <_KindTerms>[];
    final offer = widget.offer;
    final emiOption = _option(PlanKind.instalment);
    if (offer != null) {
      kinds.add(
        _KindTerms(
          kind: PlanKind.instalment,
          minPercent: offer.sliderMinPercent,
          maxPercent: emiMaxDownPaymentPercent,
          tenures: offer.tenures,
          requiresVerification: true,
          option: emiOption,
        ),
      );
    } else if (emiOption != null) {
      kinds.add(_fromOption(emiOption));
    }
    for (final kind in [PlanKind.payLater, PlanKind.prepay]) {
      final option = _option(kind);
      if (option != null) kinds.add(_fromOption(option));
    }
    return kinds;
  }

  PlanOption? _option(PlanKind kind) {
    for (final o in widget.planOptions) {
      if (o.kind == kind) return o;
    }
    return null;
  }

  static _KindTerms _fromOption(PlanOption o) => _KindTerms(
    kind: o.kind,
    minPercent: o.minDownPaymentPercent,
    maxPercent: o.downPaymentFixed
        ? o.minDownPaymentPercent
        : o.maxDownPaymentPercent,
    tenures: o.tenures,
    requiresVerification: o.requiresVerifiedIdentity,
    option: o,
  );

  @override
  void initState() {
    super.initState();
    if (_isEmi) _scheduleQuote();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleQuote() {
    _debounce?.cancel();
    if (!_isEmi) return;
    _debounce = Timer(widget.quoteDebounce, () => unawaited(_fetchQuote()));
  }

  Future<void> _fetchQuote() async {
    final request = ++_request;
    final percent = _percent;
    final tenure = _tenure;
    setState(() => _confirming = true);
    final result = await ref
        .read(emiRepositoryProvider)
        .getQuote(
          variantId: widget.variantId,
          downPaymentPercent: percent,
          tenureMonths: tenure,
        );
    if (!mounted || request != _request) return;
    setState(() {
      _confirming = false;
      result.fold(
        (failure) {
          _quote = null;
          _quoteFailure = failure;
        },
        (quote) {
          _quote = quote;
          _quoteFailure = null;
        },
      );
    });
  }

  void _select({int? percent, int? tenure}) {
    setState(() {
      _percent = percent ?? _percent;
      _tenure = tenure ?? _tenure;
      _continueFailure = null;
    });
    _scheduleQuote();
  }

  void _selectKind(_KindTerms terms) {
    if (identical(terms, _terms)) return;
    _debounce?.cancel();
    setState(() {
      _terms = terms;
      _percent = terms.minPercent;
      _tenure = terms.longestTenure;
      _quote = null;
      _quoteFailure = null;
      _confirming = false;
      _continueFailure = null;
      _request++;
    });
    _scheduleQuote();
  }

  /// Asks the server to price the selection and sign it, then hands over to
  /// the review. The router is captured before the sheet closes, since its
  /// context goes with it.
  Future<void> _continue() async {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _continuing = true;
      _continueFailure = null;
    });
    final result = await ref
        .read(creditRepositoryProvider)
        .createQuote(
          variantId: widget.variantId,
          kind: _terms.kind,
          downPaymentPercent: _terms.fixed ? null : _percent,
          tenureMonths: _tenure,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _continuing = false;
        _continueFailure = failure;
      }),
      (quote) {
        navigator.pop();
        unawaited(
          router.push(
            RouteNames.paymentPlanReview,
            extra: PlanReviewArgs(
              quote: quote,
              productName: widget.productName,
              productId: widget.productId,
              variantId: widget.variantId,
            ),
          ),
        );
      },
    );
  }

  /// `emi_quote.not_available`: the vendor switched EMI off, or this variant
  /// no longer qualifies. The plan is no longer on offer, so it is not shown.
  bool get _notAvailable {
    final failure = _quoteFailure;
    if (failure == null || !_isEmi) return false;
    return failure.code == 'emi_quote.not_available' || failure.isNotFound;
  }

  /// What is paid before the months begin, as the first schedule row.
  String get _upFrontLabel => switch (_terms.kind) {
    PlanKind.instalment => 'Down payment, to start',
    PlanKind.payLater => 'First payment, to start',
    PlanKind.prepay => 'Deposit, to start',
  };

  String get _percentLabel => switch (_terms.kind) {
    PlanKind.prepay => 'Deposit',
    PlanKind.payLater => 'First payment',
    PlanKind.instalment => 'Down payment',
  };

  @override
  Widget build(BuildContext context) {
    final terms = _terms;
    final local = EmiPlan.compute(
      price: widget.price,
      downPaymentPercent: _percent,
      tenureMonths: _tenure,
    );
    final quote = _quote;
    final confirmed =
        _isEmi &&
        quote != null &&
        quote.matches(
          variantId: widget.variantId,
          downPaymentPercent: _percent,
          tenureMonths: _tenure,
        );

    final downPayment = confirmed ? quote.downPayment : local.downPayment;
    final monthly = confirmed
        ? quote.monthlyInstallment
        : local.monthlyInstallment;
    final last = confirmed ? quote.lastInstallment : local.lastInstallment;
    final total = confirmed ? quote.totalPayable : local.totalPayable;
    final schedule = confirmed && quote.schedule.isNotEmpty
        ? [for (final i in quote.schedule) i.amount]
        : local.schedule;

    final steps = terms.fixed
        ? 0
        : (terms.maxPercent - terms.minPercent) ~/ emiDownPaymentStep;
    final sliderMax = terms.minPercent + steps * emiDownPaymentStep;
    final guarantor = terms.option?.guarantor;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.s20,
          DesignTokens.s12,
          DesignTokens.s20,
          DesignTokens.s20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              _kinds.length > 1
                  ? 'Pay over time'
                  : 'Pay in monthly instalments',
              style: DesignTokens.h3,
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              '${widget.productName} · ${_money(widget.price)}',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (_kinds.length > 1) ...[
              const SizedBox(height: DesignTokens.s16),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: [
                  for (final k in _kinds)
                    ChoiceChip(
                      key: Key('plan-kind-${k.kind.name}'),
                      label: Text(k.kind.label),
                      selected: identical(k, terms),
                      selectedColor: DesignTokens.chipsSelectedFill,
                      onSelected: (_) => _selectKind(k),
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                terms.kind.explainer,
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s20),
            if (_notAvailable)
              _Notice(
                icon: Icons.info_outline_rounded,
                text: emiQuoteMessage(_quoteFailure!),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _percentLabel,
                      style: DesignTokens.mediumSemibold,
                    ),
                  ),
                  Text(
                    '$_percent% · ${_money(downPayment)}',
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                ],
              ),
              if (steps > 0)
                Slider(
                  key: const Key('emi-down-payment-slider'),
                  value: _percent.toDouble(),
                  min: terms.minPercent.toDouble(),
                  max: sliderMax.toDouble(),
                  divisions: steps,
                  label: '$_percent%',
                  activeColor: DesignTokens.primaryGreen,
                  semanticFormatterCallback: (value) =>
                      '${value.round()} percent ${_percentLabel.toLowerCase()}',
                  onChanged: (value) {
                    final next = value.round();
                    if (next != _percent) _select(percent: next);
                  },
                )
              else
                const SizedBox(height: DesignTokens.s8),
              Text(
                terms.fixed
                    ? 'Set by the seller at ${terms.minPercent}% of the '
                          'price, paid to start the plan.'
                    : 'Between ${terms.minPercent}% and $sliderMax% of the '
                          'price, paid to start the plan.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s20),
              Text('Months', style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s8),
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: [
                  for (final months in terms.tenures)
                    ChoiceChip(
                      key: Key('emi-tenure-$months'),
                      label: Text('$months months'),
                      selected: months == _tenure,
                      selectedColor: DesignTokens.chipsSelectedFill,
                      onSelected: (_) => _select(tenure: months),
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.s20),
              _Summary(
                downPayment: downPayment,
                downPaymentLabel: _percentLabel,
                monthly: monthly,
                last: last,
                total: total,
                tenure: _tenure,
              ),
              const SizedBox(height: DesignTokens.s8),
              _QuoteStatus(
                confirming: _confirming,
                confirmed: confirmed,
                failure: _isEmi ? _quoteFailure : null,
              ),
              const SizedBox(height: DesignTokens.s16),
              Text('Payment schedule', style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s8),
              _ScheduleRow(label: _upFrontLabel, amount: downPayment),
              for (var i = 0; i < schedule.length; i++)
                _ScheduleRow(
                  label: 'Month ${i + 1}',
                  amount: schedule[i],
                ),
              if (terms.kind == PlanKind.prepay)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.s8),
                  child: Text(
                    'Your item is delivered after the last payment.',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
              const SizedBox(height: DesignTokens.s20),
              EmiCtaButton(
                requiresVerification: terms.requiresVerification,
                busy: _continuing,
                onContinue: _continue,
              ),
              if (_continueFailure != null) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(
                  creditFailureMessage(_continueFailure!),
                  key: const Key('plan-continue-error'),
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.colorError,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: DesignTokens.s12),
              Text(
                [
                  '0% interest: you pay the product price and nothing more.',
                  ?guarantor?.statement,
                ].join(' '),
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.downPayment,
    required this.downPaymentLabel,
    required this.monthly,
    required this.last,
    required this.total,
    required this.tenure,
  });

  final Money downPayment;
  final String downPaymentLabel;
  final Money monthly;
  final Money last;
  final Money total;
  final int tenure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        children: [
          _SummaryRow(label: downPaymentLabel, value: _money(downPayment)),
          _SummaryRow(
            key: const Key('emi-monthly'),
            label: 'Monthly',
            value: '${_money(monthly)} × ${tenure > 1 ? tenure - 1 : 1}',
            emphasised: true,
          ),
          if (tenure > 1)
            _SummaryRow(
              key: const Key('emi-last'),
              label: 'Last instalment',
              value: _money(last),
            ),
          const Divider(color: DesignTokens.borderDefault, height: 24),
          _SummaryRow(
            key: const Key('emi-total'),
            label: 'Total payable',
            value: _money(total),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasised = false,
    super.key,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final style = emphasised
        ? DesignTokens.mediumSemibold.copyWith(color: DesignTokens.primaryGreen)
        : DesignTokens.smallRegular;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: DesignTokens.smallRegular)),
          // Shrinks rather than truncates: an ellipsised amount reads as a
          // different number.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(value, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        Text(_money(amount), style: DesignTokens.smallRegular),
      ],
    ),
  );
}

/// Whether the figures on screen are the server's or still the device's.
class _QuoteStatus extends StatelessWidget {
  const _QuoteStatus({
    required this.confirming,
    required this.confirmed,
    required this.failure,
  });

  final bool confirming;
  final bool confirmed;
  final EmiFailure? failure;

  @override
  Widget build(BuildContext context) {
    final error = failure;
    final (icon, text) = confirmed && !confirming
        ? (Icons.verified_outlined, 'Confirmed by StyleMint')
        : confirming
        ? (Icons.sync_rounded, 'Checking with StyleMint…')
        : error != null
        ? (Icons.info_outline_rounded, emiQuoteMessage(error))
        : (Icons.calculate_outlined, 'Estimate');
    return Row(
      children: [
        Icon(icon, size: 16, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s6),
        Expanded(
          child: Text(
            text,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Row(
      children: [
        Icon(icon, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s12),
        Expanded(child: Text(text, style: DesignTokens.smallRegular)),
      ],
    ),
  );
}

/// The sheet's button. In order:
///
/// * signed out → sign in;
/// * for a plan that needs a verified identity, decided by
///   `GET /v1/customer/emi/eligibility`: `kyc_required` / `kyc_rejected` →
///   "Get verified" (the KYC flow), `kyc_in_review` → "Verification in
///   review" (the status screen);
/// * otherwise → "Continue", which asks the server for a signed quote.
///
/// Verification is checked here, before applying, so a buyer is sent to get
/// verified rather than declined for not being.
class EmiCtaButton extends ConsumerWidget {
  const EmiCtaButton({
    required this.onContinue,
    this.requiresVerification = true,
    this.busy = false,
    super.key,
  });

  final VoidCallback onContinue;
  final bool requiresVerification;
  final bool busy;

  static const signInLabel = 'Sign in to use payment plans';
  static const getVerifiedLabel = 'Get verified for payment plans';
  static const inReviewLabel = 'Verification in review';
  static const continueLabel = 'Continue';
  static const busyLabel = 'Preparing your plan…';

  /// Leaves the sheet for the verification screens. The router is captured
  /// before the sheet closes, since its context goes with it.
  void _openKyc(BuildContext context) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    unawaited(router.push(RouteNames.customerKyc));
  }

  Widget _continue() => _CtaButton(
    key: const Key('plan-continue'),
    label: busy ? busyLabel : continueLabel,
    onPressed: busy ? null : onContinue,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(emiSignedInProvider)) {
      return _CtaButton(
        label: signInLabel,
        onPressed: () async {
          final signedIn = await ensureAuth(
            context,
            ref,
            reason: AuthReason.general,
          );
          if (signedIn && context.mounted) {
            ref.invalidate(emiEligibilityProvider);
          }
        },
      );
    }

    if (!requiresVerification) return _continue();

    final eligibility = ref.watch(emiEligibilityProvider);
    return eligibility.when(
      loading: () => const _CtaButton(
        label: 'Checking your eligibility…',
        onPressed: null,
      ),
      error: (error, _) => _CtaButton(
        label: 'Could not check your eligibility — try again',
        outlined: true,
        onPressed: () => ref.invalidate(emiEligibilityProvider),
      ),
      data: (value) => switch (value.cta) {
        EmiCta.signIn || EmiCta.getVerified => _CtaButton(
          label: getVerifiedLabel,
          onPressed: () => _openKyc(context),
        ),
        EmiCta.inReview => _CtaButton(
          label: inReviewLabel,
          outlined: true,
          onPressed: () => _openKyc(context),
        ),
        EmiCta.eligible => _continue(),
      },
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
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
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.primaryGreen,
                side: const BorderSide(color: DesignTokens.primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                ),
              ),
              child: child,
            ),
    );
  }
}
