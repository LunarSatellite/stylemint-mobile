import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

void main() {
  group('MallCategoryTile', () {
    testMallLayouts('square and tall tiles keep their aspect', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MallCategoryTile(category: sneakers, onTap: () {}),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MallCategoryTile(
                  category: sneakers,
                  shape: MallTileShape.tall,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      final square = tester.getSize(find.byType(MallCategoryTile).first);
      expect(square.height, closeTo(square.width, 0.01));
      final tall = tester.getSize(find.byType(MallCategoryTile).last);
      expect(tall.height, closeTo(tall.width * 4 / 3, 0.01));
    });

    testWidgets('is a labelled button', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await pumpMall(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            child: MallCategoryTile(category: sneakers, onTap: () => taps++),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sneakers & streetwear')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      await tester.tap(find.byType(MallCategoryTile));
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
    });
  });

  group('MallCollectionCard', () {
    testMallLayouts('rail card and full-width card fit', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        Column(
          children: [
            MallRail<MallCollectionVm>(
              items: const [monsoonEdit, monsoonEdit],
              itemWidth: MallCollectionCard.defaultWidth,
              height: MallCollectionCard.heightFor(
                MallCollectionCard.defaultWidth,
              ),
              semanticLabel: 'Collections',
              itemBuilder: (_, collection, _) =>
                  MallCollectionCard(collection: collection, onTap: () {}),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: MallCollectionCard(
                collection: monsoonEdit,
                aspectRatio: 16 / 10,
                onTap: () {},
              ),
            ),
          ],
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
    });

    testWidgets('eyebrow is uppercase; semantics carry title and count', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await pumpMall(
        tester,
        Center(
          child: SizedBox(
            width: MallCollectionCard.defaultWidth,
            child: MallCollectionCard(
              collection: monsoonEdit,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      expect(find.text('EDIT'), findsOneWidget);
      expect(find.text('24 items'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Edit, Monsoon layers for city days, 24 items'),
        findsOneWidget,
      );
      await tester.tap(find.byType(MallCollectionCard));
      expect(taps, 1);
      semantics.dispose();
    });
  });

  group('MallSectionHeader', () {
    testMallLayouts('eyebrow, long title, subtitle and action fit', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        MallSectionHeader(
          eyebrow: 'Picked for you this week',
          title: 'Trending across the whole mall right now',
          subtitle: 'What Kathmandu is saving, sharing and buying.',
          onSeeAll: () {},
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
    });

    testWidgets('RTL at 320dp and ×1.3 fits', (tester) async {
      await pumpMall(
        tester,
        MallSectionHeader(
          eyebrow: 'Picked for you',
          title: 'Trending across the whole mall right now',
          onSeeAll: () {},
        ),
        width: 320,
        textScale: 1.3,
        textDirection: TextDirection.rtl,
      );
      expectNoLayoutErrors(tester);
    });

    testWidgets('display-face header title and a 44dp contextual See all', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var seeAll = 0;
      await pumpMall(
        tester,
        MallSectionHeader(title: 'Trending now', onSeeAll: () => seeAll++),
      );
      final title = tester.widget<Text>(find.text('Trending now'));
      expect(title.style?.fontFamily, 'InstrumentSerif');
      expect(
        tester.getSemantics(find.text('Trending now')),
        isSemantics(isHeader: true),
      );
      final button = find.bySemanticsLabel('See all, Trending now');
      expect(button, findsOneWidget);
      final size = tester.getSize(find.byType(TextButton));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
      await tester.tap(button);
      expect(seeAll, 1);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('no action renders no button', (tester) async {
      await pumpMall(tester, const MallSectionHeader(title: 'Trending now'));
      expect(find.byType(TextButton), findsNothing);
    });
  });
}
