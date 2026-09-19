import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/partnership_figures_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_figures.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/partnership_figures_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/widgets/partnership_figures_section.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';

/// **The two figures that came back, and the absence that did not.**
///
/// Four per-brand figures were removed from the creator's brand cards on
/// 2026-09-20 because nothing recorded them (see
/// `partnership_earnings_honesty_test.dart`, which still guards that removal
/// and must keep passing alongside this file). Two of the four are now
/// served, and these tests hold the line the new contract draws:
///
///   * `Attribution: "Unknown"` means **nobody can say** — every total comes
///     back null and the card must draw no numeral for any of them.
///   * `Attribution: "Attributed"` with `TotalEarnings: 0` means **we looked
///     and the answer is nothing** — a recorded zero, which must reach the
///     screen as a zero.
///
/// If those two ever render the same way, the backend work is undone and the
/// fabricated-zero defect is back in the opposite direction. Everything here
/// exists to make that failure loud.
///
/// Also pinned: a totals list spanning more than one currency is never added
/// into a single amount; `UnattributedLinkCountForPair` is presented as the
/// completeness signal it is and never as earnings; products tagged renders
/// its real zero; and the invented "Est. 10% commission" is gone from both
/// sites that drew it.

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeFiguresRepository implements PartnershipFiguresRepository {
  _FakeFiguresRepository({this.earnings, this.tags});

  final PartnershipAffiliateEarnings? earnings;
  final PartnershipTagCounts? tags;

  @override
  Future<Either<NetworkExceptions, PartnershipAffiliateEarnings>>
  getAffiliateEarnings(String partnershipId) async {
    final value = earnings;
    return value == null
        ? left(const NetworkExceptions.unexpectedError())
        : right(value);
  }

  @override
  Future<Either<NetworkExceptions, PartnershipTagCounts>> getTagCounts(
    String partnershipId,
  ) async {
    final value = tags;
    return value == null
        ? left(const NetworkExceptions.unexpectedError())
        : right(value);
  }
}

// ── Harness ──────────────────────────────────────────────────────────────────

Future<void> _pumpSection(
  WidgetTester tester, {
  PartnershipAffiliateEarnings? earnings,
  PartnershipTagCounts? tags,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        partnershipFiguresRepositoryProvider.overrideWithValue(
          _FakeFiguresRepository(earnings: earnings, tags: tags),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PartnershipFiguresSection(partnershipId: 'p-1'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Everything the section puts on screen, drawn or spoken. A figure
/// whispered to a screen reader is still a figure.
List<String> _sectionText(WidgetTester tester) {
  final section = find.byType(PartnershipFiguresSection);
  return <String>[
    ...tester
        .widgetList<Text>(
          find.descendant(of: section, matching: find.byType(Text)),
        )
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? ''),
    ...tester
        .widgetList<RichText>(
          find.descendant(of: section, matching: find.byType(RichText)),
        )
        .map((t) => t.text.toPlainText()),
    ...tester
        .widgetList<Semantics>(
          find.descendant(of: section, matching: find.byType(Semantics)),
        )
        .map((s) => s.properties.label ?? ''),
  ].where((s) => s.isNotEmpty).toList();
}

String _joined(WidgetTester tester) => _sectionText(tester).join('\n');

const AffiliateAttribution _attributed = AffiliateAttribution.attributed;

void main() {
  // ── 1. Unknown is not a zero ───────────────────────────────────────────────

  group('Attribution: Unknown', () {
    testWidgets('renders the not-tracked state and no numeral at all', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings.notAttributed(),
      );

      final text = _joined(tester);
      expect(text, contains('Not tracked for this brand yet'));
      expect(text, contains('not'));
      expect(text, contains('per partnership'));
      expect(text, contains('Earnings'));

      // The whole point: not a digit anywhere in the block. No zero, no
      // dash, no "Rs --" holding the slot a number belongs in.
      expect(
        text,
        isNot(matches(RegExp(r'\d'))),
        reason: 'Unknown must draw no numeral: $text',
      );
      expect(text, isNot(contains('--')));
      expect(text, isNot(contains('Rs')));
      expect(text, isNot(contains('Recorded for this brand')));
    });

    testWidgets('is visibly and semantically distinct from a recorded zero', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings.notAttributed(),
      );
      final unknown = _joined(tester);

      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings(
          attribution: _attributed,
          currencies: ['NPR'],
          unattributedLinkCountForPair: 0,
          totalEarnings: 0,
          totalConversions: 0,
          totalClicks: 12,
        ),
      );
      final recordedZero = _joined(tester);

      expect(unknown, isNot(equals(recordedZero)));
      expect(unknown, contains('Not tracked for this brand yet'));
      expect(recordedZero, contains('Recorded for this brand'));
      expect(recordedZero, isNot(contains('Not tracked for this brand yet')));
    });

    testWidgets('explains unattributed links without claiming them', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings.notAttributed(
          unattributedLinkCountForPair: 3,
        ),
      );

      final text = _joined(tester);
      // It is a completeness signal: it says why the server cannot answer.
      expect(text, contains('3 affiliate links'));
      expect(text, contains('carry no partnership'));
      // And it disclaims itself, so no reader takes it for money.
      expect(text, contains('They are not earnings on this partnership.'));
      // It is never dressed as an amount.
      expect(text, isNot(contains('Rs')));
      expect(text, isNot(contains('earned')));
    });

    testWidgets('says nothing about links when there are none', (tester) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings.notAttributed(),
      );
      expect(_joined(tester), isNot(contains('affiliate link')));
    });
  });

  // ── 2. A recorded zero is a zero ───────────────────────────────────────────

  group('Attribution: Attributed', () {
    testWidgets('a recorded zero renders as a real zero', (tester) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings(
          attribution: _attributed,
          currencies: ['NPR'],
          unattributedLinkCountForPair: 0,
          totalEarnings: 0,
          totalConversions: 0,
          totalClicks: 12,
        ),
      );

      final text = _joined(tester);
      expect(text, contains('Recorded for this brand'));
      // The zero itself, as an amount, under a chip that says it was looked
      // up. This is the answer "you made nothing here" — which is different
      // from "we cannot say", and is allowed to be a zero.
      expect(text, contains('Rs 0'));
      expect(text, contains('0 sales'));
      expect(text, contains('12 link clicks'));
      expect(text, isNot(contains('Not tracked')));
    });

    testWidgets('real money renders as the money it is', (tester) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings(
          attribution: _attributed,
          currencies: ['NPR'],
          unattributedLinkCountForPair: 0,
          totalEarnings: 1250,
          totalRevenue: 12000,
          totalConversions: 3,
          totalClicks: 87,
        ),
      );

      final text = _joined(tester);
      expect(text, contains('Rs 1,250.00'));
      expect(text, contains('3 sales from 87 link clicks'));
      // Order value is labelled as order value, not as the creator's cut.
      expect(text, contains('Rs 12,000.00 of orders attributed'));
      // The interim "we do not record per partnership" copy is gone here:
      // it would sit directly under a per-partnership figure.
      expect(text, isNot(contains('not per partnership')));
    });

    testWidgets('one sale and one click read in the singular', (tester) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings(
          attribution: _attributed,
          currencies: ['NPR'],
          unattributedLinkCountForPair: 0,
          totalEarnings: 400,
          totalConversions: 1,
          totalClicks: 1,
        ),
      );
      expect(_joined(tester), contains('1 sale from 1 link click'));
    });

    testWidgets('no conversions at all carries the zero on the counts', (
      tester,
    ) async {
      // `Currencies` is empty when nothing converted, so there is no currency
      // to print an amount in — the recorded zero is carried by the counts
      // rather than dressed in a currency nobody recorded.
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings(
          attribution: _attributed,
          currencies: [],
          unattributedLinkCountForPair: 0,
          totalEarnings: 0,
          totalConversions: 0,
          totalClicks: 40,
        ),
      );

      final text = _joined(tester);
      expect(text, contains('Recorded for this brand'));
      expect(text, contains('Nothing earned yet'));
      expect(text, contains('0 sales from 40 link clicks'));
      expect(text, isNot(contains('Not tracked')));
    });
  });

  // ── 3. Currencies are not added together ───────────────────────────────────

  group('multiple currencies', () {
    testWidgets('never render as one amount', (tester) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings(
          attribution: _attributed,
          currencies: ['NPR', 'USD'],
          unattributedLinkCountForPair: 0,
          totalEarnings: 1250,
          totalRevenue: 12000,
          totalConversions: 5,
          totalClicks: 120,
        ),
      );

      final text = _joined(tester);
      // The sum exists on the wire; it is not a number anyone can spend, so
      // it is not printed with a currency on it.
      expect(text, isNot(contains('Rs 1,250')));
      expect(text, isNot(contains('Rs 12,000')));
      expect(
        text,
        isNot(matches(RegExp(r'(Rs|NPR|USD)\s*[\d,]+\.\d\d'))),
        reason: 'no single amount may stand for totals spanning currencies',
      );

      // What it says instead names the currencies and points at the ledger.
      expect(text, contains('Earned in 2 currencies: NPR, USD'));
      expect(text, contains('span more than one currency'));
      expect(text, contains('Open Earnings'));

      // The currency-free counts are still real and still drawn.
      expect(text, contains('5 sales from 120 link clicks'));
    });
  });

  // ── 4. Products tagged is real for every partnership ───────────────────────

  group('products tagged', () {
    testWidgets('a real count renders', (tester) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings.notAttributed(),
        tags: const PartnershipTagCounts(productCount: 3),
      );
      expect(_joined(tester), contains('3 products tagged'));
    });

    testWidgets('zero renders as zero, because zero is what was recorded', (
      tester,
    ) async {
      // Unlike earnings, this snapshot has been written at tag time since
      // tagging began. There is no unknown state to confuse it with.
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings.notAttributed(),
        tags: const PartnershipTagCounts(productCount: 0),
      );
      expect(_joined(tester), contains('0 products tagged'));
    });

    testWidgets('one product reads in the singular', (tester) async {
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings.notAttributed(),
        tags: const PartnershipTagCounts(productCount: 1),
      );
      expect(_joined(tester), contains('1 product tagged'));
    });

    testWidgets('a count that did not load draws nothing', (tester) async {
      // Absent is absent: a failed read is not a zero.
      await _pumpSection(
        tester,
        earnings: const PartnershipAffiliateEarnings.notAttributed(),
      );
      expect(_joined(tester), isNot(contains('products tagged')));
      expect(_joined(tester), isNot(contains('product tagged')));
    });
  });

  // ── 5. Active campaigns stays absent ───────────────────────────────────────

  testWidgets('active campaigns is never drawn, in any state', (tester) async {
    for (final earnings in <PartnershipAffiliateEarnings>[
      const PartnershipAffiliateEarnings.notAttributed(),
      const PartnershipAffiliateEarnings(
        attribution: _attributed,
        currencies: ['NPR'],
        unattributedLinkCountForPair: 0,
        totalEarnings: 0,
        totalConversions: 0,
        totalClicks: 0,
      ),
    ]) {
      await _pumpSection(
        tester,
        earnings: earnings,
        tags: const PartnershipTagCounts(productCount: 0),
      );
      final text = _joined(tester);
      expect(text, isNot(contains('Campaign')));
      expect(text, isNot(contains('campaign')));
    }
  });

  // ── 6. The DTO keeps nulls null ────────────────────────────────────────────

  group('PartnershipAffiliateEarningsDto', () {
    test('Unknown keeps every total null', () {
      final dto = PartnershipAffiliateEarningsDto.fromJson(const {
        'attribution': 'Unknown',
        'totalEarnings': null,
        'totalRevenue': null,
        'totalConversions': null,
        'totalClicks': null,
        'currencies': <String>[],
        'unattributedLinkCountForPair': 2,
      });
      final domain = dto.toDomain();

      expect(domain.isAttributed, isFalse);
      expect(domain.totalEarnings, isNull);
      expect(domain.totalRevenue, isNull);
      expect(domain.totalConversions, isNull);
      expect(domain.totalClicks, isNull);
      expect(domain.unattributedLinkCountForPair, 2);
    });

    test('Attributed keeps a recorded zero as a zero, not a null', () {
      final domain = PartnershipAffiliateEarningsDto.fromJson(const {
        'attribution': 'Attributed',
        'totalEarnings': 0,
        'totalConversions': 0,
        'totalClicks': 9,
        'currencies': ['NPR'],
        'unattributedLinkCountForPair': 0,
      }).toDomain();

      expect(domain.isAttributed, isTrue);
      expect(domain.totalEarnings, 0);
      expect(domain.totalConversions, 0);
      expect(domain.hasSingleCurrencyAmount, isTrue);
    });

    test('an unrecognised attribution falls to unknown, never to a total', () {
      final domain = PartnershipAffiliateEarningsDto.fromJson(const {
        'attribution': 'SomethingNewTheServerAdded',
        'totalEarnings': 500,
        'currencies': ['NPR'],
      }).toDomain();

      expect(domain.isAttributed, isFalse);
      expect(domain.totalEarnings, isNull);
    });

    test('several currencies are kept as several', () {
      final domain = PartnershipAffiliateEarningsDto.fromJson(const {
        'attribution': 'Attributed',
        'totalEarnings': 99,
        'currencies': ['NPR', 'USD'],
      }).toDomain();

      expect(domain.spansMultipleCurrencies, isTrue);
      expect(domain.singleCurrency, isNull);
      expect(domain.hasSingleCurrencyAmount, isFalse);
    });

    test('the tag count parses only the figure something reads', () {
      final domain = PartnershipTagCountsDto.fromJson(const {
        'partnershipId': 'p-1',
        'productCount': 0,
        'reelCount': 4,
        'taggedProductCount': 7,
      }).toDomain();

      expect(domain.productCount, 0);
    });
  });

  // ── 7. Layout at the width and scale that broke these cards before ─────────

  group('320dp at a 1.3 text scale', () {
    testWidgets('the not-tracked block does not overflow', (tester) async {
      await _pumpSection(
        tester,
        size: const Size(320, 900),
        textScale: 1.3,
        earnings: const PartnershipAffiliateEarnings.notAttributed(
          unattributedLinkCountForPair: 4,
        ),
        tags: const PartnershipTagCounts(productCount: 0),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the recorded block does not overflow', (tester) async {
      await _pumpSection(
        tester,
        size: const Size(320, 900),
        textScale: 1.3,
        earnings: const PartnershipAffiliateEarnings(
          attribution: _attributed,
          currencies: ['NPR'],
          unattributedLinkCountForPair: 0,
          totalEarnings: 1234567.89,
          totalRevenue: 9876543.21,
          totalConversions: 128,
          totalClicks: 9999,
        ),
        tags: const PartnershipTagCounts(productCount: 128),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the multi-currency block does not overflow', (tester) async {
      await _pumpSection(
        tester,
        size: const Size(320, 900),
        textScale: 1.3,
        earnings: const PartnershipAffiliateEarnings(
          attribution: _attributed,
          currencies: ['NPR', 'USD', 'EUR'],
          unattributedLinkCountForPair: 0,
          totalEarnings: 1250,
          totalConversions: 5,
          totalClicks: 120,
        ),
        tags: const PartnershipTagCounts(productCount: 3),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ── 8. The invented commission rate is gone from both sites ────────────

  group('the invented commission rate on Tag Products', () {
    const path =
        'lib/features/creator/reel_import/presentation/screens/'
        'tag_products_screen.dart';

    test('neither product chip computes a rate from a hardcoded percent', () {
      // Two `_commissionLabel()` methods, around lines 1013 and 1286, each
      // built "Est. 10% commission (~Rs 450 per sale)" from `const pct = 10`
      // and showed it to a creator choosing which products to tag. The real
      // rate is a term of their partnership and is now looked up — see
      // `test/features/creator/reel_import/tag_product_commission_test.dart`
      // for what replaced it.
      final source = File(path)
          .readAsStringSync()
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
          .replaceAll(RegExp('//.*'), '');
      expect(source, isNot(contains('const pct = 10')));
      expect(source, isNot(contains(r'Est. $pct% commission')));
      expect(source, isNot(contains('_commissionLabel')));
      expect(source, isNot(contains('Est. 10%')));
    });
  });
}
