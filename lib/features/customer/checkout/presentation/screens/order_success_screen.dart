import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Where an order shown on [OrderSuccessScreen] stands.
enum OrderSuccessPhase {
  /// Sent to the payment provider; the server has not seen the payment yet.
  awaitingPayment,

  /// Still unpaid after the whole polling window. The buyer can ask again.
  stillAwaitingPayment,

  /// Paid (or Cash on Delivery): the order is placed and with the seller.
  confirmed,

  /// The payment failed or was abandoned and the server cancelled the order.
  paymentFailed,
}

/// The one display moment in the post-purchase journey.
///
/// It used to fire a ten-colour confetti burst on a forever-repeating ticker,
/// and it fired the same burst whether the money had actually moved or not.
/// Both are gone. A confirmed order gets a single green bloom that plays once
/// and settles; a payment that has not completed gets the caution tone, a
/// clock, and copy that does not congratulate anyone. What follows is the same
/// on both: the order number, and the four stages of what happens next, so the
/// buyer leaves this screen oriented rather than merely pleased.
///
/// An online payment (eSewa, card, PayPal) is not an order until it is paid:
/// the server creates the order at Place Order but only releases it to the
/// seller once the payment clears, and cancels it when the payment fails. So
/// while [paymentPending] this screen never calls the order placed. It
/// re-reads the order every [pollInterval] for [pollWindow], and again
/// whenever the app comes back to the foreground (the buyer returning from
/// the payment page), and moves to the confirmed view once the order is paid
/// — or to "Payment didn't go through" once the server has cancelled it.
class OrderSuccessScreen extends ConsumerStatefulWidget {
  const OrderSuccessScreen({
    required this.orderId,
    super.key,
    this.paymentPending = false,
  });

  // Despite the name, this is the order NUMBER (e.g. "NK2026-00001") from
  // PlaceOrderState.success — every order route (detail/invoice/cancel) is
  // keyed by that, not the internal orderId GUID.
  final String orderId;

  // True for PayPal/eSewa/Card orders: the customer was just sent to the
  // provider's payment page but hasn't necessarily finished it — the order
  // exists but isn't paid yet, so this screen must not claim it is.
  final bool paymentPending;

  /// How often an unpaid order is re-read.
  static const pollInterval = Duration(seconds: 3);

  /// How long it is re-read before the screen stops and offers "Check again".
  static const pollWindow = Duration(minutes: 3);

  /// What a freshly read order means for this screen; null while the payment
  /// is still outstanding.
  static OrderSuccessPhase? phaseFor(OrderTrackStatus status) =>
      switch (status) {
        OrderTrackStatus.awaitingPayment => null,
        OrderTrackStatus.cancelled => OrderSuccessPhase.paymentFailed,
        // Paid, or anything after it: the order is placed.
        OrderTrackStatus.preparingForShipping ||
        OrderTrackStatus.inTransit ||
        OrderTrackStatus.outForDelivery ||
        OrderTrackStatus.delivered => OrderSuccessPhase.confirmed,
      };

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late OrderSuccessPhase _phase;
  bool _started = false;

  Timer? _pollTimer;
  Timer? _windowTimer;
  bool _checking = false;

  /// The provider's name once the order has been read ("eSewa", "Card",
  /// "PayPal"); null until then, when the copy stays method-neutral.
  String? _method;

  @override
  void initState() {
    super.initState();
    _phase = widget.paymentPending
        ? OrderSuccessPhase.awaitingPayment
        : OrderSuccessPhase.confirmed;
    _controller = AnimationController(
      vsync: this,
      duration: DesignTokens.motionSlow * 2,
      value: 1,
    );
    if (_awaiting) {
      WidgetsBinding.instance.addObserver(this);
      _startPolling();
    }
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
    if (_phase == OrderSuccessPhase.stillAwaitingPayment) {
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
      _phase == OrderSuccessPhase.awaitingPayment ||
      _phase == OrderSuccessPhase.stillAwaitingPayment;

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
    if (_phase == OrderSuccessPhase.stillAwaitingPayment) {
      setState(() => _phase = OrderSuccessPhase.awaitingPayment);
    }
    _pollTimer = Timer.periodic(
      OrderSuccessScreen.pollInterval,
      (_) => unawaited(_check()),
    );
    _windowTimer = Timer(OrderSuccessScreen.pollWindow, () {
      _stopPolling();
      if (!mounted || _phase != OrderSuccessPhase.awaitingPayment) return;
      setState(() => _phase = OrderSuccessPhase.stillAwaitingPayment);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _windowTimer?.cancel();
    _windowTimer = null;
  }

  /// Reads the order once. A failed read changes nothing: the next tick, or
  /// the buyer's "Check again", asks again.
  Future<void> _check() async {
    if (_checking || !_awaiting) return;
    _checking = true;
    try {
      final result = await ref
          .read(ordersRepositoryProvider)
          .getOrderDetail(widget.orderId);
      if (!mounted || !_awaiting) return;
      result.fold((_) {}, (order) {
        final next = OrderSuccessScreen.phaseFor(order.status);
        final method = order.paymentMethod.trim();
        if (next == null) {
          if (method.isNotEmpty && method != _method) {
            setState(() => _method = method);
          }
          return;
        }
        _stopPolling();
        setState(() {
          _phase = next;
          if (method.isNotEmpty) _method = method;
        });
        _playBloom();
        // The server keeps the cart until an online payment clears, then takes
        // the bought items out (paid) or leaves them (failed): show it as it is.
        if (ref.exists(cartNotifierProvider)) {
          unawaited(ref.read(cartNotifierProvider.notifier).fetchCart());
        }
      });
    } finally {
      _checking = false;
    }
  }

  void _checkAgain() {
    _startPolling();
    unawaited(_check());
  }

  MallStatusTone get _tone => switch (_phase) {
    OrderSuccessPhase.awaitingPayment ||
    OrderSuccessPhase.stillAwaitingPayment => MallStatusTone.caution,
    OrderSuccessPhase.confirmed => MallStatusTone.success,
    OrderSuccessPhase.paymentFailed => MallStatusTone.danger,
  };

  String get _title => switch (_phase) {
    OrderSuccessPhase.awaitingPayment ||
    OrderSuccessPhase.stillAwaitingPayment => 'Waiting for your payment',
    OrderSuccessPhase.confirmed => 'Thank you',
    OrderSuccessPhase.paymentFailed => "Payment didn't go through",
  };

  String get _lead => switch (_phase) {
    OrderSuccessPhase.awaitingPayment ||
    OrderSuccessPhase.stillAwaitingPayment =>
      _method == null
          ? "Complete the payment — your order is placed as soon as it's paid."
          : 'Complete the payment in $_method — your order is placed as '
                "soon as it's paid.",
    OrderSuccessPhase.confirmed => 'Your order is confirmed.',
    OrderSuccessPhase.paymentFailed =>
      'Your order was not placed and you were not charged.',
  };

  String get _body => switch (_phase) {
    OrderSuccessPhase.awaitingPayment =>
      'Nothing has been charged yet. This page updates by itself once the '
          'payment clears.',
    OrderSuccessPhase.stillAwaitingPayment =>
      "We haven't heard back about the payment yet. If you finished paying, "
          'it can take a few minutes — check again, or find this order in My '
          'orders.',
    OrderSuccessPhase.confirmed =>
      'You can follow every stage from Order History, and we will tell you '
          'when it is out for delivery.',
    OrderSuccessPhase.paymentFailed =>
      'Nothing was sent to the seller. You can go back to your cart and '
          'check out again.',
  };

  List<MallTimelineStep> get _nextSteps {
    final paid = _phase == OrderSuccessPhase.confirmed;
    return [
      MallTimelineStep(
        title: paid ? 'Confirmed' : 'Paid',
        state: paid ? MallStepState.done : MallStepState.current,
      ),
      MallTimelineStep(
        title: 'Packed',
        state: paid ? MallStepState.current : MallStepState.upcoming,
      ),
      const MallTimelineStep(title: 'Shipped', state: MallStepState.upcoming),
      const MallTimelineStep(title: 'Delivered', state: MallStepState.upcoming),
    ];
  }

  ({String label, VoidCallback onPressed}) get _primaryAction =>
      switch (_phase) {
        OrderSuccessPhase.awaitingPayment ||
        OrderSuccessPhase.confirmed => (
          label: 'View order',
          onPressed: () => context.pushReplacement(
            RouteNames.orderDetail.replaceAll(':orderId', widget.orderId),
          ),
        ),
        OrderSuccessPhase.stillAwaitingPayment => (
          label: 'Check again',
          onPressed: _checkAgain,
        ),
        // There is no pay-again endpoint for a cancelled order: the way to
        // try again is a fresh checkout.
        OrderSuccessPhase.paymentFailed => (
          label: 'Back to cart',
          onPressed: () => context.go(RouteNames.cart),
        ),
      };

  ({String label, VoidCallback onPressed}) get _secondaryAction =>
      switch (_phase) {
        OrderSuccessPhase.stillAwaitingPayment => (
          label: 'View my orders',
          onPressed: () => context.go(RouteNames.orders),
        ),
        OrderSuccessPhase.awaitingPayment ||
        OrderSuccessPhase.confirmed ||
        OrderSuccessPhase.paymentFailed => (
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
                    _SuccessMark(tone: _tone, progress: _controller),
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
                    const SizedBox(height: DesignTokens.s24),
                    _OrderNumberPlate(orderNumber: widget.orderId),
                    // A cancelled order has nothing next to show.
                    if (_phase != OrderSuccessPhase.paymentFailed) ...[
                      const SizedBox(height: DesignTokens.s28),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: MallStatusStepper(
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
                  SizedBox(
                    width: double.infinity,
                    child: MallPrimaryCta(
                      label: primary.label,
                      onPressed: primary.onPressed,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
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

/// The order number, set once, large enough to read aloud down a phone line
/// and in tabular figures so the digits do not dance.
class _OrderNumberPlate extends StatelessWidget {
  const _OrderNumberPlate({required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Order number $orderNumber',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MallEyebrow('Order number'),
            const SizedBox(height: 2),
            Text(
              orderNumber,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
                letterSpacing: 0.4,
                color: DesignTokens.textWhite,
                fontFeatures: mallTabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One mark, one accent. Concentric rings bloom outward once and settle; the
/// glyph itself never moves, so the state is readable from the first frame
/// whether or not animation ran.
class _SuccessMark extends StatelessWidget {
  const _SuccessMark({required this.tone, required this.progress});

  final MallStatusTone tone;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final style = mallStatusStyle(tone);
    final glyph = switch (tone) {
      MallStatusTone.success => Icons.check_rounded,
      MallStatusTone.danger => Icons.close_rounded,
      MallStatusTone.neutral ||
      MallStatusTone.info ||
      MallStatusTone.progress ||
      MallStatusTone.caution => Icons.hourglass_bottom_rounded,
    };
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 196,
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(
              progress.value.clamp(0.0, 1.0),
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                _Ring(diameter: 196, scale: t, opacity: 0.14 * t, tone: tone),
                _Ring(diameter: 148, scale: t, opacity: 0.26 * t, tone: tone),
                child!,
              ],
            );
          },
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: style.foreground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              glyph,
              size: 52,
              color: tone == MallStatusTone.success
                  ? DesignTokens.buttonPrimaryText
                  : DesignTokens.bgAppFoundation,
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.diameter,
    required this.scale,
    required this.opacity,
    required this.tone,
  });

  final double diameter;
  final double scale;
  final double opacity;
  final MallStatusTone tone;

  @override
  Widget build(BuildContext context) {
    // The accent itself at a low alpha, not the tonal fill: against the app
    // foundation a dark fill would simply not be there.
    final fill = mallStatusStyle(tone).foreground;
    return Transform.scale(
      scale: 0.7 + 0.3 * scale,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: SizedBox.square(
          dimension: diameter,
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
