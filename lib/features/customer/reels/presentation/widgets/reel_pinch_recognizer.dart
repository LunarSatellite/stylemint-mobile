import 'package:flutter/gestures.dart';

/// Recognises a two-finger pinch on a reel, and nothing else.
///
/// A reel page is crowded with gestures: the feed pages on a vertical drag, a
/// journey (and Home's tab pager) on a horizontal one, and a tap pauses. A
/// stock `ScaleGestureRecognizer` would join every one of those arenas with a
/// single finger too — it treats one moving finger as a pan — and could win a
/// swipe that belongs to a pager. This one never claims a gesture until two
/// fingers are down and the distance between them has changed by
/// [claimRatio]; a single finger only ever drops out, leaving its swipe or tap
/// to whoever wanted it, exactly as before this recognizer existed.
///
/// [onUpdate] reports the pinch's scale: the fingers' distance over what it
/// was when the second finger landed (above 1 spreading, below 1 closing).
/// [onEnd] fires when fewer than two fingers are left after a pinch.
class ReelPinchGestureRecognizer extends OneSequenceGestureRecognizer {
  ReelPinchGestureRecognizer({super.debugOwner});

  /// How far the two fingers' distance must change, as a fraction of where it
  /// started, before this recognizer claims the gesture. Small on purpose: a
  /// spreading finger also moves along a pager's axis, and the pinch should
  /// win that race well before the pager's own drag slop.
  static const double claimRatio = 0.04;

  /// The pinch's scale since two fingers came down.
  ValueChanged<double>? onUpdate;

  /// The pinch is over: fewer than two fingers left.
  VoidCallback? onEnd;

  final Map<int, Offset> _positions = <int, Offset>{};
  double? _startSpan;
  bool _accepted = false;
  bool _pinching = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _positions[event.pointer] = event.position;
    _restartSpan();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      _positions[event.pointer] = event.position;
      _onMove();
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _dropPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {
    _accepted = true;
  }

  @override
  void rejectGesture(int pointer) {
    _dropPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (!_accepted) resolve(GestureDisposition.rejected);
    _endPinch();
    _accepted = false;
    _positions.clear();
    _startSpan = null;
  }

  @override
  String get debugDescription => 'reel pinch';

  void _dropPointer(int pointer) {
    _positions.remove(pointer);
    _restartSpan();
    stopTrackingPointer(pointer);
  }

  /// The distance between the first two fingers down, or null with fewer.
  double? _span() {
    if (_positions.length < 2) return null;
    final points = _positions.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  /// A finger came or went: the pinch is measured afresh from here.
  void _restartSpan() {
    final span = _span();
    if (span == null) {
      _startSpan = null;
      _endPinch();
      return;
    }
    _startSpan = span;
  }

  void _onMove() {
    final span = _span();
    final start = _startSpan;
    if (span == null || start == null || start <= 0) return;
    final scale = span / start;
    if (!_accepted) {
      if ((scale - 1).abs() < claimRatio) return;
      resolve(GestureDisposition.accepted);
      if (!_accepted) return;
    }
    _pinching = true;
    final update = onUpdate;
    if (update != null) invokeCallback<void>('onUpdate', () => update(scale));
  }

  void _endPinch() {
    if (!_pinching) return;
    _pinching = false;
    final end = onEnd;
    if (end != null) invokeCallback<void>('onEnd', end);
  }
}
