import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

final DateTime _now = DateTime.utc(2026, 9, 15, 13);

/// 4h 30m after [_now].
final DateTime _endsSoon = DateTime.utc(2026, 9, 15, 17, 30);

MallCollectionVm _collection(String id, String title, {int? count}) =>
    MallCollectionVm(
      id: id,
      title: title,
      eyebrow: 'Edit',
      itemCount: count,
    );

final List<MallCollectionVm> _collections = [
  _collection('c-1', 'Minimal workwear', count: 8),
  _collection('c-2', 'Monsoon layers', count: 12),
  _collection('c-3', 'Gold hour', count: 6),
];

const List<MallCategoryVm> _categories = [
  MallCategoryVm(id: 'cat-1', label: 'Fashion'),
  MallCategoryVm(id: 'cat-2', label: 'Home'),
  MallCategoryVm(id: 'cat-3', label: 'Tech'),
  MallCategoryVm(id: 'cat-4', label: 'Beauty'),
  MallCategoryVm(id: 'cat-5', label: 'Sneakers & streetwear'),
];

Widget _band({
  int? discount = 40,
  DateTime? endsUtc,
  VoidCallback? onCta,
}) => MallDealBand(
  title: 'Deals',
  eyebrow: 'Limited time',
  topDiscountPercent: discount,
  endsUtc: endsUtc,
  ctaLabel: onCta == null ? null : 'Shop the drop',
  onCta: onCta,
  now: () => _now,
  child: const SizedBox(height: 40, child: Text('the rail')),
);

void main() {
  group('MallDealBand', () {
    testMallLayouts('the plate and its rail fit', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        _band(endsUtc: _endsSoon, onCta: () {}),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
    });

    testWidgets('shows the real discount, the real deadline and the action', (
      tester,
    ) async {
      var taps = 0;
      await pumpMall(
        tester,
        _band(endsUtc: _endsSoon, onCta: () => taps++),
      );
      expect(find.text('LIMITED TIME'), findsOneWidget);
      expect(find.text('Deals'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('UP TO'), findsOneWidget);
      expect(find.text('Ends in 4h 30m'), findsOneWidget);
      expect(find.text('the rail'), findsOneWidget);

      await tester.tap(find.text('Shop the drop'));
      expect(taps, 1);
    });

    testWidgets('draws no numeral when nothing is discounted', (tester) async {
      await pumpMall(tester, _band(discount: null, endsUtc: _endsSoon));
      expect(find.text('UP TO'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Ends in 4h 30m'), findsOneWidget);
    });

    testWidgets('draws no countdown without a deadline, or once it passes', (
      tester,
    ) async {
      await pumpMall(tester, _band());
      expect(find.textContaining('Ends in'), findsNothing);

      await pumpMall(
        tester,
        _band(endsUtc: DateTime.utc(2026, 9, 15, 12)),
      );
      expect(find.textContaining('Ends in'), findsNothing);
    });

    testWidgets('has no action when there is nowhere to send anyone', (
      tester,
    ) async {
      await pumpMall(tester, _band(endsUtc: _endsSoon));
      expect(find.text('Shop the drop'), findsNothing);
    });

    testWidgets('the countdown speaks its long form', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMall(tester, _band(endsUtc: _endsSoon));
      expect(
        find.bySemanticsLabel('Ends in 4 hours 30 minutes'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('MallEditorialSpread', () {
    testMallLayouts('the spread fits', (tester, width, scale) async {
      await pumpMall(
        tester,
        MallEditorialSpread(
          collections: _collections,
          semanticLabel: 'Collections',
          onOpen: (_) {},
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      for (final collection in _collections) {
        expect(find.text(collection.title), findsOneWidget);
      }
    });

    testWidgets('a lone collection still reads as a spread', (tester) async {
      await pumpMall(
        tester,
        MallEditorialSpread(
          collections: [_collections.first],
          semanticLabel: 'Collections',
        ),
      );
      expectNoLayoutErrors(tester);
      expect(find.text('Minimal workwear'), findsOneWidget);
    });

    testWidgets('anything past the third runs on', (tester) async {
      await pumpMall(
        tester,
        MallEditorialSpread(
          collections: [
            ..._collections,
            _collection('c-4', 'Field notes', count: 4),
            _collection('c-5', 'After hours', count: 9),
          ],
          semanticLabel: 'Collections',
        ),
      );
      expectNoLayoutErrors(tester);
      expect(find.text('Field notes'), findsOneWidget);
    });

    testWidgets('opens the collection that was tapped', (tester) async {
      MallCollectionVm? opened;
      await pumpMall(
        tester,
        MallEditorialSpread(
          collections: _collections,
          semanticLabel: 'Collections',
          onOpen: (collection) => opened = collection,
        ),
      );
      await tester.tap(find.text('Monsoon layers'), warnIfMissed: false);
      expect(opened?.id, 'c-2');
    });

    testWidgets('an empty spread draws nothing', (tester) async {
      await pumpMall(
        tester,
        const MallEditorialSpread(
          collections: [],
          semanticLabel: 'Collections',
        ),
      );
      expect(find.byType(MallCollectionCard), findsNothing);
    });
  });

  group('MallCategoryMosaic', () {
    testMallLayouts('every tile fits, with no artwork to lean on', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        const MallCategoryMosaic(
          categories: _categories,
          semanticLabel: 'Shop by category',
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      for (final category in _categories) {
        expect(find.text(category.label), findsOneWidget);
      }
    });

    testWidgets('keeps every category in one compact horizontal row', (
      tester,
    ) async {
      await pumpMall(
        tester,
        const MallCategoryMosaic(
          categories: _categories,
          semanticLabel: 'Shop by category',
        ),
        width: 390,
      );

      final first = tester.getRect(
        find.byKey(MallCategoryMosaic.tileKey(_categories.first)),
      );
      final second = tester.getRect(
        find.byKey(MallCategoryMosaic.tileKey(_categories[1])),
      );
      final third = tester.getRect(
        find.byKey(MallCategoryMosaic.tileKey(_categories[2])),
      );
      expect(first.top, closeTo(second.top, 0.01));
      expect(second.top, closeTo(third.top, 0.01));
      expect(first.width, MallCategoryMosaic.tileWidth);
      expect(first.height, lessThan(140));
    });
    testWidgets('an empty mosaic draws nothing', (tester) async {
      await pumpMall(
        tester,
        const MallCategoryMosaic(
          categories: [],
          semanticLabel: 'Shop by category',
        ),
      );
      expect(find.byType(MallTapOverlay), findsNothing);
    });
  });
}
