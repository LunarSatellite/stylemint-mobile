import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

void main() {
  testMallLayouts('compact and regular reel rails fit; AI label never '
      'truncates', (tester, width, scale) async {
    await pumpMall(
      tester,
      Column(
        children: [
          for (final itemWidth in [
            MallReelCard.compactWidth,
            MallReelCard.regularWidth,
          ])
            MallRail<MallReelVm>(
              items: const [aiReel, humanReel, aiReel],
              itemWidth: itemWidth,
              height: MallReelCard.heightFor(itemWidth),
              semanticLabel: 'Reels',
              itemBuilder: (_, reel, _) =>
                  MallReelCard(reel: reel, onTap: () {}),
            ),
        ],
      ),
      width: width,
      textScale: scale,
    );
    expectNoLayoutErrors(tester);
    final labels = find.text('AI-generated');
    expect(labels, findsWidgets);
    for (final paragraph in tester.renderObjectList<RenderParagraph>(
      labels,
    )) {
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  });

  testWidgets('AI reel shows the disclosure, counts and a full semantic '
      'label', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await pumpMall(
      tester,
      Center(
        child: SizedBox(
          width: MallReelCard.regularWidth,
          child: MallReelCard(reel: aiReel, onTap: () => taps++),
        ),
      ),
    );
    expect(find.text('AI-generated'), findsOneWidget);
    expect(find.text('3 products'), findsOneWidget);
    expect(find.text('12.4K'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Reel by ${aiReel.creatorName}, AI-generated, 3 products, '
        '12.4K likes, Weekend edit',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(MallReelCard));
    expect(taps, 1);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('non-AI reel has no AI label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(
      tester,
      const Center(
        child: SizedBox(
          width: MallReelCard.compactWidth,
          child: MallReelCard(reel: humanReel),
        ),
      ),
    );
    expect(find.text('AI-generated'), findsNothing);
    expect(find.text('1 product'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Reel by Aarav, 1 product, 1 like'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('AI label follows MallStringsScope localisation', (
    tester,
  ) async {
    await pumpMall(
      tester,
      const MallStringsScope(
        strings: MallStrings(aiGenerated: 'Generado con IA'),
        child: Center(
          child: SizedBox(
            width: MallReelCard.compactWidth,
            child: MallReelCard(reel: aiReel),
          ),
        ),
      ),
    );
    expect(find.text('Generado con IA'), findsOneWidget);
    expect(find.text('AI-generated'), findsNothing);
  });

  test('heightFor is 9:16', () {
    expect(MallReelCard.heightFor(90), 160);
  });
}
