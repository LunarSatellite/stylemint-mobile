/// Where the garment overlay goes, given body landmarks.
///
/// Pure Dart (no Flutter, no ML Kit) so it is unit-testable: the presentation
/// layer converts ML Kit's `Pose` into [BodyLandmarks] and draws the
/// resulting [OverlayPlacement]; every rule about shoulders, hips and ankles
/// lives here.
///
/// Coordinates are pixels of the upright source image (the frame after the
/// sensor rotation is applied — what ML Kit reports). [mapPlacementToView]
/// turns a placement into widget coordinates, including the front-camera
/// mirror.
library;

import 'dart:math' as math;

import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/size_chart.dart';

class Pt {
  const Pt(this.x, this.y);

  final double x;
  final double y;

  Pt operator +(Pt o) => Pt(x + o.x, y + o.y);
  Pt operator -(Pt o) => Pt(x - o.x, y - o.y);
  Pt operator *(double k) => Pt(x * k, y * k);

  double get length => math.sqrt(x * x + y * y);

  double distanceTo(Pt o) => (this - o).length;

  Pt get unit {
    final l = length;
    return l == 0 ? const Pt(0, 1) : Pt(x / l, y / l);
  }

  static Pt mid(Pt a, Pt b) => Pt((a.x + b.x) / 2, (a.y + b.y) / 2);

  @override
  String toString() => 'Pt(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// The landmarks the overlay uses (a subset of ML Kit's 33).
enum BodyPoint {
  nose,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftHeel,
  rightHeel,
  leftFootIndex,
  rightFootIndex,
}

class Landmark {
  const Landmark(this.point, {this.likelihood = 1});

  final Pt point;
  final double likelihood;
}

class BodyLandmarks {
  const BodyLandmarks({
    required this.points,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Map<BodyPoint, Landmark> points;
  final double imageWidth;
  final double imageHeight;

  /// Landmarks ML Kit is less sure of than this are treated as not seen —
  /// an off-frame hip is guessed with ~0.2 likelihood and would drag the
  /// garment off the body.
  static const double minLikelihood = 0.5;

  Pt? operator [](BodyPoint p) {
    final l = points[p];
    if (l == null || l.likelihood < minLikelihood) return null;
    return l.point;
  }

  Pt? midOf(BodyPoint a, BodyPoint b) {
    final pa = this[a];
    final pb = this[b];
    if (pa == null || pb == null) return null;
    return Pt.mid(pa, pb);
  }
}

/// A rotated rectangle in source-image pixels: the garment's centre, its
/// size, and its tilt in radians (clockwise positive, y pointing down).
class OverlayPlacement {
  const OverlayPlacement({
    required this.center,
    required this.width,
    required this.height,
    this.rotation = 0,
  });

  final Pt center;
  final double width;
  final double height;
  final double rotation;

  double get left => center.x - width / 2;
  double get top => center.y - height / 2;

  OverlayPlacement copyWith({
    Pt? center,
    double? width,
    double? height,
    double? rotation,
  }) => OverlayPlacement(
    center: center ?? this.center,
    width: width ?? this.width,
    height: height ?? this.height,
    rotation: rotation ?? this.rotation,
  );

  /// The same placement moved by [offset] and grown by [scale] about its
  /// centre — what the photo mode's nudge/pinch gestures apply.
  OverlayPlacement adjusted({
    Pt offset = const Pt(0, 0),
    double scale = 1,
    double extraRotation = 0,
  }) => OverlayPlacement(
    center: center + offset,
    width: width * scale,
    height: height * scale,
    rotation: rotation + extraRotation,
  );

  @override
  String toString() =>
      'OverlayPlacement($center, ${width.toStringAsFixed(1)}x'
      '${height.toStringAsFixed(1)}, ${rotation.toStringAsFixed(3)})';
}

/// Why no placement could be computed — drives the on-screen hint.
enum PoseProblem {
  /// No body at all, or the anchor landmarks are not visible.
  notFound,

  /// The person is so close that the anchors are cramped/unreliable.
  tooClose,
}

class OverlayResult {
  const OverlayResult.placed(OverlayPlacement this.placement) : problem = null;
  const OverlayResult.missing(PoseProblem this.problem) : placement = null;

  final OverlayPlacement? placement;
  final PoseProblem? problem;

  bool get isPlaced => placement != null;
}

abstract final class OverlayGeometry {
  /// Computes where an overlay of [overlayAspect] (height / width) goes on a
  /// body of [garment] type.
  ///
  /// Width is derived from the anchor span (shoulders, hips, ankles); where a
  /// second span is visible (shoulder→hip, hip→ankle, shoulder→knee) the
  /// length it implies is blended in, so a long coat and a crop top are not
  /// drawn the same size. The image is never stretched: height always
  /// follows the overlay's own aspect.
  static OverlayResult compute({
    required GarmentType garment,
    required BodyLandmarks body,
    required double overlayAspect,
  }) {
    final aspect = overlayAspect <= 0 ? 1.0 : overlayAspect;
    return switch (garment) {
      GarmentType.top => _upperBody(body, aspect, widthK: 1.55, lengthK: 1.25),
      GarmentType.outerwear => _upperBody(
        body,
        aspect,
        widthK: 1.75,
        lengthK: 1.45,
      ),
      GarmentType.dress || GarmentType.fullBody => _fullLength(body, aspect),
      GarmentType.bottom => _bottom(body, aspect),
      GarmentType.footwear => _footwear(body, aspect),
      GarmentType.accessory => _accessory(body, aspect),
    };
  }

  /// Unit vector pointing "down the body" (from shoulders to hips), so the
  /// garment tilts with a leaning user. Falls back to the perpendicular of
  /// the [across] line, then to straight down.
  static Pt _downAxis({Pt? from, Pt? to, Pt? acrossA, Pt? acrossB}) {
    if (from != null && to != null && from.distanceTo(to) > 1) {
      return (to - from).unit;
    }
    if (acrossA != null && acrossB != null) {
      final (l, r) = acrossA.x <= acrossB.x
          ? (acrossA, acrossB)
          : (acrossB, acrossA);
      final across = (r - l).unit;
      // Perpendicular, rotated clockwise: (x, y) -> (-y, x) points down.
      return Pt(-across.y, across.x);
    }
    return const Pt(0, 1);
  }

  /// Rotation (radians) of a rectangle whose "down" is [down].
  static double _rotationOf(Pt down) => -math.atan2(down.x, down.y);

  static OverlayPlacement _placeFromTop({
    required Pt topAnchor,
    required Pt down,
    required double width,
    required double aspect,
  }) {
    final height = width * aspect;
    return OverlayPlacement(
      center: topAnchor + down * (height / 2),
      width: width,
      height: height,
      rotation: _rotationOf(down),
    );
  }

  static OverlayResult _upperBody(
    BodyLandmarks b,
    double aspect, {
    required double widthK,
    required double lengthK,
  }) {
    final ls = b[BodyPoint.leftShoulder];
    final rs = b[BodyPoint.rightShoulder];
    if (ls == null || rs == null) {
      return const OverlayResult.missing(PoseProblem.notFound);
    }
    final shoulderMid = Pt.mid(ls, rs);
    final shoulderW = ls.distanceTo(rs);
    if (shoulderW < 8) return const OverlayResult.missing(PoseProblem.notFound);
    final hipMid = b.midOf(BodyPoint.leftHip, BodyPoint.rightHip);
    final down = _downAxis(
      from: shoulderMid,
      to: hipMid,
      acrossA: ls,
      acrossB: rs,
    );

    var width = shoulderW * widthK;
    if (hipMid != null) {
      final torso = shoulderMid.distanceTo(hipMid);
      final widthFromLength = torso * lengthK / aspect;
      width = (width + widthFromLength) / 2;
    }
    // The collar sits a little above the shoulder joints.
    final top = shoulderMid - down * (shoulderW * 0.18);
    return OverlayResult.placed(
      _placeFromTop(topAnchor: top, down: down, width: width, aspect: aspect),
    );
  }

  static OverlayResult _fullLength(BodyLandmarks b, double aspect) {
    final ls = b[BodyPoint.leftShoulder];
    final rs = b[BodyPoint.rightShoulder];
    if (ls == null || rs == null) {
      return const OverlayResult.missing(PoseProblem.notFound);
    }
    final shoulderMid = Pt.mid(ls, rs);
    final shoulderW = ls.distanceTo(rs);
    if (shoulderW < 8) return const OverlayResult.missing(PoseProblem.notFound);
    final hipMid = b.midOf(BodyPoint.leftHip, BodyPoint.rightHip);
    final kneeMid = b.midOf(BodyPoint.leftKnee, BodyPoint.rightKnee);
    final down = _downAxis(
      from: shoulderMid,
      to: hipMid ?? kneeMid,
      acrossA: ls,
      acrossB: rs,
    );

    var width = shoulderW * 1.7;
    final double? length = kneeMid != null
        ? shoulderMid.distanceTo(kneeMid) * 1.1
        : hipMid != null
        ? shoulderMid.distanceTo(hipMid) * 2.0
        : null;
    if (length != null) width = (width + length / aspect) / 2;
    final top = shoulderMid - down * (shoulderW * 0.18);
    return OverlayResult.placed(
      _placeFromTop(topAnchor: top, down: down, width: width, aspect: aspect),
    );
  }

  static OverlayResult _bottom(BodyLandmarks b, double aspect) {
    final lh = b[BodyPoint.leftHip];
    final rh = b[BodyPoint.rightHip];
    if (lh == null || rh == null) {
      return const OverlayResult.missing(PoseProblem.notFound);
    }
    final hipMid = Pt.mid(lh, rh);
    // Hip joints sit well inside the hip line; the waistband is wider.
    final hipW = lh.distanceTo(rh);
    if (hipW < 6) return const OverlayResult.missing(PoseProblem.notFound);
    final ankleMid = b.midOf(BodyPoint.leftAnkle, BodyPoint.rightAnkle);
    final kneeMid = b.midOf(BodyPoint.leftKnee, BodyPoint.rightKnee);
    final down = _downAxis(
      from: hipMid,
      to: ankleMid ?? kneeMid,
      acrossA: lh,
      acrossB: rh,
    );

    var width = hipW * 2.3;
    final double? length = ankleMid != null
        ? hipMid.distanceTo(ankleMid) * 1.05
        : kneeMid != null
        ? hipMid.distanceTo(kneeMid) * 2.05
        : null;
    if (length != null) width = (width + length / aspect) / 2;
    final top = hipMid - down * (hipW * 0.35);
    return OverlayResult.placed(
      _placeFromTop(topAnchor: top, down: down, width: width, aspect: aspect),
    );
  }

  static OverlayResult _footwear(BodyLandmarks b, double aspect) {
    final la = b[BodyPoint.leftAnkle];
    final ra = b[BodyPoint.rightAnkle];
    if (la == null || ra == null) {
      return const OverlayResult.missing(PoseProblem.notFound);
    }
    final ankleMid = Pt.mid(la, ra);
    final hipW = switch ((b[BodyPoint.leftHip], b[BodyPoint.rightHip])) {
      (final Pt l, final Pt r) => l.distanceTo(r),
      _ => 0.0,
    };
    final width = math.max(la.distanceTo(ra) * 1.8, hipW * 1.4);
    if (width < 8) return const OverlayResult.missing(PoseProblem.notFound);
    final height = width * aspect;
    // The pair image is centred a little below the ankle joints.
    return OverlayResult.placed(
      OverlayPlacement(
        center: Pt(ankleMid.x, ankleMid.y + height * 0.25),
        width: width,
        height: height,
      ),
    );
  }

  static OverlayResult _accessory(BodyLandmarks b, double aspect) {
    final ls = b[BodyPoint.leftShoulder];
    final rs = b[BodyPoint.rightShoulder];
    if (ls == null || rs == null) {
      // Best effort: a wrist (watch, bracelet) when the shoulders are not
      // in frame.
      final wrist = b[BodyPoint.leftWrist] ?? b[BodyPoint.rightWrist];
      if (wrist == null) {
        return const OverlayResult.missing(PoseProblem.notFound);
      }
      final elbow = b[BodyPoint.leftElbow] ?? b[BodyPoint.rightElbow];
      final w = elbow == null ? 60.0 : wrist.distanceTo(elbow) * 0.45;
      return OverlayResult.placed(
        OverlayPlacement(center: wrist, width: w, height: w * aspect),
      );
    }
    final shoulderMid = Pt.mid(ls, rs);
    final shoulderW = ls.distanceTo(rs);
    final down = _downAxis(acrossA: ls, acrossB: rs);
    // Neck: just above the shoulder line, where a necklace or scarf sits.
    final neck = shoulderMid - down * (shoulderW * 0.12);
    final width = shoulderW * 0.7;
    return OverlayResult.placed(
      OverlayPlacement(
        center: neck,
        width: width,
        height: width * aspect,
        rotation: _rotationOf(down),
      ),
    );
  }
}

/// Exponential smoothing of placements across frames, so the garment does
/// not shiver with landmark noise. A big jump (the user moved, or a new
/// person stepped in) snaps instead of sliding across the screen. A short
/// gap in detection holds the last placement rather than flickering.
class PlacementSmoother {
  PlacementSmoother({this.alpha = 0.35, this.holdFrames = 8});

  /// Weight of the new frame (0..1). Lower is smoother but laggier.
  final double alpha;

  /// Frames without a pose before the overlay is dropped.
  final int holdFrames;

  OverlayPlacement? _current;
  int _missed = 0;

  OverlayPlacement? get current => _current;

  void reset() {
    _current = null;
    _missed = 0;
  }

  /// Feeds one frame's raw placement (null = no pose this frame) and returns
  /// what to draw.
  OverlayPlacement? add(OverlayPlacement? next) {
    if (next == null) {
      _missed++;
      if (_missed > holdFrames) _current = null;
      return _current;
    }
    _missed = 0;
    final prev = _current;
    if (prev == null || prev.center.distanceTo(next.center) > prev.width) {
      return _current = next;
    }
    double lerp(double a, double b) => a + (b - a) * alpha;
    return _current = OverlayPlacement(
      center: Pt(
        lerp(prev.center.x, next.center.x),
        lerp(prev.center.y, next.center.y),
      ),
      width: lerp(prev.width, next.width),
      height: lerp(prev.height, next.height),
      rotation: lerp(prev.rotation, next.rotation),
    );
  }
}

/// How the source image is laid into the view.
enum ViewFit { cover, contain }

/// A placement in view (widget) coordinates.
class ViewPlacement {
  const ViewPlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.rotation,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double rotation;

  double get centerX => left + width / 2;
  double get centerY => top + height / 2;
}

/// Maps a source-image [placement] into a view of [viewWidth]x[viewHeight]
/// showing the image with [fit]. With [mirror] (front camera preview, which
/// the platform shows mirrored) x is flipped and so is the tilt.
ViewPlacement mapPlacementToView({
  required OverlayPlacement placement,
  required double imageWidth,
  required double imageHeight,
  required double viewWidth,
  required double viewHeight,
  ViewFit fit = ViewFit.cover,
  bool mirror = false,
}) {
  final sx = viewWidth / imageWidth;
  final sy = viewHeight / imageHeight;
  final s = fit == ViewFit.cover ? math.max(sx, sy) : math.min(sx, sy);
  final dx = (viewWidth - imageWidth * s) / 2;
  final dy = (viewHeight - imageHeight * s) / 2;
  var cx = placement.center.x * s + dx;
  final cy = placement.center.y * s + dy;
  if (mirror) cx = viewWidth - cx;
  final w = placement.width * s;
  final h = placement.height * s;
  return ViewPlacement(
    left: cx - w / 2,
    top: cy - h / 2,
    width: w,
    height: h,
    rotation: mirror ? -placement.rotation : placement.rotation,
  );
}

/// Mean luma (0..255) of a sample of [luma] bytes — the Y plane of an NV21 /
/// YUV420 frame. Below [lowLightThreshold] the pose model gets unreliable and
/// the screen asks for more light.
double meanLuma(List<int> luma, {int samples = 2000}) {
  if (luma.isEmpty) return 0;
  final step = math.max(1, luma.length ~/ samples);
  var sum = 0;
  var n = 0;
  for (var i = 0; i < luma.length; i += step) {
    sum += luma[i];
    n++;
  }
  return sum / n;
}

const double lowLightThreshold = 45;
