import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_return_record.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/return_record_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

const _viewedId = 'p-viewed';

/// Every word this card is banned from putting on screen. The retired card
/// drew a Low/Medium/High chip in green, amber and red; an above-typical
/// return rate here is a count the shopper weighs, not an accusation, and
/// the server refuses to demote such a product for the same reason.
final RegExp _judgementWords = RegExp(
  'risk|danger|warning|bad|poor|avoid|caution|unsafe',
  caseSensitive: false,
);

const _basis = CategoryReturnBasis(
  categoryId: 'c-totes',
  available: true,
  productsCounted: 42,
  unitsSold: 12400,
  unitsReturned: 620,
  returnsPerHundredSold: 5,
);

const _unmeasuredBasis = CategoryReturnBasis(
  categoryId: 'c-totes',
  available: false,
  unavailableReason:
      'This category has not sold enough in the last 180 days to compare '
      'against (312 of the 500 needed).',
  productsCounted: 3,
  unitsSold: 312,
  unitsReturned: 9,
);

const _below = ProductReturnOption(
  position: 1,
  suppliedPosition: 2,
  productId: 'p-alt',
  productName: 'Canvas tote',
  hasEnoughSales: true,
  unitsSold: 412,
  unitsReturned: 12,
  returnsPerHundredSold: 3,
  comparedWithCategory: CategoryComparison.belowCategoryTypical,
  returnedUnits: ReturnedUnitSplit(
    classifiedReturns: 10,
    fitToResell: 7,
    notFitToResell: 3,
  ),
);

/// The viewed product, above its category's rate — and carrying no
/// [ProductReturnOption.returnedUnits], which is the common case.
const _above = ProductReturnOption(
  position: 2,
  suppliedPosition: 1,
  productId: _viewedId,
  productName: 'Leather tote',
  hasEnoughSales: true,
  unitsSold: 260,
  unitsReturned: 31,
  returnsPerHundredSold: 12,
  comparedWithCategory: CategoryComparison.aboveCategoryTypical,
);

/// Under the product minimum: no rate, no comparison, nothing.
const _thin = ProductReturnOption(
  position: 3,
  suppliedPosition: 3,
  productId: 'p-new',
  productName: 'Jute tote',
  hasEnoughSales: false,
  unitsSold: 8,
  unitsReturned: 1,
  comparedWithCategory: CategoryComparison.notEnoughData,
);

const _record = ProductReturnRecord(
  productId: _viewedId,
  categoryId: 'c-totes',
  windowDays: 180,
  orderingApplied: true,
  basis: _basis,
  options: [_below, _above, _thin],
);

/// Enough sales for a rate, but the category could not be measured, so there
/// is no comparison to state.
const _noComparison = ProductReturnRecord(
  productId: _viewedId,
  categoryId: 'c-totes',
  windowDays: 180,
  orderingApplied: false,
  orderingSkippedReason: 'This category has not been measured.',
  basis: _unmeasuredBasis,
  options: [
    ProductReturnOption(
      position: 1,
      suppliedPosition: 1,
      productId: _viewedId,
      productName: 'Leather tote',
      hasEnoughSales: true,
      unitsSold: 260,
      unitsReturned: 0,
      returnsPerHundredSold: 0,
      comparedWithCategory: CategoryComparison.notEnoughData,
    ),
  ],
);

/// A comparison value shipped by a newer server than this build knows.
const _unknownComparison = ProductReturnRecord(
  productId: _viewedId,
  categoryId: 'c-totes',
  windowDays: 180,
  orderingApplied: true,
  basis: _basis,
  options: [
    ProductReturnOption(
      position: 1,
      suppliedPosition: 1,
      productId: _viewedId,
      productName: 'Leather tote',
      hasEnoughSales: true,
      unitsSold: 260,
      unitsReturned: 31,
      returnsPerHundredSold: 12,
      comparedWithCategory: CategoryComparison.unknown,
    ),
  ],
);

/// Nothing countable at all — the card must not appear.
const _nothingCountable = ProductReturnRecord(
  productId: _viewedId,
  categoryId: 'c-totes',
  windowDays: 180,
  orderingApplied: false,
  basis: _unmeasuredBasis,
  options: [_thin],
);

Finder _option(String productId) =>
    find.byKey(ValueKey('return-record-option-$productId'));

List<String> _textsIn(WidgetTester tester, Finder scope) => tester
    .widgetList<Text>(find.descendant(of: scope, matching: find.byType(Text)))
    .map((t) => t.data ?? '')
    .where((t) => t.isNotEmpty)
    .toList();

void main() {
  late _MockDiscoveryRepository repository;

  setUp(() => repository = _MockDiscoveryRepository());

  void stub(ProductReturnRecord record) => when(
    () => repository.getReturnRecord(_viewedId),
  ).thenAnswer((_) async => right(record));

  Future<List<String>> pumpCard(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1,
  }) async {
    final opened = <String>[];
    tester.view
      ..physicalSize = Size(width, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReturnRecordCard(
                productId: _viewedId,
                onOpenProduct: opened.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  group('productReturnRecordProvider', () {
    Future<ProductReturnRecord?> read() async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        productReturnRecordProvider(_viewedId).future,
        (_, _) {},
      );
      return sub.read();
    }

    test('exposes a record with at least one countable option', () async {
      stub(_record);

      expect(await read(), same(_record));
    });

    test('is null when no option can be quoted', () async {
      stub(_nothingCountable);

      expect(await read(), isNull);
    });

    test('is null on a repository failure', () async {
      when(
        () => repository.getReturnRecord(_viewedId),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      expect(await read(), isNull);
    });

    test('is null when the repository throws', () async {
      when(
        () => repository.getReturnRecord(_viewedId),
      ).thenThrow(StateError('boom'));

      expect(await read(), isNull);
    });
  });

  group('ReturnRecordCard', () {
    testWidgets('names the window and the category it counted within', (
      tester,
    ) async {
      stub(_record);

      await pumpCard(tester);

      expect(find.text('Return record'), findsOneWidget);
      expect(
        find.text(
          'How often these came back, counted within this category over '
          'the last 180 days.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('states the category basis as a rate with its own counts, '
        'and says the comparison is against that rate', (tester) async {
      stub(_record);

      await pumpCard(tester);

      final basis = _textsIn(
        tester,
        find.byKey(const ValueKey('return-record-basis')),
      );
      expect(basis, contains('In this category: 5 returns per 100 sold.'));
      expect(
        basis,
        contains(
          '620 of the 12,400 sold in the last 180 days came back, across 42 '
          'products with a sales history.',
        ),
      );
      expect(
        basis,
        contains(
          "Each comparison below is against this category's own measured "
          'rate, not an overall standard.',
        ),
      );
    });

    testWidgets('never shows a rate without the two counts behind it', (
      tester,
    ) async {
      stub(_record);

      await pumpCard(tester);

      const scopes = [
        'return-record-basis',
        'return-record-option-p-alt',
        'return-record-option-$_viewedId',
      ];
      var rateCount = 0;
      for (final key in scopes) {
        final texts = _textsIn(tester, find.byKey(ValueKey(key)));
        final rates = texts.where((t) => t.contains('per 100 sold'));
        expect(rates, hasLength(1), reason: key);
        rateCount += rates.length;
        expect(
          texts.any(
            (t) => RegExp(r'\d[\d,]* sold in the last \d+ days').hasMatch(t),
          ),
          isTrue,
          reason: 'no denominator beside the rate in $key',
        );
      }
      // Nothing quotes a rate outside those three blocks.
      expect(find.textContaining('per 100 sold'), findsNWidgets(rateCount));
      // And nothing anywhere is a bare percentage.
      final all = _textsIn(tester, find.byType(ReturnRecordCard));
      expect(all.any((t) => t.contains('%')), isFalse);
    });

    testWidgets('an option renders its own counts in full', (tester) async {
      stub(_record);

      await pumpCard(tester);

      final texts = _textsIn(tester, _option('p-alt'));
      expect(texts, contains('Canvas tote'));
      expect(texts, contains('3 returns per 100 sold'));
      expect(
        texts,
        contains('12 of the 412 sold in the last 180 days came back'),
      );
    });

    testWidgets('a product with no returns still names its denominator', (
      tester,
    ) async {
      stub(_noComparison);

      await pumpCard(tester);

      final texts = _textsIn(tester, _option(_viewedId));
      expect(texts, contains('0 returns per 100 sold'));
      expect(
        texts,
        contains('None of the 260 sold in the last 180 days came back'),
      );
    });

    testWidgets('the only comparison is within-category, by glyph and word', (
      tester,
    ) async {
      stub(_record);

      await pumpCard(tester);

      expect(
        _textsIn(tester, _option('p-alt')),
        contains('Comes back less often than others in this category'),
      );
      expect(
        _textsIn(tester, _option(_viewedId)),
        contains('Comes back more often than others in this category'),
      );
      // Each comparison carries a glyph, so colour is never the only carrier.
      for (final id in ['p-alt', _viewedId]) {
        expect(
          find.descendant(of: _option(id), matching: find.byType(Icon)),
          findsWidgets,
          reason: id,
        );
      }
      expect(
        categoryComparisonGlyph(CategoryComparison.belowCategoryTypical),
        isNot(categoryComparisonGlyph(CategoryComparison.aboveCategoryTypical)),
      );
    });

    testWidgets('an option below the sales minimum renders nothing at all — '
        'no zero, no dash, no empty slot', (tester) async {
      stub(_record);

      await pumpCard(tester);

      expect(_option('p-new'), findsNothing);
      expect(find.text('Jute tote'), findsNothing);
      final all = _textsIn(tester, find.byType(ReturnRecordCard));
      expect(all.any((t) => t.trim() == '—'), isFalse);
      expect(all.any((t) => t.trim() == '-'), isFalse);
      expect(all.any((t) => t.toLowerCase().contains('no data')), isFalse);
      expect(
        all.any((t) => t.toLowerCase().contains('not enough')),
        isFalse,
      );
    });

    testWidgets('renders nothing when no option can be quoted', (
      tester,
    ) async {
      stub(_nothingCountable);

      await pumpCard(tester);

      expect(find.byKey(const ValueKey('return-record-card')), findsNothing);
      expect(find.text('Return record'), findsNothing);
    });

    testWidgets('NotEnoughData states no comparison and no placeholder for '
        'one', (tester) async {
      stub(_noComparison);

      await pumpCard(tester);

      final texts = _textsIn(tester, _option(_viewedId));
      expect(
        texts.any((t) => t.contains('than others in this category')),
        isFalse,
      );
      expect(texts.any((t) => t.contains('about as often')), isFalse);
      // The basis says plainly why, in the server's own words.
      expect(
        _textsIn(tester, find.byKey(const ValueKey('return-record-basis'))),
        contains(_unmeasuredBasis.unavailableReason),
      );
    });

    testWidgets('an unrecognised comparison degrades to no comparison, and '
        'the counts still stand', (tester) async {
      stub(_unknownComparison);

      await pumpCard(tester);

      expect(tester.takeException(), isNull);
      final texts = _textsIn(tester, _option(_viewedId));
      expect(
        texts.any((t) => t.contains('than others in this category')),
        isFalse,
      );
      expect(texts, contains('12 returns per 100 sold'));
      expect(categoryComparisonLabel(CategoryComparison.unknown), isNull);
      expect(categoryComparisonLabel(CategoryComparison.notEnoughData), isNull);
    });

    testWidgets('a null returnedUnits renders nothing, never zeros', (
      tester,
    ) async {
      stub(_record);

      await pumpCard(tester);

      final viewed = _textsIn(tester, _option(_viewedId));
      expect(viewed.any((t) => t.contains('returned units')), isFalse);
      expect(viewed.any((t) => t.contains('back into stock')), isFalse);
      expect(viewed.any((t) => t.contains('was recorded')), isFalse);
      // Name, rate, counts, comparison, and nothing standing in for the
      // split that was never classified.
      expect(viewed, [
        'Leather tote',
        'This one',
        '12 returns per 100 sold',
        '31 of the 260 sold in the last 180 days came back',
        'Comes back more often than others in this category',
      ]);
    });

    testWidgets('a present returnedUnits is a handling record, and says so', (
      tester,
    ) async {
      stub(_record);

      await pumpCard(tester);

      final texts = _textsIn(tester, _option('p-alt'));
      expect(
        texts,
        contains(
          'Of 10 returned units whose handling was recorded, 7 went straight '
          'back into stock and 3 did not.',
        ),
      );
      expect(
        texts,
        contains(
          'This records where a returned unit was sent, not why it came back.',
        ),
      );
    });

    testWidgets('no judgement or risk vocabulary reaches the screen', (
      tester,
    ) async {
      for (final record in [_record, _noComparison, _unknownComparison]) {
        stub(record);

        await pumpCard(tester);

        final offenders = _textsIn(
          tester,
          find.byType(ReturnRecordCard),
        ).where(_judgementWords.hasMatch).toList();
        expect(offenders, isEmpty, reason: 'judgement wording on screen');
      }
    });

    testWidgets('the retired score and level vocabulary is gone', (
      tester,
    ) async {
      stub(_record);

      await pumpCard(tester);

      for (final word in const [
        'Rarely regretted',
        'Some regrets',
        'Often regretted',
        'Too new to tell',
        'Recommended',
        'Check before you buy',
      ]) {
        expect(find.text(word), findsNothing, reason: word);
      }
      final all = _textsIn(tester, find.byType(ReturnRecordCard)).join(' ');
      expect(all.toLowerCase().contains('score'), isFalse);
      expect(all.toLowerCase().contains('regret'), isFalse);
    });

    testWidgets('every option carries a spoken label; the ones that open a '
        'product are buttons that respond to a tap', (tester) async {
      final handle = tester.ensureSemantics();
      stub(_record);

      final opened = await pumpCard(tester);

      expect(
        tester.getSemantics(_option('p-alt')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(
        find.bySemanticsLabel(RegExp('Canvas tote.*3 returns per 100 sold')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Leather tote.*you are viewing')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('^Return record.')), findsOneWidget);

      await tester.tap(find.text('Canvas tote'));
      await tester.tap(find.text('Leather tote'));
      await tester.pump();

      // The viewed product is not a way out of its own page.
      expect(opened, ['p-alt']);

      // Disposed here, not in a tearDown: the framework checks for a live
      // handle before tearDowns run.
      handle.dispose();
    });

    testWidgets('lays out at 320dp and text scale 1.3 without overflow', (
      tester,
    ) async {
      for (final record in [_record, _noComparison, _unknownComparison]) {
        stub(record);

        await pumpCard(tester, width: 320, textScale: 1.3);

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('renders nothing when the record cannot be fetched', (
      tester,
    ) async {
      when(() => repository.getReturnRecord(_viewedId)).thenAnswer(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );

      await pumpCard(tester);

      expect(find.text('Return record'), findsNothing);
    });
  });

  group('returnCountsSentence', () {
    test('always names both counts and the window', () {
      expect(
        returnCountsSentence(
          unitsSold: 412,
          unitsReturned: 12,
          windowDays: 180,
        ),
        '12 of the 412 sold in the last 180 days came back',
      );
      expect(
        returnCountsSentence(
          unitsSold: 412,
          unitsReturned: 0,
          windowDays: 180,
        ),
        'None of the 412 sold in the last 180 days came back',
      );
    });
  });

  group('formatUnitCount', () {
    test('groups thousands', () {
      expect(formatUnitCount(0), '0');
      expect(formatUnitCount(412), '412');
      expect(formatUnitCount(12400), '12,400');
      expect(formatUnitCount(1234567), '1,234,567');
    });
  });
}
