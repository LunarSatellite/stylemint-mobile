import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The one display moment in the post-purchase journey.
///
/// It used to fire a ten-colour confetti burst on a forever-repeating ticker,
/// and it fired the same burst whether the money had actually moved or not.
/// Both are gone. A confirmed order gets a single green bloom that plays once
/// and settles; a payment that has not completed gets the caution tone, a
/// clock, and copy that does not congratulate anyone. What follows is the same
/// on both: the order number, and the four stages of what happens next, so the
/// buyer leaves this screen oriented rather than merely pleased.
class OrderSuccessScreen extends StatefulWidget {
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

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DesignTokens.motionSlow * 2,
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // The bloom plays once, and not at all when the platform says no motion.
    if (!MallMetrics.reduceMotion(context)) {
      _controller.value = 0;
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _pending => widget.paymentPending;

  MallStatusTone get _tone =>
      _pending ? MallStatusTone.caution : MallStatusTone.success;

  String get _title => _pending ? 'Almost there' : 'Thank you';

  String get _lead => _pending
      ? 'Your order is placed. Finish the payment to confirm it.'
      : 'Your order is confirmed.';

  String get _body => _pending
      ? "We've sent you to your payment provider. Nothing has been charged "
            'yet — once the payment clears, this order moves to Confirmed and '
            'you can track it from Order History.'
      : 'You can follow every stage from Order History, and we will tell you '
            'when it is out for delivery.';

  List<MallTimelineStep> get _nextSteps => [
    MallTimelineStep(
      title: _pending ? 'Placed' : 'Confirmed',
      state: _pending ? MallStepState.current : MallStepState.done,
    ),
    MallTimelineStep(
      title: 'Packed',
      state: _pending ? MallStepState.upcoming : MallStepState.current,
    ),
    const MallTimelineStep(title: 'Shipped', state: MallStepState.upcoming),
    const MallTimelineStep(title: 'Delivered', state: MallStepState.upcoming),
  ];

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(height: DesignTokens.s28),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: MallStatusStepper(
                        steps: _nextSteps,
                        semanticLabel: 'What happens next',
                      ),
                    ),
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
                      label: 'View order',
                      onPressed: () => context.pushReplacement(
                        RouteNames.orderDetail.replaceAll(
                          ':orderId',
                          widget.orderId,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.go(RouteNames.home),
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
                      child: const Text('Keep shopping'),
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
    final glyph = tone == MallStatusTone.success
        ? Icons.check_rounded
        : Icons.hourglass_bottom_rounded;
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
