import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_detail_screen.dart';

import '../../codes/support/recording_api_client.dart';

/// **A 15 % partnership advertised itself as "0% Commission".**
///
/// `PartnershipDto.CommissionMinPercent` is `CommissionRange.MinPercent`,
/// and `CommissionRange` stores commission as a **fraction** in `0..1` —
/// `0.15` is fifteen percent — despite the `Percent` in the name.
/// `RequestPartnershipVmValidator` pins the request side to the same
/// `Floor..Ceiling` == `0..1`.
///
/// `PartnershipDetailDto.fromJson` read that field straight into a field it
/// called `commissionMinPercent` with no conversion, while its sibling
/// `BrandDetailDto.fromJson` in the very same file multiplied by 100. Two
/// things followed, both about the creator's own money:
///
///   * `brand_detail_screen.dart` formats the header chip with
///     `toStringAsFixed(0)`. On `0.15` that is `"0"`, so the brand's own
///     detail page announced **"0% Commission"** — and "0-0% Commissions"
///     for a range — to every creator, for every partnership paying under
///     50 %.
///   * The same two numbers are handed to `PartnershipApplyArgs`. The apply
///     screen treats them as percents: it labels the slider `"$min%-$max%"`
///     and submits `_range.start / 100`. Given a fraction it submitted
///     `0.15 / 100` == `0.0015` — a request for **0.15 % commission**, a
///     hundredth of what the creator saw and agreed to, inside the
///     backend's valid range and therefore accepted in silence.
///
/// The other caller of `PartnershipApplyArgs` (`brand_info_screen.dart`,
/// seeded from `BrandListItemDto`) always passed true percents, so the two
/// entry points into one screen disagreed about the unit.
///
/// These assert over **rendered and parsed values**, not over source text,
/// so a rename or a move still fails them.
void main() {
  // ── The parsed value, which is what the apply slider is handed ──────────
  group('PartnershipDetailDto.fromJson', () {
    test('converts the backend fraction to a percent', () {
      final dto = PartnershipDetailDto.fromJson(_partnershipJson());

      expect(dto.commissionMinPercent, 15.0);
      expect(dto.commissionMaxPercent, 30.0);
    });

    test('a fixed 8 % rate does not collapse to zero', () {
      final dto = PartnershipDetailDto.fromJson(
        _partnershipJson(min: 0.08, max: 0.08),
      );

      expect(dto.commissionMinPercent, closeTo(8.0, 1e-9));
      expect(dto.commissionMaxPercent, closeTo(8.0, 1e-9));
      // What the header prints, and what the apply slider labels itself.
      expect(dto.commissionMinPercent.toStringAsFixed(0), '8');
    });

    test(
      "the apply screen's own /100 round-trips back to the stored fraction",
      () {
        final dto = PartnershipDetailDto.fromJson(_partnershipJson());

        // `partnership_apply_screen.dart` submits `_range.start / 100`,
        // whose default is `args.commissionMin`.
        expect(dto.commissionMinPercent / 100, closeTo(0.15, 1e-9));
        expect(dto.commissionMaxPercent / 100, closeTo(0.30, 1e-9));
      },
    );
  });

  // ── What the creator actually reads on the screen ───────────────────────
  testWidgets('brand detail header states the real commission range', (
    tester,
  ) async {
    await _pumpDetail(tester);

    final text = _allText(tester);
    expect(
      text,
      contains('15-30% Commissions'),
      reason: 'the header must name the rate the partnership actually pays',
    );
    expect(
      text.any((s) => s.contains('0-0%') || s == '0% Commission'),
      isFalse,
      reason: 'a 15-30 % partnership must never advertise 0 % to a creator',
    );
  });

  testWidgets('a fixed-rate partnership keeps its rate on screen', (
    tester,
  ) async {
    await _pumpDetail(tester, min: 0.08, max: 0.08);

    expect(_allText(tester), contains('8% Commission'));
  });
}

// ── Harness ──────────────────────────────────────────────────────────────────

/// The shape `GET /v1/partnerships/{id}` serialises `PartnershipDto` into —
/// commission as a fraction, because that is what `CommissionRange` holds.
Map<String, dynamic> _partnershipJson({double min = 0.15, double max = 0.30}) =>
    <String, dynamic>{
      'id': 'ptr-1',
      'vendorProfileId': 'vp-1',
      'state': 3,
      'commissionMinPercent': min,
      'commissionMaxPercent': max,
      'vendorRating': 4.5,
      'requestMessage': null,
      'vendorName': 'Himalayan Threads',
      'vendorLogoUrl': null,
      'vendorCategory': 'Apparel',
      'description': 'Handwoven pashmina, made in Kathmandu.',
    };

Future<void> _pumpDetail(
  WidgetTester tester, {
  double min = 0.15,
  double max = 0.30,
}) async {
  tester.view.physicalSize = const Size(720, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final ApiClient client = RecordingApiClient((call) {
    if (call.uri == '/v1/partnerships/ptr-1') {
      return _partnershipJson(min: min, max: max);
    }
    return dioError(404, path: call.uri);
  });

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const BrandDetailScreen(partnershipId: 'ptr-1'),
      ),
      GoRoute(
        path: '/creator/partnerships/:partnershipId/apply',
        builder: (_, _) => const Scaffold(body: Text('apply screen')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(client)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every string the screen put on screen, plus every spoken label — a
/// fabricated rate whispered to a screen reader is still fabricated.
List<String> _allText(WidgetTester tester) => [
  ...tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? ''),
  ...tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((s) => s.properties.label ?? ''),
].where((s) => s.isNotEmpty).toList();
