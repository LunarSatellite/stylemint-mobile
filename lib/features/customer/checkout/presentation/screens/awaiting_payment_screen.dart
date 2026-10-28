import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/order_success_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Where the buyer stands on [AwaitingPaymentScreen].
enum AwaitingPaymentPhase {
  /// Sent to the payment provider; the server has not seen the payment yet.
  waiting,

  /// Still nothing after the whole polling window. The buyer can ask again.
  stillWaiting,

  /// The payment failed, was abandoned, or its hold lapsed. No order exists.
  failed,
}

/// "Waiting for your payment", after Place Order with an online method.
///
/// Order only after payment (contract v1.0, 2026-10-28): for eSewa, card,
/// PayPal or connectIPS the server creates **no order** until the payment
/// succeeds, so there is no order to show yet — only the checkout session,
/// which this screen is keyed by. It re-reads the session every
/// [pollInterval] for [pollWindow], and again whenever the app comes back to
/// the foreground (the buyer returning from the payment page). Once the
/// session reads Placed with an order number it moves on to the order-success
/// screen for that order, confirmed. Once it reads Failed or Expired it says
/// the payment didn't go through and leads back to the cart, which the
/// server left as it was.
///
/// Cash on delivery, payment plans, and a server from before the change (whose
/// Place Order reply still names an order) never come here: they go straight
/// to the order-success screen as before.
class AwaitingPaymentScreen extends ConsumerStatefulWidget {
  const AwaitingPaymentScreen({required this.checkoutSessionId, super.key});

  /// The checkout session that was placed and is waiting for its payment.
  final String checkoutSessionId;

  /// How often the session is re-read.
  /// One second: the buyer is looking at this screen, and the order appears a
  /// few seconds after the payment; each read is one small request.
  static const pollInterval = Duration(seconds: 1);

  /// How long it is re-read before the screen stops and offers "Check again".
  static const pollWindow = Duration(minutes: 3);

  @override
  ConsumerState<AwaitingPaymentScreen> createState() =>
      _AwaitingPaymentScreenState();
}

class _AwaitingPaymentScreenState extends ConsumerState<AwaitingPaymentScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  AwaitingPaymentPhase _phase = AwaitingPaymentPhase.waiting;
  bool _started = false;

  Timer? _pollTimer;
  Timer? _windowTimer;
  bool _checking = false;

  /// Set once the order exists and the screen is on its way to it, so no
  /// later read or tap navigates a second time.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DesignTokens.motionSlow * 2,
      value: 1,
    );
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _playBloom();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the payment page: ask at once rather than at the next tick,
    // and give a lapsed window another round.
    if (state != AppLifecycleState.resumed || !_awaiting) return;
    if (_phase == AwaitingPaymentPhase.stillWaiting) {
      _startPolling();
    }
    unawaited(_check());
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  bool get _awaiting =>
      !_leaving &&
      (_phase == AwaitingPaymentPhase.waiting ||
          _phase == AwaitingPaymentPhase.stillWaiting);

  /// The bloom plays once per settled state, and not at all when the
  /// platform says no motion.
  void _playBloom() {
    if (MallMetrics.reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    _controller.value = 0;
    unawaited(_controller.forward());
  }

  void _startPolling() {
    _stopPolling();
    if (_phase == AwaitingPaymentPhase.stillWaiting) {
      setState(() => _phase = AwaitingPaymentPhase.waiting);
    }
    _pollTimer = Timer.periodic(
      AwaitingPaymentScreen.pollInterval,
      (_) => unawaited(_check()),
    );
    _windowTimer = Timer(AwaitingPaymentScreen.pollWindow, () {
      _stopPolling();
      if (!mounted || _phase != AwaitingPaymentPhase.waiting) return;
      setState(() => _phase = AwaitingPaymentPhase.stillWaiting);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _windowTimer?.cancel();
    _windowTimer = null;
  }

  /// Reads the session once. A failed read changes nothing: the next tick, or
  /// the buyer's "Check again", asks again.
  Future<void> _check() async {
    if (_checking || !_awaiting) return;
    _checking = true;
    try {
      final result = await ref
          .read(checkoutRepositoryProvider)
          .getCheckoutSession(widget.checkoutSessionId);
      if (!mounted || !_awaiting) return;
      result.fold((_) {}, _settle);
    } finally {
      _checking = false;
    }
  }

  void _settle(CheckoutSessionProgress session) {
    final orderNumber = session.orderNumber;
    if (session.isPlaced && orderNumber != null) {
      _stopPolling();
      _leaving = true;
      // The server takes the bought items out of the cart once the order is
      // paid: show the cart as it now is.
      if (ref.exists(cartNotifierProvider)) {
        unawaited(ref.read(cartNotifierProvider.notifier).fetchCart());
      }
      // Paid, so the order-success screen opens confirmed (no
      // paymentPending): the order exists only because the payment cleared.
      context.go(
        RouteNames.orderSuccess.replaceAll(
          ':orderId',
          Uri.encodeComponent(orderNumber),
        ),
      );
      return;
    }
    if (session.isFailed) {
      _stopPolling();
      setState(() => _phase = AwaitingPaymentPhase.failed);
      _playBloom();
    }
    // Anything else (AwaitingPayment, Placing, Placed without its number yet,
    // or a status this build cannot read): still waiting.
  }

  void _checkAgain() {
    _startPolling();
    unawaited(_check());
  }

  MallStatusTone get _tone => switch (_phase) {
    AwaitingPaymentPhase.waiting ||
    AwaitingPaymentPhase.stillWaiting => MallStatusTone.caution,
    AwaitingPaymentPhase.failed => MallStatusTone.danger,
  };

  String get _title => switch (_phase) {
    AwaitingPaymentPhase.waiting ||
    AwaitingPaymentPhase.stillWaiting => 'Waiting for your payment',
    AwaitingPaymentPhase.failed => "Payment didn't go through",
  };

  String get _lead => switch (_phase) {
    AwaitingPaymentPhase.waiting || AwaitingPaymentPhase.stillWaiting =>
      "Complete the payment — your order is placed as soon as it's paid.",
    AwaitingPaymentPhase.failed =>
      'No order was placed and you were not charged.',
  };

  String get _body => switch (_phase) {
    AwaitingPaymentPhase.waiting =>
      'Nothing has been charged yet. This page updates by itself once the '
          'payment clears.',
    AwaitingPaymentPhase.stillWaiting =>
      "We haven't heard back about the payment yet. If you finished paying, "
          'it can take a few minutes — check again, and your order appears '
          'in My orders once it is paid.',
    AwaitingPaymentPhase.failed =>
      'Nothing was sent to the seller, and your cart is as you left it. You '
          'can go back to it and check out again.',
  };

  static const List<MallTimelineStep> _nextSteps = [
    MallTimelineStep(title: 'Paid', state: MallStepState.current),
    MallTimelineStep(title: 'Packed', state: MallStepState.upcoming),
    MallTimelineStep(title: 'Shipped', state: MallStepState.upcoming),
    MallTimelineStep(title: 'Delivered', state: MallStepState.upcoming),
  ];

  void _backToCart() => context.go(RouteNames.cart);

  /// The filled button, if this phase has one.
  ({String label, VoidCallback onPressed})? get _primaryAction =>
      switch (_phase) {
        // Nothing to do here but pay on the provider's page; this page
        // follows the payment by itself.
        AwaitingPaymentPhase.waiting => null,
        AwaitingPaymentPhase.stillWaiting => (
          label: 'Check again',
          onPressed: _checkAgain,
        ),
        // No order was created, so the way to try again is a fresh checkout.
        AwaitingPaymentPhase.failed => (
          label: 'Back to cart',
          onPressed: _backToCart,
        ),
      };

  ({String label, VoidCallback onPressed}) get _secondaryAction =>
      switch (_phase) {
        AwaitingPaymentPhase.waiting || AwaitingPaymentPhase.stillWaiting => (
          label: 'Back to cart',
          onPressed: _backToCart,
        ),
        AwaitingPaymentPhase.failed => (
          label: 'Keep shopping',
          onPressed: () => context.go(RouteNames.home),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final primary = _primaryAction;
    final secondary = _secondaryAction;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s24,
                  vertical: DesignTokens.s32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OrderOutcomeMark(tone: _tone, progress: _controller),
                    const SizedBox(height: DesignTokens.s32),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: DesignTokens.displayTitle,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      _lead,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    Text(
                      _body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        height: 1.55,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    // No order exists after a failed payment: nothing next.
                    if (_phase != AwaitingPaymentPhase.failed) ...[
                      const SizedBox(height: DesignTokens.s28),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: const MallStatusStepper(
                          steps: _nextSteps,
                          semanticLabel: 'What happens next',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s24,
              ),
              decoration: const BoxDecoration(
                color: DesignTokens.bgAppFoundation,
                border: Border(
                  top: BorderSide(color: DesignTokens.borderDefault),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (primary != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: MallPrimaryCta(
                        label: primary.label,
                        onPressed: primary.onPressed,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: secondary.onPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: DesignTokens.textLight,
                        backgroundColor: DesignTokens.bgAppBodyLight,
                        minimumSize: const Size(
                          DesignTokens.minTouchTarget,
                          48,
                        ),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(secondary.label),
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
