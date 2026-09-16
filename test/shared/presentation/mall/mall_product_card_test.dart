import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

void main() {
  testMallLayouts('compact rail and regular grid fit', (
    tester,
    width,
    scale,
  ) async {
    var railHeight = 0.0;
    await pumpMall(
      tester,
      Builder(
        builder: (context) {
          railHeight = MallProductCard.heightFor(
            context,
            width: MallProductCard.compactWidth,
            size: MallCardSize.compact,
          );
          return Column(
            children: [
              MallRail<MallProductVm>(
                items: const [saleProduct, plainProduct, saleProduct],
                itemWidth: MallProductCard.compactWidth,
                height: railHeight,
                semanticLabel: 'Trending products',
                itemBuilder: (_, product, _) => MallProductCard(
                  product: product,
                  size: MallCardSize.compact,
                  onTap: () {},
                  onSaveTap: () {},
                ),
              ),
              MallProductGrid(
                products: const [saleProduct, plainProduct, saleProduct],
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onProductTap: (_) {},
                onSaveTap: (_) {},
              ),
            ],
          );
        },
      ),
      width: width,
      textScale: scale,
    );
    expectNoLayoutErrors(tester);
    expect(
      tester.getSize(find.byType(MallProductCard).first).height,
      lessThanOrEqualTo(railHeight),
    );
  });

  testWidgets('RTL at 320dp and ×1.3 puts the save heart at the leading '
      'corner without overflow', (tester) async {
    await pumpMall(
      tester,
      Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox(
          width: MallProductCard.compactWidth,
          child: MallProductCard(
            product: saleProduct,
            size: MallCardSize.compact,
            onSaveTap: () {},
          ),
        ),
      ),
      width: 320,
      textScale: 1.3,
      textDirection: TextDirection.rtl,
    );
    expectNoLayoutErrors(tester);
    final card = tester.getRect(find.byType(MallProductCard));
    final heart = tester.getRect(find.byType(MallSaveButton));
    expect(heart.center.dx, lessThan(card.center.dx));
  });

  testWidgets('sale price: whole rupees, strikethrough original, floored '
      'discount pill', (tester) async {
    await pumpMall(
      tester,
      const Center(
        child: SizedBox(
          width: MallProductCard.regularWidth,
          child: MallProductCard(product: saleProduct),
        ),
      ),
    );
    expect(find.text('Rs 3,499'), findsOneWidget);
    final original = tester.widget<Text>(find.text('Rs 4,999'));
    expect(original.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('-30%'), findsOneWidget);
    expect(find.textContaining('.00'), findsNothing);
    expect(find.text('NEW'), findsNothing, reason: 'badges keep their case');
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Low stock'), findsOneWidget);
    expect(find.text('KATHMANDU ATELIER'), findsOneWidget);
  });

  testWidgets('no sale styling without a higher original price', (
    tester,
  ) async {
    await pumpMall(
      tester,
      const Center(
        child: SizedBox(
          width: MallProductCard.regularWidth,
          child: MallProductCard(product: plainProduct),
        ),
      ),
    );
    expect(find.text('Rs 1,800'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.decoration == TextDecoration.lineThrough,
      ),
      findsNothing,
    );
    expect(find.textContaining('%'), findsNothing);
    expect(find.byType(MallSaveButton), findsNothing);
  });

  testWidgets('amounts with paisa keep two decimals', (tester) async {
    await pumpMall(
      tester,
      const Center(
        child: SizedBox(
          width: MallProductCard.regularWidth,
          child: MallProductCard(
            product: MallProductVm(
              id: 'p-paisa',
              name: 'Hair clip',
              price: Money(amount: 1299.5, currency: npr),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Rs 1,299.50'), findsOneWidget);
  });

  testWidgets('semantics: one labelled card button plus a separate save '
      'toggle, both 44dp or larger', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    var saves = 0;
    await pumpMall(
      tester,
      Center(
        child: SizedBox(
          width: MallProductCard.regularWidth,
          child: MallProductCard(
            product: saleProduct,
            onTap: () => taps++,
            onSaveTap: () => saves++,
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Kathmandu Atelier, $longProductName, Rs 3,499, was Rs 4,999, '
        '30% off, New, Low stock, Rated 4.6 out of 5',
      ),
      findsOneWidget,
    );
    final save = find.bySemanticsLabel('Save $longProductName');
    expect(
      tester.getSemantics(save),
      isSemantics(
        isButton: true,
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
      ),
    );

    await tester.tap(save);
    expect(saves, 1);
    expect(taps, 0);
    await tester.tap(find.byType(MallProductCard));
    expect(taps, 1);

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('reel-backed photo has an independent play action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var productTaps = 0;
    var playedReel = '';
    await pumpMall(
      tester,
      Center(
        child: SizedBox(
          width: MallProductCard.regularWidth,
          child: MallProductCard(
            product: reelProduct,
            onTap: () => productTaps++,
            onReelTap: (reel) => playedReel = reel.reelId,
          ),
        ),
      ),
    );

    final play = find.byKey(MallProductCard.playKey);
    expect(play, findsOneWidget);
    expect(find.bySemanticsLabel('Watch reel'), findsOneWidget);
    await tester.tap(play);
    expect(playedReel, productReel.reelId);
    expect(productTaps, 0);

    await tester.tap(find.byType(MallProductCard));
    expect(productTaps, 1);
    semantics.dispose();
  });
  testWidgets('saved state reads as remove-from-saved', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(
      tester,
      Center(
        child: SizedBox(
          width: MallProductCard.regularWidth,
          child: MallProductCard(
            product: const MallProductVm(
              id: 'p-saved',
              name: 'Canvas tote',
              price: Money(amount: 1800, currency: npr),
              isSaved: true,
            ),
            onSaveTap: () {},
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(
        find.bySemanticsLabel('Remove Canvas tote from saved'),
      ),
      isSemantics(isToggled: true),
    );
    semantics.dispose();
  });

  testWidgets('heightFor matches the rendered height at ×1.3', (tester) async {
    for (final size in MallCardSize.values) {
      var expected = 0.0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) {
            expected = MallProductCard.heightFor(
              context,
              width: 160,
              size: size,
            );
            return Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: 160,
                child: MallProductCard(product: saleProduct, size: size),
              ),
            );
          },
        ),
        textScale: 1.3,
      );
      final rendered = tester.getSize(find.byType(MallProductCard)).height;
      expect(rendered, inInclusiveRange(expected - 1, expected));
    }
  });
}
