import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/size_chart.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/overlay_geometry.dart';

/// An upright person in a 1000x2000 frame: shoulders 200 px apart at y=500,
/// hips 140 px apart at y=900, knees at y=1300, ankles at y=1700.
BodyLandmarks _body({
  double tilt = 0,
  double likelihood = 0.99,
  Set<BodyPoint> omit = const {},
}) {
  Pt rot(double x, double y) {
    // Rotate about the frame centre by [tilt] radians.
    const cx = 500.0;
    const cy = 1000.0;
    final dx = x - cx;
    final dy = y - cy;
    return Pt(
      cx + dx * math.cos(tilt) - dy * math.sin(tilt),
      cy + dx * math.sin(tilt) + dy * math.cos(tilt),
    );
  }

  final raw = <BodyPoint, Pt>{
    BodyPoint.leftShoulder: rot(600, 500),
    BodyPoint.rightShoulder: rot(400, 500),
    BodyPoint.leftHip: rot(570, 900),
    BodyPoint.rightHip: rot(430, 900),
    BodyPoint.leftKnee: rot(560, 1300),
    BodyPoint.rightKnee: rot(440, 1300),
    BodyPoint.leftAnkle: rot(550, 1700),
    BodyPoint.rightAnkle: rot(450, 1700),
    BodyPoint.leftWrist: rot(700, 900),
    BodyPoint.leftElbow: rot(680, 700),
  };
  return BodyLandmarks(
    points: {
      for (final e in raw.entries)
        if (!omit.contains(e.key))
          e.key: Landmark(e.value, likelihood: likelihood),
    },
    imageWidth: 1000,
    imageHeight: 2000,
  );
}

void main() {
  group('OverlayGeometry', () {
    test('top: centred on the torso, collar above the shoulder line', () {
      final r = OverlayGeometry.compute(
        garment: GarmentType.top,
        body: _body(),
        overlayAspect: 1.2,
      );
      final p = r.placement!;
      expect(p.center.x, closeTo(500, 0.001));
      // Collar sits above the shoulders (y=500), hem down at the hips (y=900).
      expect(p.top, lessThan(500));
      expect(p.top + p.height, greaterThanOrEqualTo(899));
      // Wider than the shoulder span, never distorted.
      expect(p.width, greaterThan(200));
      expect(p.height / p.width, closeTo(1.2, 1e-9));
      expect(p.rotation, closeTo(0, 1e-9));
    });

    test('outerwear is drawn larger than a top', () {
      double w(GarmentType g) => OverlayGeometry.compute(
        garment: g,
        body: _body(),
        overlayAspect: 1.2,
      ).placement!.width;
      expect(w(GarmentType.outerwear), greaterThan(w(GarmentType.top)));
    });

    test('bottom: from the waist down to the ankles', () {
      final p = OverlayGeometry.compute(
        garment: GarmentType.bottom,
        body: _body(),
        overlayAspect: 2.5,
      ).placement!;
      expect(p.top, lessThan(900));
      expect(p.top, greaterThan(500));
      expect(p.top + p.height, greaterThan(1500));
    });

    test('dress: from the shoulders to well past the hips', () {
      final p = OverlayGeometry.compute(
        garment: GarmentType.dress,
        body: _body(),
        overlayAspect: 2,
      ).placement!;
      expect(p.top, lessThan(500));
      expect(p.top + p.height, greaterThan(1100));
    });

    test('footwear sits at the ankles', () {
      final p = OverlayGeometry.compute(
        garment: GarmentType.footwear,
        body: _body(),
        overlayAspect: 0.5,
      ).placement!;
      expect(p.center.x, closeTo(500, 0.001));
      expect(p.center.y, greaterThan(1700));
    });

    test('accessory sits at the neck, or the wrist without shoulders', () {
      final neck = OverlayGeometry.compute(
        garment: GarmentType.accessory,
        body: _body(),
        overlayAspect: 1,
      ).placement!;
      expect(neck.center.y, lessThan(500));
      expect(neck.center.x, closeTo(500, 0.001));

      final wrist = OverlayGeometry.compute(
        garment: GarmentType.accessory,
        body: _body(
          omit: {BodyPoint.leftShoulder, BodyPoint.rightShoulder},
        ),
        overlayAspect: 1,
      ).placement!;
      expect(wrist.center.x, closeTo(700, 0.001));
      expect(wrist.center.y, closeTo(900, 0.001));
    });

    test('a leaning body tilts the garment with it', () {
      const tilt = 0.2;
      final p = OverlayGeometry.compute(
        garment: GarmentType.top,
        body: _body(tilt: tilt),
        overlayAspect: 1.2,
      ).placement!;
      expect(p.rotation, closeTo(tilt, 1e-6));
    });

    test('missing or unsure anchors are "pose not found"', () {
      final noShoulders = OverlayGeometry.compute(
        garment: GarmentType.top,
        body: _body(omit: {BodyPoint.leftShoulder}),
        overlayAspect: 1,
      );
      expect(noShoulders.isPlaced, isFalse);
      expect(noShoulders.problem, PoseProblem.notFound);

      final unsure = OverlayGeometry.compute(
        garment: GarmentType.bottom,
        body: _body(likelihood: 0.2),
        overlayAspect: 1,
      );
      expect(unsure.isPlaced, isFalse);
    });

    test('top without hips still places from the shoulders', () {
      final p = OverlayGeometry.compute(
        garment: GarmentType.top,
        body: _body(omit: {BodyPoint.leftHip, BodyPoint.rightHip}),
        overlayAspect: 1,
      ).placement!;
      expect(p.width, closeTo(200 * 1.55, 1e-6));
    });
  });

  group('mapPlacementToView', () {
    const placement = OverlayPlacement(
      center: Pt(250, 500),
      width: 100,
      height: 200,
      rotation: 0.1,
    );

    test('cover scales to fill and centres the overflow', () {
      // 1000x2000 image into a 500x500 view: scale 0.5, y overflow -250.
      final v = mapPlacementToView(
        placement: placement,
        imageWidth: 1000,
        imageHeight: 2000,
        viewWidth: 500,
        viewHeight: 500,
      );
      expect(v.width, 50);
      expect(v.height, 100);
      expect(v.centerX, closeTo(125, 1e-9));
      expect(v.centerY, closeTo(250 - 250, 1e-9));
      expect(v.rotation, 0.1);
    });

    test('contain letterboxes', () {
      final v = mapPlacementToView(
        placement: placement,
        imageWidth: 1000,
        imageHeight: 2000,
        viewWidth: 500,
        viewHeight: 500,
        fit: ViewFit.contain,
      );
      // scale 0.25, x offset (500-250)/2 = 125.
      expect(v.width, 25);
      expect(v.centerX, closeTo(250 * 0.25 + 125, 1e-9));
      expect(v.centerY, closeTo(500 * 0.25, 1e-9));
    });

    test('mirror flips x and the tilt (front camera)', () {
      final v = mapPlacementToView(
        placement: placement,
        imageWidth: 1000,
        imageHeight: 1000,
        viewWidth: 1000,
        viewHeight: 1000,
        mirror: true,
      );
      expect(v.centerX, closeTo(750, 1e-9));
      expect(v.rotation, -0.1);
    });
  });

  group('PlacementSmoother', () {
    const a = OverlayPlacement(center: Pt(100, 100), width: 100, height: 100);
    const b = OverlayPlacement(center: Pt(120, 100), width: 110, height: 110);

    test('eases toward the new frame', () {
      final s = PlacementSmoother(alpha: 0.5)..add(a);
      final p = s.add(b)!;
      expect(p.center.x, closeTo(110, 1e-9));
      expect(p.width, closeTo(105, 1e-9));
    });

    test('snaps on a big jump', () {
      final s = PlacementSmoother(alpha: 0.5)..add(a);
      const far = OverlayPlacement(
        center: Pt(900, 900),
        width: 100,
        height: 100,
      );
      expect(s.add(far)!.center.x, 900);
    });

    test('holds through a short gap, then drops', () {
      final s = PlacementSmoother(holdFrames: 2)..add(a);
      expect(s.add(null), isNotNull);
      expect(s.add(null), isNotNull);
      expect(s.add(null), isNull);
    });
  });

  test('meanLuma flags dark frames', () {
    expect(meanLuma(List.filled(10000, 20)), lessThan(lowLightThreshold));
    expect(meanLuma(List.filled(10000, 120)), greaterThan(lowLightThreshold));
    expect(meanLuma(const []), 0);
  });
}
