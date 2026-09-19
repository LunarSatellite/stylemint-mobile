import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/reel_earnings_projection.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/tag_product_commission.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/reel_published_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/review_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/potential_earnings_card.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// **The ten percent that outlived its own removal.**
///
/// The product chips on Tag Products were taught to show the real commission
/// — `GET /v1/creator/tag-products/commission`, the creator's actual
/// partnership term. The header directly above them was not. It kept summing
/// `product.price.amount * 0.10`, drew it as "Est. Potential Earnings",
/// broke it down as `12 * ~Rs 300 = ~Rs 3,600 (est.)`, and handed it to the
/// Review and Published screens as `ReviewReelArgs.potentialEarningsPerSale`,
/// an `int` those screens multiplied by fifty. So one screen showed a
/// creator a real rate and an invented one at the same time, inches apart.
///
/// These tests are about the case that decides whether the replacement is
/// honest rather than merely different: **the mixed basket**. Two tagged
/// products have a partnership, three have no answer. The sum over the two,
/// drawn as *the* potential earnings, is a false statement about someone's
/// income — quieter than the ten percent but the same kind of lie. So a
/// figure that does not cover the whole basket has to say what it covers.
///
/// Three outcomes are kept strictly apart, because collapsing any two of
/// them is how fabricated figures get in:
///
///   * **A stated figure**, including a genuine `Rs 0.00` from a recorded 0%
///     term. Zero that somebody agreed to is knowledge.
///   * **A stated none** — `NoPartnership`. The server answered; nothing is
///     earned on that product. It is covered, contributes nothing, and no
///     `Money` is invented for it.
///   * **No answer** — `ProductUnavailable`, an `Applies` row with no money,
///     a lookup in flight, a lookup that failed. It is never a zero.

// ── Builders ─────────────────────────────────────────────────────────────────

TagProductCommission _applies(
  String id, {
  required double? perSale,
  double rate = 0.15,
  String currency = 'NPR',
}) => TagProductCommission(
  productId: id,
  status: TagProductCommissionStatus.applies,
  partnershipId: 'p-$id',
  commissionRateFraction: rate,
  commissionPerSale: perSale == null
      ? null
      : Money(amount: perSale, currency: currency),
);

TagProductCommission _noPartnership(String id) => TagProductCommission(
  productId: id,
  status: TagProductCommissionStatus.noPartnership,
);

TagProductCommission _unavailable(String id) => TagProductCommission(
  productId: id,
  status: TagProductCommissionStatus.productUnavailable,
);

TaggedProductForImport _product(String id, {String name = 'Kurta'}) =>
    TaggedProductForImport(
      productId: id,
      productName: name,
      imageUrl: '',
      price: const Money(amount: 3000, currency: 'NPR'),
      vendorName: 'Hamro Pasal',
    );

ReviewReelArgs _args(ReelEarningsProjection? earnings, {int products = 1}) =>
    ReviewReelArgs(
      reel: null,
      taggedProducts: [
        for (var i = 0; i < products; i++) _product('p$i', name: 'Item $i'),
      ],
      earnings: earnings,
    );

// ── Pumping ──────────────────────────────────────────────────────────────────

Future<void> _pumpCard(
  WidgetTester tester, {
  required List<TaggedProductForImport> products,
  required Map<String, TagProductCommission>? commissions,
  bool expanded = true,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final projection = ReelEarningsProjection.fold(
    products.map((p) => commissions?[p.productId]),
  );

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PotentialEarningsCard(
              projection: projection,
              isExpanded: expanded,
              onToggle: () {},
              taggedProducts: products,
              commissions: commissions,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(home: screen),
      ),
    ),
  );
  await tester.pump();
}

String _allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((s) => s.isNotEmpty)
    .join('\n');

void main() {
  // ── 1. The fold: what is known, what is stated as none, what is not known ──

  group('ReelEarningsProjection.fold', () {
    test('adds the server per-sale figures, and does not touch the price', () {
      final p = ReelEarningsProjection.fold([
        _applies('a', perSale: 450),
        _applies('b', perSale: 120),
      ]);

      expect(p.perSale, const Money(amount: 570, currency: 'NPR'));
      expect(p.statedProducts, 2);
      expect(p.unknownProducts, 0);
      expect(p.coversEverything, isTrue);
      expect(p.isPartial, isFalse);
    });

    test('a mixed basket keeps the unknowns visible, not folded into zero', () {
      final p = ReelEarningsProjection.fold([
        _applies('a', perSale: 450),
        _applies('b', perSale: 150),
        _unavailable('c'),
        null, // still in flight
        _applies('e', perSale: null), // a rate with no money behind it
      ]);

      expect(p.perSale, const Money(amount: 600, currency: 'NPR'));
      expect(p.statedProducts, 2);
      expect(p.unknownProducts, 3);
      expect(p.totalProducts, 5);
      expect(p.isPartial, isTrue);
      expect(p.coversEverything, isFalse);
    });

    test('a 0% term is a real contribution of zero, and is covered', () {
      final p = ReelEarningsProjection.fold([
        _applies('a', rate: 0, perSale: 0),
      ]);

      // Not null. Zero that a partnership agreed to is a figure.
      expect(p.perSale, const Money(amount: 0, currency: 'NPR'));
      expect(p.hasFigure, isTrue);
      expect(p.statedProducts, 1);
      expect(p.unknownProducts, 0);
      expect(p.isSilent, isFalse);
    });

    test('a 0% term next to a paying one contributes its zero', () {
      final p = ReelEarningsProjection.fold([
        _applies('a', rate: 0, perSale: 0),
        _applies('b', perSale: 450),
      ]);

      expect(p.perSale, const Money(amount: 450, currency: 'NPR'));
      expect(p.coversEverything, isTrue, reason: 'both products answered');
    });

    test('NoPartnership is covered and supplies no money of its own', () {
      final p = ReelEarningsProjection.fold([
        _noPartnership('a'),
        _noPartnership('b'),
      ]);

      // A stated none. Covered — and still no numeral, because the server
      // supplied none and one is not invented.
      expect(p.perSale, isNull);
      expect(p.hasFigure, isFalse);
      expect(p.statedProducts, 2);
      expect(p.unknownProducts, 0);
      expect(p.coversEverything, isTrue);
      expect(p.isSilent, isFalse);
    });

    test('a basket nothing is known about is silent, not zero', () {
      final p = ReelEarningsProjection.fold([
        _unavailable('a'),
        null,
        null,
      ]);

      expect(p.perSale, isNull);
      expect(p.hasFigure, isFalse);
      expect(p.statedProducts, 0);
      expect(p.unknownProducts, 3);
      expect(p.isSilent, isTrue);
      expect(p.isPartial, isFalse, reason: 'nothing is known to be partial');
    });

    test('an empty basket projects nothing', () {
      final p = ReelEarningsProjection.fold(const []);
      expect(p.perSale, isNull);
      expect(p.totalProducts, 0);
      expect(p.isSilent, isTrue);
      expect(p.coversEverything, isFalse);
    });

    test('two currencies are not added into one figure', () {
      final p = ReelEarningsProjection.fold([
        _applies('a', perSale: 450),
        _applies('b', perSale: 10, currency: 'USD'),
      ]);

      expect(p.perSale, isNull);
      expect(p.unknownProducts, 2, reason: 'neither figure can be stated');
    });

    test('projectedOver multiplies the stated money, or stays null', () {
      final known = ReelEarningsProjection.fold([_applies('a', perSale: 450)]);
      expect(
        known.projectedOver(50),
        const Money(amount: 22500, currency: 'NPR'),
      );

      final unknown = ReelEarningsProjection.fold([_unavailable('a')]);
      expect(unknown.projectedOver(50), isNull);
    });
  });

  // ── 2. The card: a partial total says what it covers ──────────────────────

  group('the earnings card', () {
    testWidgets('a mixed basket states its coverage next to the figure', (
      tester,
    ) async {
      final products = [
        _product('a', name: 'Dhaka Topi'),
        _product('b', name: 'Pashmina'),
        _product('c', name: 'Chappal'),
      ];
      await _pumpCard(
        tester,
        products: products,
        commissions: {'a': _applies('a', perSale: 450)},
      );

      final text = _allText(tester);
      expect(text, contains('Rs 450.00 per sale'));
      expect(
        text,
        contains('Covers 1 of 3 tagged products'),
        reason: 'a total over part of the basket must say which part',
      );
      expect(text, contains('The other 2 have no commission figure'));
      // The two unanswered products carry no arithmetic of their own.
      expect(text, contains('Pashmina'));
      expect(text, isNot(contains('Rs 0')));
    });

    testWidgets('a fully answered basket claims the whole basket', (
      tester,
    ) async {
      final products = [_product('a'), _product('b', name: 'Pashmina')];
      await _pumpCard(
        tester,
        products: products,
        commissions: {
          'a': _applies('a', perSale: 450),
          'b': _noPartnership('b'),
        },
      );

      final text = _allText(tester);
      expect(text, contains('Rs 450.00 per sale'));
      expect(text, contains('Across all 2 tagged products'));
      expect(text, isNot(contains('Covers')));
      // The product that earns nothing says so, with no numeral.
      expect(text, contains('No commission applies'));
    });

    testWidgets('a basket of nothing but NoPartnership draws no numeral', (
      tester,
    ) async {
      final products = [_product('a'), _product('b', name: 'Pashmina')];
      await _pumpCard(
        tester,
        products: products,
        commissions: {
          'a': _noPartnership('a'),
          'b': _noPartnership('b'),
        },
      );

      final text = _allText(tester);
      expect(text, contains('No commission applies'));
      expect(text, contains('None of your 2 tagged products earns a'));
      expect(
        text,
        isNot(matches(RegExp(r'Rs\s*[\d.,]'))),
        reason: 'no partnership means no figure, not Rs 0',
      );
    });

    testWidgets('a 0% product shows its real zero', (tester) async {
      final products = [_product('a', name: 'Dhaka Topi')];
      await _pumpCard(
        tester,
        products: products,
        commissions: {'a': _applies('a', rate: 0, perSale: 0)},
      );

      final text = _allText(tester);
      expect(
        text,
        contains('Rs 0.00 per sale'),
        reason: 'a recorded zero is a figure and is drawn as one',
      );
      expect(text, contains('Across all 1 tagged product'));
      // And it is not confused with the absence next door.
      expect(text, isNot(contains('No commission applies')));
    });

    testWidgets('the breakdown draws nothing for a product with no answer', (
      tester,
    ) async {
      final products = [_product('a', name: 'Dhaka Topi')];
      await _pumpCard(
        tester,
        products: products,
        commissions: {'a': _unavailable('a')},
      );

      final text = _allText(tester);
      expect(text, contains('Dhaka Topi'));
      expect(text, isNot(contains('Rs')));
      expect(text, isNot(contains('est')));
      expect(text, isNot(contains('=')));
    });

    testWidgets('a lookup still in flight is not a zero', (tester) async {
      final products = [_product('a', name: 'Dhaka Topi')];
      await _pumpCard(tester, products: products, commissions: null);

      final projection = ReelEarningsProjection.fold(
        products.map((_) => null),
      );
      expect(projection.isSilent, isTrue, reason: 'the card is not drawn');
      expect(_allText(tester), isNot(contains('Rs 0')));
    });

    testWidgets('no overflow at 320dp and a 1.3 text scale', (tester) async {
      final products = [
        _product('a', name: 'Handwoven Dhaka Topi, Palpali'),
        _product('b', name: 'Pashmina Shawl, Natural Dye'),
        _product('c', name: 'Chappal'),
      ];
      await _pumpCard(
        tester,
        products: products,
        commissions: {
          'a': _applies('a', perSale: 1450.5),
          'b': _noPartnership('b'),
        },
        size: const Size(320, 900),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });
  });

  // ── 3. Review and Published draw nothing when the figure is absent ────────

  group('the Review screen', () {
    testWidgets('draws no earnings line when nothing is known', (tester) async {
      await _pumpScreen(
        tester,
        ReviewReelScreen(
          args: _args(
            ReelEarningsProjection.fold([_unavailable('p0')]),
          ),
        ),
      );

      final text = _allText(tester);
      expect(text, isNot(contains('Potential Earnings')));
      expect(text, isNot(contains('with 50 sales')));
      expect(text, isNot(contains('Rs 0')));
    });

    testWidgets('draws no earnings line when there is no projection at all', (
      tester,
    ) async {
      await _pumpScreen(tester, ReviewReelScreen(args: _args(null)));
      expect(_allText(tester), isNot(contains('Potential Earnings')));
    });

    testWidgets('a partial total says what it covers', (tester) async {
      await _pumpScreen(
        tester,
        ReviewReelScreen(
          args: _args(
            ReelEarningsProjection.fold([
              _applies('p0', perSale: 450),
              _unavailable('p1'),
            ]),
            products: 2,
          ),
        ),
      );

      final text = _allText(tester);
      expect(text, contains('Rs 22,500.00 with 50 sales'));
      expect(text, contains('Covers 1 of 2 tagged products'));
    });

    testWidgets('a complete total carries no coverage hedge', (tester) async {
      await _pumpScreen(
        tester,
        ReviewReelScreen(
          args: _args(
            ReelEarningsProjection.fold([_applies('p0', perSale: 450)]),
          ),
        ),
      );

      final text = _allText(tester);
      expect(text, contains('Rs 22,500.00 with 50 sales'));
      expect(text, isNot(contains('Covers')));
    });

    testWidgets('the partial total fits at 320dp and a 1.3 text scale', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        ReviewReelScreen(
          args: _args(
            ReelEarningsProjection.fold([
              _applies('p0', perSale: 1450.5),
              _unavailable('p1'),
            ]),
            products: 2,
          ),
        ),
        size: const Size(320, 900),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('the Published screen', () {
    testWidgets('draws no earnings line when nothing is known', (tester) async {
      await _pumpScreen(
        tester,
        ReelPublishedScreen(
          args: _args(ReelEarningsProjection.fold([_unavailable('p0')])),
        ),
      );

      final text = _allText(tester);
      expect(text, isNot(contains('Potential Earnings')));
      expect(text, isNot(contains('Rs 0')));
    });

    testWidgets('draws no earnings line for a NoPartnership basket', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        ReelPublishedScreen(
          args: _args(ReelEarningsProjection.fold([_noPartnership('p0')])),
        ),
      );

      // Covered, but there is no money figure — so no money is drawn.
      expect(_allText(tester), isNot(contains('Potential Earnings')));
    });

    testWidgets('a partial total says what it covers', (tester) async {
      await _pumpScreen(
        tester,
        ReelPublishedScreen(
          args: _args(
            ReelEarningsProjection.fold([
              _applies('p0', perSale: 450),
              _noPartnership('p1'),
              _unavailable('p2'),
            ]),
            products: 3,
          ),
        ),
      );

      final text = _allText(tester);
      expect(text, contains('Rs 22,500.00 with 50 sales'));
      expect(text, contains('Covers 2 of 3 tagged products'));
      expect(text, contains('The other 1 has no commission figure'));
    });

    testWidgets('the partial total fits at 320dp and a 1.3 text scale', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        ReelPublishedScreen(
          args: _args(
            ReelEarningsProjection.fold([
              _applies('p0', perSale: 1450.5),
              _unavailable('p1'),
            ]),
            products: 2,
          ),
        ),
        size: const Size(320, 900),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });
  });

  // ── 4. The constant cannot come back ──────────────────────────────────────

  group('the hardcoded ten percent is gone from the feature', () {
    const featureDir = 'lib/features/creator/reel_import';

    /// Every `.dart` file in the feature, comments stripped.
    ///
    /// The bans are about what the app **computes and renders**, never about
    /// what a comment may explain: the files that removed the constant name
    /// it in prose so the next reader knows what went and why, and that prose
    /// must not fail the guard that keeps it gone. Stripping is deliberately
    /// crude — a `//` inside a string truncates that line — which can only
    /// hide a match, never invent one.
    Map<String, String> code() {
      final out = <String, String>{};
      for (final entity in Directory(featureDir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('.freezed.dart')) {
          continue;
        }
        out[entity.path.replaceAll(r'\', '/')] = entity
            .readAsStringSync()
            .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
            .replaceAll(RegExp('//.*'), '');
      }
      return out;
    }

    test('the feature has files to scan', () {
      expect(code(), isNotEmpty);
      expect(
        code().keys,
        contains(
          '$featureDir/presentation/widgets/potential_earnings_card.dart',
        ),
      );
    });

    test('nothing derives a commission from a hardcoded percentage', () {
      const banned = <String, String>{
        r'\*\s*0?\.10\b': 'multiplying by a hardcoded ten percent',
        r'0?\.10\s*\*': 'multiplying by a hardcoded ten percent',
        r'\*\s*0?\.1\b': 'multiplying by a hardcoded tenth',
        r'0?\.1\s*\*': 'multiplying by a hardcoded tenth',
        r'\bpct\s*=\s*10\b': 'a hardcoded ten percent rate',
        r'\bcommissionRate\s*=\s*0?\.\d': 'a hardcoded commission rate',
        r'price\.amount\s*\*': 'deriving commission from the shelf price',
        r'\.price\.amount\s*\)?\s*\*': 'deriving commission from the price',
      };

      for (final entry in code().entries) {
        for (final ban in banned.entries) {
          expect(
            entry.value,
            isNot(matches(RegExp(ban.key))),
            reason: '${entry.key}: ${ban.value}',
          );
        }
      }
    });

    test('no screen carries an int per-sale figure any more', () {
      for (final entry in code().entries) {
        expect(
          entry.value,
          isNot(contains('potentialEarningsPerSale')),
          reason:
              '${entry.key}: an int cannot say "unknown" or "this covers two '
              'of your five products"',
        );
      }
    });

    test('no estimate hedge is rendered over a computed figure', () {
      for (final entry in code().entries) {
        expect(entry.value, isNot(contains('(est.)')), reason: entry.key);
        expect(
          entry.value,
          isNot(contains('Est. Potential Earnings')),
          reason: entry.key,
        );
        expect(
          entry.value,
          isNot(matches(RegExp(r"'~Rs|~Rs \$"))),
          reason: '${entry.key}: a tilde over a real figure is a hedge',
        );
      }
    });
  });
}
