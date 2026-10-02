import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/showcase/fixtures.dart';
import '../../integration_test/showcase/harness.dart';
import '../../integration_test/showcase/stub_images.dart';

/// Guards the App Store screenshot run from the development machine.
///
/// The capture itself needs an iOS simulator and so only ever runs on the
/// macOS runner (`.github/workflows/ios-screenshots.yml`). What can go wrong
/// there without anyone noticing is not the capture — it is the content: a
/// fixture that stops matching the widget tree renders an empty rail, the run
/// still succeeds, and what lands in the artifact is a photograph of an empty
/// app. These tests fail here instead, on Windows, in seconds.
///
/// They assert that each showcase screen reaches the fixture data. They say
/// nothing about how it looks — that is what the artifact is for.
void main() {
  // iPhone 14 Plus in logical pixels: 1284 × 2778 at devicePixelRatio 3, the
  // 6.5" slot the listing needs. Layout, not resolution, is what is checked.
  const logicalSize = Size(428, 926);

  setUp(() => HttpOverrides.global = ShowcaseImageOverrides());
  tearDown(() => HttpOverrides.global = null);

  Future<void> pump(WidgetTester tester, ShowcaseScreen screen) async {
    await tester.binding.setSurfaceSize(logicalSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpShowcase(tester, screen);
  }

  testWidgets('the Mall reaches its campaign, rails and live deal', (
    tester,
  ) async {
    await pump(tester, ShowcaseScreen.mall);

    expect(tester.takeException(), isNull);
    expect(find.text('The Gold Hour Edit'), findsOneWidget);
    expect(find.text('Picked for you'), findsOneWidget);
    // The personalisation line: proof the signed-in home rendered, not the
    // anonymous fallback.
    expect(find.text('Because you follow Kathmandu Atelier'), findsOneWidget);
    // At least one product tile carried a name through.
    expect(find.text('Oversized linen co-ord set'), findsOneWidget);
  });

  testWidgets('the product page reaches its product, price and seller', (
    tester,
  ) async {
    await pump(tester, ShowcaseScreen.productDetail);

    expect(tester.takeException(), isNull);
    expect(find.text(ShowcaseFixtures.productDetail().name), findsWidgets);
    expect(find.text('Himalayan Weaves'), findsWidgets);
    // A loading spinner instead of a body is the failure this catches.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the reels feed reaches a populated feed', (tester) async {
    await pump(tester, ShowcaseScreen.reels);

    expect(tester.takeException(), isNull);
    // The empty state's copy, which must not be what gets photographed.
    expect(find.textContaining('No reels yet'), findsNothing);
    expect(find.textContaining('priya.styles'), findsWidgets);
  });

  test('every showcase screen has a distinct, sortable file name', () {
    final names = ShowcaseScreen.values.map((s) => s.fileName).toList();
    expect(names.toSet(), hasLength(names.length));
    expect(names, orderedEquals([...names]..sort()));
  });
}
