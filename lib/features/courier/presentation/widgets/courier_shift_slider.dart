import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_action_feedback.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Slide to go on shift — the control that decides whether parcels arrive.
///
/// This is the availability gate. It used to be the `Active` lifecycle state,
/// which nothing ever set: an approved courier sat with a working dashboard
/// and was never a candidate for any parcel, because advancing out of
/// Onboarded needed an operator pressing a button labelled for something
/// else. A rider saying "I am on shift" is both the honest signal and one
/// they control.
///
/// A slide rather than a tap, deliberately. Going off shift mid-run is
/// expensive — it stops offers and strands whatever was about to be routed to
/// this rider — and a phone in a jacket pocket on a motorbike is exactly the
/// environment where a single stray tap happens. A deliberate drag across
/// most of the track is hard to do by accident. The same gesture arms and
/// disarms, so there is one control and one habit rather than two.
///
/// It floats over the map, so it is translucent enough to show the streets
/// moving underneath and becomes more solid once the rider is online.
class CourierShiftSlider extends ConsumerStatefulWidget {
  const CourierShiftSlider({required this.profile, super.key});

  final CourierProfile profile;

  @override
  ConsumerState<CourierShiftSlider> createState() => _CourierShiftSliderState();
}

class _CourierShiftSliderState extends ConsumerState<CourierShiftSlider> {
  static const double _trackHeight = 64;
  static const double _inset = 4;
  static const double _thumbSize = _trackHeight - _inset * 2;

  /// How much of the track a drag has to cover before it counts as meaning it.
  ///
  /// High on purpose: the whole reason this is a slide is that a short,
  /// accidental movement must not change shift state.
  static const double _commit = 0.72;

  /// What the control shows while the call is in flight.
  ///
  /// Held locally so the slider settles at its destination immediately rather
  /// than snapping back and then jumping forward a round trip later.
  /// Reconciled from the profile on success and reverted on failure, so it
  /// never lies for long.
  bool? _pending;

  /// Where the thumb is, as a fraction of the track. Null means resting at
  /// whichever end the current state implies.
  double? _drag;

  bool _dragging = false;

  bool get _online => _pending ?? widget.profile.isOnline;

  Future<void> _set(bool online) async {
    setState(() => _pending = online);

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .setShift(courierProfileId: widget.profile.id, online: online);

    if (!mounted) return;

    if (result is CourierActionOk) {
      // Re-read rather than trust the optimistic value: the server decides,
      // and a courier whose review has lapsed may have been refused.
      ref.invalidate(courierProfileProvider(widget.profile.accountId));
      setState(() => _pending = null);
      return;
    }

    setState(() => _pending = null);
    showCourierActionFeedback(context, result);
  }

  void _onDragUpdate(DragUpdateDetails details, double travel) {
    final current = _drag ?? (_online ? 1.0 : 0.0);
    var next = current + details.delta.dx / travel;
    // Not .clamp(): on num that returns num, which will not assign to a
    // double without a cast.
    if (next < 0) next = 0;
    if (next > 1) next = 1;
    setState(() => _drag = next);
  }

  void _onDragEnd(bool online) {
    final current = _drag ?? (online ? 1.0 : 0.0);
    setState(() {
      _drag = null;
      _dragging = false;
    });

    // Offline slides right to arm, online slides left to stand down. A drag
    // that did not cover the track simply springs back.
    if (!online && current >= _commit) {
      unawaited(_set(true));
    } else if (online && current <= 1 - _commit) {
      unawaited(_set(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(courierActionsNotifierProvider);
    final online = _online;

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = constraints.maxWidth - _thumbSize - _inset * 2;
        final travel = span > 1 ? span : 1.0;
        final fraction = _drag ?? (online ? 1.0 : 0.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: busy
              ? null
              : (_) => setState(() => _dragging = true),
          onHorizontalDragUpdate: busy
              ? null
              : (details) => _onDragUpdate(details, travel),
          onHorizontalDragEnd: busy ? null : (_) => _onDragEnd(online),
          onHorizontalDragCancel: busy ? null : () => _onDragEnd(online),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // More opaque once online: on shift this is a status light the
              // rider glances at, and it has to read at arm's length in
              // daylight. Offline it is a prompt sitting over a map the rider
              // is still reading, so it lets the streets through.
              color: online
                  ? DesignTokens.primaryGreenLight.withValues(alpha: 0.96)
                  : DesignTokens.bgAppBody.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(_trackHeight / 2),
              border: Border.all(
                color: online
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textMuted.withValues(alpha: 0.35),
                width: online ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SizedBox(
              height: _trackHeight,
              child: Stack(
                children: [
                  // Padded clear of a thumb at either end, so the label never
                  // collides with it at rest. Mid-drag the thumb passes over
                  // the text, which is what every slide-to-act control does.
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _trackHeight + DesignTokens.s8,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              online ? "You're online" : "You're offline",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DesignTokens.mediumSemibold.copyWith(
                                color: online
                                    ? DesignTokens.primaryGreen
                                    : DesignTokens.textLight,
                              ),
                            ),
                            Text(
                              online
                                  ? 'Slide back to stop'
                                  : 'Slide right to start',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DesignTokens.tiny.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    // Zero while the thumb is under the rider's finger — an
                    // animation there lags the touch and feels broken.
                    duration: _dragging
                        ? Duration.zero
                        : const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    left: _inset + travel * fraction,
                    top: _inset,
                    child: _Thumb(online: online, busy: busy),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.online, required this.busy});

  final bool online;
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
    width: _CourierShiftSliderState._thumbSize,
    height: _CourierShiftSliderState._thumbSize,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: online ? DesignTokens.primaryGreen : DesignTokens.bgAppBodyLight,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Center(
      child: busy
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: online
                    ? DesignTokens.textDark
                    : DesignTokens.primaryGreen,
              ),
            )
          : Icon(
              online
                  ? Icons.arrow_back_rounded
                  : Icons.arrow_forward_rounded,
              size: 24,
              color: online ? DesignTokens.textDark : DesignTokens.textWhite,
            ),
    ),
  );
}
