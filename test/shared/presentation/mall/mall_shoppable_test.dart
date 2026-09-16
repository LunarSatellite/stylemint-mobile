import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

/// 13:00 UTC is 18:45 in Kathmandu.
final DateTime _now = DateTime.utc(2026, 9, 15, 13);

/// 4h 30m out: a live countdown, same Kathmandu day.
final DateTime _saleEnd = DateTime.utc(2026, 9, 15, 17, 30);

const MallProductVm _spotlightProduct = MallProductVm(
  id: 'p-spot',
  brandName: 'Kathmandu Atelier',
  name: longProductName,
  price: Money(amount: 3499, currency: npr),
  compareAtPrice: Money(amount: 4999, currency: npr),
  rating: 4.6,
  reviewCount: 12,
  imageUrl: productPhotoUrl,
  requiresOptionSelection: false,
  defaultVariantId: 'v-spot',
  isInStock: true,
);

/// The thin-data case: a name, a price and nothing else the API populated.
const MallProductVm _bareProduct = MallProductVm(
  id: 'p-bare',
  name: 'Canvas tote',
  price: Money(amount: 1800, currency: npr),
);

void main() {
  group('MallQuickAdd', () {
    testWidgets('one tap adds, confirms, then resets itself', (tester) async {
      var adds = 0;
      await pumpMall(
        tester,
        MallQuickAdd(
          onAdd: () async {
            adds++;
            return true;
          },
          semanticLabel: 'Add Canvas tote to bag',
        ),
      );

      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(adds, 1);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // The tick is held, then the control goes back to offering the add.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a rejected add drops straight back to idle', (tester) async {
      await pumpMall(
        tester,
        MallQuickAdd(
          onAdd: () async => false,
          semanticLabel: 'Add Canvas tote to bag',
        ),
      );

      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
    });

    testWidgets('a second tap in flight does not buy it twice', (tester) async {
      var adds = 0;
      final gate = Completer<bool>();
      await pumpMall(
        tester,
        MallQuickAdd(
          onAdd: () {
            adds++;
            return gate.future;
          },
          semanticLabel: 'Add Canvas tote to bag',
        ),
      );

      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      expect(adds, 1);

      gate.complete(true);
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
    });

    testWidgets('a product needing a size opens its page and adds nothing', (
      tester,
    ) async {
      var opened = 0;
      var added = 0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) =>
              MallQuickAdd.forProduct(
                product: optionProduct,
                strings: MallStrings.of(context),
                onAdd: () async {
                  added++;
                  return true;
                },
                onChoose: () => opened++,
              ) ??
              const SizedBox.shrink(),
        ),
      );

      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(added, 0, reason: 'a size was never chosen');
      expect(opened, 1);
      // No phase change either: the control is still offering the choice.
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('the two states do not read the same', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMall(
        tester,
        Builder(
          builder: (context) {
            final strings = MallStrings.of(context);
            return Wrap(
              children: [
                MallQuickAdd.forProduct(
                  product: plainAddableProduct,
                  strings: strings,
                  onAdd: () async => true,
                  onChoose: () {},
                  withLabel: true,
                )!,
                MallQuickAdd.forProduct(
                  product: optionProduct,
                  strings: strings,
                  onAdd: () async => true,
                  onChoose: () {},
                  withLabel: true,
                )!,
              ],
            );
          },
        ),
      );

      expect(find.text('Add to bag'), findsOneWidget);
      expect(find.text('Choose options'), findsOneWidget);
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(
        find.bySemanticsLabel('Add Canvas tote to bag'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Choose options for Linen shirt'),
        findsOneWidget,
      );
      // Same target in both states, so a rail never reflows.
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('a card with unknown stock exposes no buy control', (
      tester,
    ) async {
      var added = 0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) =>
              MallQuickAdd.forProduct(
                // Straight from the default constructor: the field was absent
                // from the payload, which reads as "a choice is required".
                product: plainProduct,
                strings: MallStrings.of(context),
                onAdd: () async {
                  added++;
                  return true;
                },
                onChoose: () {},
              ) ??
              const SizedBox.shrink(),
        ),
      );

      expect(find.byKey(MallQuickAdd.tapKey), findsNothing);
      expect(added, 0);
    });

    testWidgets('cleared but with no variant named is still a choice', (
      tester,
    ) async {
      const half = MallProductVm(
        id: 'p-half',
        name: 'Linen shirt',
        price: Money(amount: 2400, currency: npr),
        requiresOptionSelection: false,
        isInStock: true,
      );
      var added = 0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) =>
              MallQuickAdd.forProduct(
                product: half,
                strings: MallStrings.of(context),
                onAdd: () async {
                  added++;
                  return true;
                },
                onChoose: () {},
              ) ??
              const SizedBox.shrink(),
        ),
      );

      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(added, 0, reason: 'there is no variant to send');
    });

    testWidgets('the disc and the pill are both tappable sizes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpMall(
        tester,
        Row(
          children: [
            MallQuickAdd(
              onAdd: () async => true,
              semanticLabel: 'Add Canvas tote to bag',
            ),
            MallQuickAdd(
              onAdd: () async => true,
              label: 'Add to bag',
              semanticLabel: 'Add Linen co-ord set to bag',
            ),
          ],
        ),
      );
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });
  });

  group('MallSpotlight', () {
    testWidgets('shows the reason, the price, the saving and the deadline', (
      tester,
    ) async {
      await pumpMall(
        tester,
        MallSpotlight(
          product: _spotlightProduct,
          eyebrow: 'Biggest saving here',
          endsUtc: _saleEnd,
          now: () => _now,
          onTap: () {},
          onQuickAdd: () async => true,
        ),
      );

      expect(find.text('BIGGEST SAVING HERE'), findsOneWidget);
      expect(find.text(longProductName), findsOneWidget);
      expect(find.text('-30%'), findsOneWidget);
      expect(find.text('Add to bag'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.textContaining('Ends in 4h'), findsOneWidget);
      // Video first: the spotlight never builds a product photo.
      expect(find.byType(Image), findsNothing);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a product with nothing to say still reads as a block', (
      tester,
    ) async {
      await pumpMall(
        tester,
        const MallSpotlight(product: _bareProduct),
      );

      expect(find.text('Canvas tote'), findsOneWidget);
      // No claim, no eyebrow, no saving, no countdown, no actions.
      expect(find.text('View'), findsNothing);
      expect(find.text('Add to bag'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('Ends in'), findsNothing);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a tap on the copy opens the product', (tester) async {
      var opened = 0;
      await pumpMall(
        tester,
        MallSpotlight(product: _bareProduct, onTap: () => opened++),
      );
      await tester.tap(find.text('Canvas tote'), warnIfMissed: false);
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('the buy control buys without opening the product', (
      tester,
    ) async {
      var opened = 0;
      var added = 0;
      await pumpMall(
        tester,
        MallSpotlight(
          product: _spotlightProduct,
          onTap: () => opened++,
          onQuickAdd: () async {
            added++;
            return true;
          },
        ),
      );
      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(added, 1);
      expect(opened, 0);
      await tester.pump(const Duration(milliseconds: 1500));
    });

    testWidgets('a product needing a size opens instead of adding', (
      tester,
    ) async {
      var opened = 0;
      var added = 0;
      await pumpMall(
        tester,
        MallSpotlight(
          product: optionProduct,
          onTap: () => opened++,
          onQuickAdd: () async {
            added++;
            return true;
          },
        ),
      );

      expect(find.text('Choose options'), findsOneWidget);
      expect(find.text('Add to bag'), findsNothing);
      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(added, 0);
      expect(opened, 1);
    });

    testWidgets('a reel product plays its reel from the panel', (tester) async {
      MallReelRef? played;
      await pumpMall(
        tester,
        MallSpotlight(
          product: reelProduct,
          onTap: () {},
          onReelTap: (reel) => played = reel,
        ),
      );
      await tester.tap(find.byKey(MallSpotlightKeys.play));
      await tester.pump();
      expect(played?.reelId, productReel.reelId);
    });

    testWidgets('an AI reel keeps its disclosure', (tester) async {
      await pumpMall(
        tester,
        MallSpotlight(product: aiReelProduct, onReelTap: (_) {}),
      );
      expect(find.text('AI-generated'), findsOneWidget);
    });

    testMallLayouts('the block fits with the choose pill', (
      tester,
      width,
      textScale,
    ) async {
      await pumpMall(
        tester,
        MallSpotlight(
          product: optionProduct,
          eyebrow: 'Biggest saving here',
          onTap: () {},
          onSaveTap: () {},
          onQuickAdd: () async => true,
        ),
        width: width,
        textScale: textScale,
      );
      expectNoLayoutErrors(tester);
    });

    testMallLayouts('the block fits', (tester, width, textScale) async {
      await pumpMall(
        tester,
        MallSpotlight(
          product: _spotlightProduct,
          eyebrow: 'Biggest saving here',
          endsUtc: _saleEnd,
          now: () => _now,
          onTap: () {},
          onSaveTap: () {},
          onQuickAdd: () async => true,
        ),
        width: width,
        textScale: textScale,
      );
      expectNoLayoutErrors(tester);
    });
  });

  group('MallTicker', () {
    const words = ['Kathmandu Atelier', 'Monsoon layers', 'Fashion'];

    testWidgets("sets the page's own words as signage", (tester) async {
      await pumpMall(
        tester,
        const MallTicker(words: words, semanticLabel: 'In the Mall right now'),
      );
      // Two passes of the line, so the loop never shows a gap.
      expect(find.text('KATHMANDU ATELIER'), findsNWidgets(2));
      expectNoLayoutErrors(tester);
    });

    testWidgets('speaks the words in the casing they were sent in', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpMall(
        tester,
        const MallTicker(words: words, semanticLabel: 'In the Mall right now'),
      );
      expect(
        find.bySemanticsLabel(
          'In the Mall right now: '
          'Kathmandu Atelier, Monsoon layers, Fashion',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('holds still under reduced motion', (tester) async {
      await pumpMall(
        tester,
        const MallTicker(words: words, semanticLabel: 'In the Mall right now'),
        disableAnimations: true,
      );
      // One pass only: nothing is travelling, so nothing needs covering.
      expect(find.text('KATHMANDU ATELIER'), findsOneWidget);
    });

    testWidgets('no words, no band', (tester) async {
      await pumpMall(
        tester,
        const MallTicker(words: [], semanticLabel: 'In the Mall right now'),
      );
      expect(find.byType(Text), findsNothing);
    });

    testMallLayouts('the band fits', (tester, width, textScale) async {
      await pumpMall(
        tester,
        const MallTicker(words: words, semanticLabel: 'In the Mall right now'),
        width: width,
        textScale: textScale,
      );
      expectNoLayoutErrors(tester);
    });
  });

  group('MallProductTile with quick-add', () {
    /// A tile at exactly the size a rail would give it. `Align` keeps the
    /// box loose, the way a rail's viewport does.
    Widget sized(BuildContext context, Widget child, {required bool action}) =>
        Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: MallProductTile.compactWidth,
            height: MallProductTile.heightFor(
              context,
              width: MallProductTile.compactWidth,
              size: MallCardSize.compact,
              withSignal: true,
              withAction: action,
            ),
            child: child,
          ),
        );

    Widget tile({
      required void Function() onTap,
      required Future<bool> Function() onQuickAdd,
      MallProductVm product = photoOnlyProduct,
    }) => Builder(
      builder: (context) => sized(
        context,
        MallProductTile(
          product: product,
          size: MallCardSize.compact,
          reserveSignal: true,
          onTap: onTap,
          onSaveTap: () {},
          onQuickAdd: onQuickAdd,
        ),
        action: true,
      ),
    );

    testWidgets('the type tile buys without opening the product', (
      tester,
    ) async {
      var opened = 0;
      var added = 0;
      await pumpMall(
        tester,
        tile(
          onTap: () => opened++,
          onQuickAdd: () async {
            added++;
            return true;
          },
        ),
      );
      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(added, 1);
      expect(opened, 0);
      expectNoLayoutErrors(tester);
      await tester.pump(const Duration(milliseconds: 1500));
    });

    testWidgets('the reel tile buys without playing the reel', (tester) async {
      var played = 0;
      var added = 0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) => sized(
            context,
            MallProductTile(
              product: reelProduct,
              size: MallCardSize.compact,
              reserveSignal: true,
              onTap: () {},
              onReelTap: (_) => played++,
              onQuickAdd: () async {
                added++;
                return true;
              },
            ),
            action: true,
          ),
        ),
      );
      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(added, 1);
      expect(played, 0);
      await tester.pump(const Duration(milliseconds: 1500));
    });

    testWidgets('a tile whose product needs a size opens the page', (
      tester,
    ) async {
      var opened = 0;
      var added = 0;
      await pumpMall(
        tester,
        tile(
          product: optionProduct,
          onTap: () => opened++,
          onQuickAdd: () async {
            added++;
            return true;
          },
        ),
      );

      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(added, 0, reason: 'a size was never chosen');
      expect(opened, 1);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a reel tile whose product needs a size opens the page', (
      tester,
    ) async {
      var opened = 0;
      var added = 0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) => sized(
            context,
            MallProductTile(
              product: optionReelProduct,
              size: MallCardSize.compact,
              reserveSignal: true,
              onTap: () => opened++,
              onReelTap: (_) {},
              onQuickAdd: () async {
                added++;
                return true;
              },
            ),
            action: true,
          ),
        ),
      );

      await tester.tap(find.byKey(MallQuickAdd.tapKey));
      await tester.pump();
      await tester.pump();
      expect(added, 0);
      expect(opened, 1);
    });

    testWidgets('both states occupy the same slot', (tester) async {
      Rect control() => tester.getRect(find.byKey(MallQuickAdd.tapKey));

      await pumpMall(
        tester,
        tile(onTap: () {}, onQuickAdd: () async => true),
      );
      final adds = control();

      await pumpMall(
        tester,
        tile(
          product: optionProduct,
          onTap: () {},
          onQuickAdd: () async => true,
        ),
      );
      expect(control(), adds, reason: 'a rail must not reflow');
    });

    testWidgets('no callback, no buy control', (tester) async {
      await pumpMall(
        tester,
        Builder(
          builder: (context) => sized(
            context,
            const MallProductTile(
              product: photoOnlyProduct,
              size: MallCardSize.compact,
              reserveSignal: true,
            ),
            action: false,
          ),
        ),
      );
      expect(find.byKey(MallQuickAdd.tapKey), findsNothing);
      expectNoLayoutErrors(tester);
    });

    testMallLayouts('a rail of choose tiles fits', (
      tester,
      width,
      textScale,
    ) async {
      await pumpMall(
        tester,
        Builder(
          builder: (context) => MallRail<MallProductVm>(
            items: const [optionReelProduct, optionProduct, plainProduct],
            itemWidth: MallProductTile.compactWidth,
            height: MallProductTile.heightFor(
              context,
              width: MallProductTile.compactWidth,
              size: MallCardSize.compact,
              withSignal: true,
              withAction: true,
            ),
            semanticLabel: 'Products needing a choice',
            itemBuilder: (_, product, _) => MallProductTile(
              product: product,
              size: MallCardSize.compact,
              reserveSignal: true,
              signal: const MallSignal(label: '12 reviews'),
              onTap: () {},
              onSaveTap: () {},
              onReelTap: (_) {},
              onQuickAdd: () async => true,
            ),
          ),
        ),
        width: width,
        textScale: textScale,
      );
      expectNoLayoutErrors(tester);
    });

    testMallLayouts('a buyable rail fits', (tester, width, textScale) async {
      await pumpMall(
        tester,
        Builder(
          builder: (context) => MallRail<MallProductVm>(
            items: const [reelProduct, photoOnlyProduct, saleProduct],
            itemWidth: MallProductTile.compactWidth,
            height: MallProductTile.heightFor(
              context,
              width: MallProductTile.compactWidth,
              size: MallCardSize.compact,
              withSignal: true,
              withAction: true,
            ),
            semanticLabel: 'Buyable products',
            itemBuilder: (_, product, _) => MallProductTile(
              product: product,
              size: MallCardSize.compact,
              reserveSignal: true,
              signal: const MallSignal(label: '12 reviews'),
              onTap: () {},
              onSaveTap: () {},
              onReelTap: (_) {},
              onQuickAdd: () async => true,
            ),
          ),
        ),
        width: width,
        textScale: textScale,
      );
      expectNoLayoutErrors(tester);
    });
  });
}
