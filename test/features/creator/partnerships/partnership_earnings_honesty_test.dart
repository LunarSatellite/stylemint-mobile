import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/partnership_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_terms.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/partnerships_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/active_partnerships_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnership_requests_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// **Every creator was told they had earned Rs 0 from every brand.**
///
/// `PartnershipDto.toActiveDomain()` and `toEndedDomain()` hardcoded
/// `totalEarned: Money(0)`, `totalSales: 0` and `productsCount: 0`, and
/// `active_partnerships_screen.dart` passed a literal `0` for
/// `activeCampaigns`. So the Active Partnerships card drew, for every
/// partnership without exception:
///
///   * "Total Earnings   Rs 0" — in a green chip, styled as a result
///   * "Active Campaigns   0"
///   * "0 Products tagged"
///
/// and the Ended tab drew the Rs 0 again on partnerships that had run their
/// whole course. None of the four numbers was ever read from anything. A
/// creator who had earned money was told, on the screen about the brand that
/// paid it, that they had earned nothing — a false statement to someone about
/// their own money.
///
/// Verified against `lead360` on 2026-09-20, none of the four is knowable:
///
///   * Payouts' `EarningsLedgerEntry` is the system of record for creator
///     money and has **no partnership and no vendor dimension** — the word
///     "partnership" does not occur in that module at all.
///   * Partnerships' `AffiliateLink` has `PartnershipId` next to
///     `TotalEarnings`, but its only construction site passes
///     `partnershipId: null`, so the column is dead in every row.
///   * `Reels.TaggedProduct.PartnershipIdSnapshot` really is recorded, but no
///     repository method counts by partnership and no endpoint returns it.
///   * "Active campaigns per partnership" is not modelled anywhere.
///
/// So the figures are **removed**, not defaulted and not nulled into a dash.
/// These tests are written against the *shape* of the defect — a source scan
/// plus what the widget actually puts on screen — so it cannot come back
/// through a different field name or a different screen in this feature.

// ── Source scanning ──────────────────────────────────────────────────────────

const String _featureDir = 'lib/features/creator/partnerships';

/// Source of every `.dart` file in the partnerships feature, comments
/// stripped.
///
/// The bans below are about what the app **reads and renders**, never about
/// what a comment may explain. The files that removed these figures name them
/// in prose so the next reader knows exactly what went and why; that prose
/// must not fail the guard that keeps it gone. Stripping is deliberately
/// crude — a `//` inside a string literal truncates that line — which can
/// only ever hide a match, never invent one.
Map<String, String> _featureCode() {
  final lineComment = RegExp('//.*');
  final blockComment = RegExp(r'/\*.*?\*/', dotAll: true);
  final out = <String, String>{};
  for (final entity in Directory(_featureDir).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart') ||
        entity.path.endsWith('.freezed.dart')) {
      continue;
    }
    out[entity.path.replaceAll(r'\', '/')] = entity
        .readAsStringSync()
        .replaceAll(blockComment, '')
        .replaceAll(lineComment, '');
  }
  return out;
}

/// The one place in this feature a zero amount survives, named individually
/// with its reason — the house pattern, so an exemption is a decision on the
/// record rather than a hole.
///
/// `PotentialEarningsDto.fromJson` falls back to `MoneyDto(amount: 0)` when
/// the `potential-earnings` payload is missing a money key. It is **not** the
/// defect this file is about: that endpoint is a *projection at 50
/// hypothetical sales*, not money anyone earned, and the fallback is a parse
/// guard rather than a rendered figure. It is left alone deliberately —
/// changing it reaches into `brand_detail_screen`, a surface outside this
/// change — and is reported as still open. It should become a nullable money
/// that renders nothing, for the same reason everything else here did.
const List<String> _zeroExemptions = [
  '$_featureDir/data/models/brand_detail_dto.dart: amount: 0',
];

// ── Widget harness ───────────────────────────────────────────────────────────

/// A partnership paying a real fifteen percent, started on a real date.
/// The wire carries commission as a fraction (`CommissionRange.cs`:
/// "stored as fractions (0.15 == 15 %)"), so 0.15 here is 15%.
ActivePartnership _active({
  required double commissionRate,
  required String vendorName,
  String id = 'p-1',
  String vendorLogoUrl = '',
}) => ActivePartnership(
  id: id,
  vendorProfileId: 'vp-1',
  vendorAccountId: 'acct-1',
  vendorName: vendorName,
  vendorLogoUrl: vendorLogoUrl,
  commissionRate: commissionRate,
  startedAt: DateTime(2026, 3, 4),
);

EndedPartnership _ended({required double commissionRate}) => EndedPartnership(
  id: 'p-2',
  vendorName: 'Sagarmatha Threads',
  vendorLogoUrl: '',
  commissionRate: commissionRate,
  startedAt: DateTime(2025, 11, 2),
  endedAt: DateTime(2026, 6, 18),
  endReason: 'Campaign concluded',
);

class _FakeRepository implements PartnershipsRepository {
  _FakeRepository({
    this.invites = const [],
    this.active = const [],
    this.ended = const [],
  });

  final List<PartnershipInvite> invites;
  final List<ActivePartnership> active;
  final List<EndedPartnership> ended;

  @override
  Future<NetworkEither<List<PartnershipInvite>>> getInvites() async =>
      networkRight(invites);

  @override
  Future<NetworkEither<List<ActivePartnership>>>
  getActivePartnerships() async => networkRight(active);

  @override
  Future<NetworkEither<List<EndedPartnership>>> getEndedPartnerships() async =>
      networkRight(ended);

  @override
  Future<NetworkEither<PartnershipInvite>> acceptInvite(String id) async =>
      networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<Unit>> declineInvite(String id) async =>
      networkRight(unit);

  @override
  Future<NetworkEither<PartnershipTerms>> getPartnershipTerms(
    String id,
  ) async => networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<List<PartnershipTerms>>> getTermsVersions(
    String id,
  ) async => networkRight(const []);

  @override
  Future<NetworkEither<PotentialEarnings>> getPotentialEarnings(
    String id, {
    String? variantId,
  }) async => networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<List<RecipeAttachmentInfo>>> getPartnershipRecipes(
    String id,
  ) async => networkRight(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Routes the card can actually reach, so a tap is verifiable rather than
/// merely "did not throw".
String? _lastRoute;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
  double textScale = 1,
  List<ActivePartnership> active = const [],
  List<EndedPartnership> ended = const [],
  List<PartnershipInvite> invites = const [],
}) async {
  _lastRoute = null;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Widget stub(String name) => Builder(
    builder: (_) {
      _lastRoute = name;
      return Scaffold(body: Text('route:$name'));
    },
  );

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: RouteNames.earnings,
        builder: (_, _) => stub(RouteNames.earnings),
      ),
      GoRoute(
        path: RouteNames.creatorAnalytics,
        builder: (_, _) => stub(RouteNames.creatorAnalytics),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        partnershipsRepositoryProvider.overrideWithValue(
          _FakeRepository(invites: invites, active: active, ended: ended),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every string the screen actually put on screen, plus every spoken label —
/// a fabricated figure whispered to a screen reader is still fabricated.
List<String> _allText(WidgetTester tester) => [
  ...tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? ''),
  ...tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((s) => s.properties.label ?? ''),
].where((s) => s.isNotEmpty).toList();

void main() {
  // ── 1. The zeros cannot come back through the source ───────────────────────

  group('no hardcoded zero reaches a money, count or campaign figure', () {
    test('the four fabricated fields no longer exist in the feature', () {
      // Identifiers, not copy: each of these was a field or an argument that
      // carried a constant to the screen. While none of them exists, none of
      // them can be defaulted to zero again.
      const banned = <String>[
        'totalEarned',
        'totalSales',
        'productsCount',
        'productsTagged',
        'activeCampaigns',
      ];
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        for (final token in banned) {
          if (code.contains(token)) offenders.add('$path: $token');
        }
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no zero Money is constructed anywhere in the feature', () {
      // `Money(amount: 0, currency: 'NPR')` was the exact literal that told
      // every creator they had earned nothing, in two methods of one file.
      final zeroMoney = RegExp(r'Money\s*\(\s*(amount\s*:\s*)?0[.,)\s]');
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        if (zeroMoney.hasMatch(code)) offenders.add(path);
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no money, sales or campaign figure is assigned a literal zero', () {
      // The general shape rather than the five names above: any argument or
      // field whose name is about money, sales, earnings, campaigns or a
      // payout, being handed a bare 0. This is what makes the guard survive
      // a rename — a new `lifetimeEarnings: 0` fails it just as the old
      // `totalEarned` would have.
      final zeroAssign = RegExp(
        r'\b\w*(earn|earning|sale|revenue|campaign|payout|amount)'
        r'\w*\s*:\s*0\b',
        caseSensitive: false,
      );
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        for (final m in zeroAssign.allMatches(code)) {
          final hit = '$path: ${m.group(0)}';
          if (_zeroExemptions.any(hit.startsWith)) continue;
          offenders.add(hit);
        }
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the active partnerships screen draws no money at all', () {
      // It has no money to draw. Importing a money formatter there is the
      // first step back toward a placeholder amount.
      final code =
          _featureCode()['$_featureDir/presentation/screens/'
              'active_partnerships_screen.dart'];
      expect(code, isNotNull);
      expect(code, isNot(contains('formatMoney')));
      expect(code, isNot(contains('format_money')));
      expect(code, isNot(contains('Money')));
    });

    test('no money placeholder string exists in the feature', () {
      // "Absent is absent": a literal stand-in amount reads as a result that
      // happens to be small or missing, which is the same lie in a quieter
      // voice.
      //
      // This bans placeholders *where money belongs*, not the dash
      // character. A bare dash is a legitimate mark elsewhere in this
      // feature and must stay legitimate: `brand_partnership_record_view`
      // draws one for a rate that is genuinely too thin to divide, always
      // beside a glyph-and-word pill and the count it could not divide by —
      // the convention that replaced the brand trust score. This screen also
      // uses an em dash as a range separator ("From – To") in the filter
      // sheet and as the empty-section mark in a terms sheet. None of those
      // is an amount. The card's own freedom from dashes is asserted on the
      // rendered widget below, where "where money belongs" is decidable.
      const banned = <String>[
        "'Rs 0'",
        "'Rs --'",
        "'Rs -'",
        "'NPR 0'",
        "'N/A'",
        "'Rs 0.00'",
      ];
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        for (final token in banned) {
          if (code.contains(token)) offenders.add('$path: $token');
        }
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('commission is never rendered straight off the raw fraction', () {
      // The wire stores 0.15 for 15%. `commissionRate.round()` is 0, which is
      // how three cards came to advertise "0% commissions" on partnerships
      // that pay fifteen. Rendering goes through `commissionPercent`.
      final rawRender = RegExp(
        r'commissionRate\s*\.\s*(round|toStringAsFixed|toString)',
      );
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        for (final m in rawRender.allMatches(code)) {
          offenders.add('$path: ${m.group(0)}');
        }
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  // ── 2. The DTO cannot reintroduce them ─────────────────────────────────────

  group('PartnershipDto maps only what the endpoint returns', () {
    test('toActiveDomain carries no earnings, sales or product count', () {
      final dto = PartnershipDto(
        id: 'p-1',
        vendorProfileId: 'vp-1',
        creatorProfileId: 'cp-1',
        state: 3,
        commissionMinPercent: 0.15,
        commissionMaxPercent: 0.2,
        invitedUtc: DateTime(2026, 3, 2),
        respondedUtc: DateTime(2026, 3, 4),
        vendorName: 'Hamro Pasal',
        createdUtc: DateTime(2026, 3, 2),
        updatedUtc: DateTime(2026, 3, 4),
      );

      final active = dto.toActiveDomain();

      // The type itself is the assertion: were `totalEarned` still a field,
      // this would not compile without a value, and the only value available
      // is a constant.
      expect(active.commissionRate, 0.15);
      expect(active.commissionPercent, 15);
      expect(active.vendorName, 'Hamro Pasal');
      expect(active.startedAt, DateTime(2026, 3, 4));
    });

    test('a 15% commission reads as 15, not 0', () {
      // Regression on the second defect this card carried.
      final fifteen = _active(commissionRate: 0.15, vendorName: 'B');
      expect(fifteen.commissionPercent, 15);
      expect(_ended(commissionRate: 0.22).commissionPercent, 22);
      expect(fifteen.commissionPercent.round(), 15);
    });
  });

  // ── 3. What the card renders ───────────────────────────────────────────────

  group('the active partnership card', () {
    testWidgets('renders no zero, no dash and no amount', (tester) async {
      await _pump(
        tester,
        const ActivePartnershipsScreen(),
        active: [_active(commissionRate: 0.15, vendorName: 'Hamro Pasal')],
      );

      final text = _allText(tester).join('\n');
      expect(text, isNot(contains('Total Earnings')));
      expect(text, isNot(contains('Active Campaigns')));
      expect(text, isNot(contains('Products tagged')));
      expect(text, isNot(contains('Rs 0')));
      expect(text, isNot(contains('NPR 0')));
      expect(text, isNot(contains('--')));

      // No bare zero anywhere on the card, in any slot.
      for (final s in _allText(tester)) {
        expect(
          s.trim(),
          isNot(equals('0')),
          reason: 'a bare "0" is still on screen: $s',
        );
      }
    });

    testWidgets('renders the commission it actually pays', (tester) async {
      await _pump(
        tester,
        const ActivePartnershipsScreen(),
        active: [_active(commissionRate: 0.15, vendorName: 'Hamro Pasal')],
      );

      final text = _allText(tester).join('\n');
      expect(text, contains('15% commission'));
      expect(text, isNot(contains('0% commission')));
    });

    testWidgets('every figure it draws says what it covers', (tester) async {
      await _pump(
        tester,
        const ActivePartnershipsScreen(),
        active: [_active(commissionRate: 0.15, vendorName: 'Hamro Pasal')],
      );

      final text = _allText(tester).join('\n');
      // The commission names what it is a commission on; the date names what
      // it is the date of. Neither is a bare number in a slot.
      expect(text, contains('commission'));
      expect(text, contains('Start Date'));
      expect(text, contains('4 Mar, 2026'));
    });

    testWidgets(
      'says the platform does not record earnings per partnership',
      (tester) async {
        // This is the line between "you earned nothing" and "we did not
        // look". The card states the scope the platform actually keeps
        // (all brands together) and sends the creator to the ledger-backed
        // screen; it never states an amount, in either direction.
        await _pump(
          tester,
          const ActivePartnershipsScreen(),
          active: [_active(commissionRate: 0.15, vendorName: 'Hamro Pasal')],
        );

        final text = _allText(tester).join('\n');
        expect(text, contains('not'));
        expect(text, contains('per partnership'));
        expect(text, contains('Earnings'));
        expect(
          text,
          isNot(matches(RegExp(r'(Rs|NPR)\s*[\d.]'))),
          reason: 'the card must not state any amount',
        );
      },
    );

    testWidgets('the ended card carries no earnings row either', (
      tester,
    ) async {
      await _pump(
        tester,
        const ActivePartnershipsScreen(),
        ended: [_ended(commissionRate: 0.22)],
      );
      await tester.tap(find.text('Ended').first);
      await tester.pumpAndSettle();

      final text = _allText(tester).join('\n');
      expect(text, isNot(contains('Total Earnings')));
      expect(text, isNot(contains('Rs 0')));
      expect(text, contains('22% commission'));
      expect(text, contains('Campaign concluded'));
    });
  });

  // ── 4. Layout and controls ─────────────────────────────────────────────────

  group('layout and controls', () {
    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      await _pump(
        tester,
        const ActivePartnershipsScreen(),
        size: const Size(320, 900),
        textScale: 1.3,
        active: [
          _active(
            commissionRate: 0.15,
            vendorName: 'Sagarmatha Handloom Collective Pvt Ltd',
          ),
        ],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ended tab does not overflow at 320dp and 1.3', (tester) async {
      await _pump(
        tester,
        const ActivePartnershipsScreen(),
        size: const Size(320, 900),
        textScale: 1.3,
        ended: [_ended(commissionRate: 0.22)],
      );
      await tester.tap(find.text('Ended').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the earnings note is a labelled control that navigates', (
      tester,
    ) async {
      await _pump(
        tester,
        const ActivePartnershipsScreen(),
        active: [_active(commissionRate: 0.15, vendorName: 'Hamro Pasal')],
      );

      final note = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.button ?? false) &&
            (w.properties.label ?? '').contains('not recorded per partnership'),
      );
      expect(note, findsOneWidget);

      await tester.tap(note, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_lastRoute, RouteNames.earnings);
    });

    testWidgets('View Analytics is reachable and navigates', (tester) async {
      await _pump(
        tester,
        const ActivePartnershipsScreen(),
        active: [_active(commissionRate: 0.15, vendorName: 'Hamro Pasal')],
      );

      await tester.tap(find.text('View Analytics'));
      await tester.pumpAndSettle();
      expect(_lastRoute, RouteNames.creatorAnalytics);
    });

    testWidgets('every tappable on the card carries a spoken name', (
      tester,
    ) async {
      await _pump(
        tester,
        const ActivePartnershipsScreen(),
        active: [_active(commissionRate: 0.15, vendorName: 'Hamro Pasal')],
      );

      // Each control is reachable by the name a screen reader would speak.
      for (final label in const ['Message', 'View Terms', 'View Analytics']) {
        expect(
          find.text(label),
          findsOneWidget,
          reason: '$label is missing its visible, spoken name',
        );
      }
    });
  });

  // ── 5. The brand logo ──────────────────────────────────────────────────────

  group('brand logo', () {
    testWidgets('a brand with a logo gets its logo, not a letter', (
      tester,
    ) async {
      const url = 'https://cdn.example.com/brands/hamro-pasal.png';
      await _pump(
        tester,
        const PartnershipRequestsScreen(),
        active: [
          _active(
            commissionRate: 0.15,
            vendorName: 'Hamro Pasal',
            vendorLogoUrl: url,
          ),
        ],
      );
      // The Accepted tab is where active partnerships are listed.
      await tester.tap(find.textContaining('Accepted').first);
      await tester.pumpAndSettle();

      final images = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => i.image)
          .whereType<NetworkImage>()
          .map((n) => n.url)
          .toList();
      expect(images, contains(url));
    });

    testWidgets('a brand with no logo still gets its initial', (tester) async {
      await _pump(
        tester,
        const PartnershipRequestsScreen(),
        active: [_active(commissionRate: 0.15, vendorName: 'Hamro Pasal')],
      );
      await tester.tap(find.textContaining('Accepted').first);
      await tester.pumpAndSettle();

      expect(find.text('H'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
