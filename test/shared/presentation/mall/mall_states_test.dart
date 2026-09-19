import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

void main() {
  group('MallTrustStrip', () {
    testMallLayouts('fits, sharing the row only when every tile fits', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        const MallTrustStrip(),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      expect(find.text('Secure checkout'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MallTrustStrip),
          matching: find.byType(SingleChildScrollView),
        ),
        width >= 768 ? findsNothing : findsOneWidget,
      );
    });

    testWidgets('each tile reads as one merged node', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMall(tester, const MallTrustStrip(), width: 768);
      expect(
        find.bySemanticsLabel(RegExp(r'^Easy returns\s+Simple return')),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('SmSkeleton', () {
    testMallLayouts('product and reel skeleton rails fit', (
      tester,
      width,
      scale,
    ) async {
      var productHeight = 0.0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) {
            productHeight = MallProductCard.heightFor(
              context,
              width: MallProductCard.compactWidth,
              size: MallCardSize.compact,
            );
            return Column(
              children: [
                SmSkeletonRail(
                  itemWidth: MallProductCard.compactWidth,
                  height: productHeight,
                  itemBuilder: (_, _) => const SmSkeletonProductCard(
                    width: MallProductCard.compactWidth,
                    size: MallCardSize.compact,
                  ),
                ),
                SmSkeletonRail(
                  itemWidth: MallReelCard.compactWidth,
                  height: MallReelCard.heightFor(MallReelCard.compactWidth),
                  itemBuilder: (_, _) => const SmSkeletonReelCard(
                    width: MallReelCard.compactWidth,
                  ),
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
        tester.getSize(find.byType(SmSkeletonProductCard).first).height,
        productHeight,
      );
    });

    testWidgets('primitives size themselves', (tester) async {
      await pumpMall(
        tester,
        const Wrap(
          children: [
            SmSkeleton.box(width: 100, height: 40),
            SmSkeleton.line(width: 80),
            SmSkeleton.circle(diameter: 24),
          ],
        ),
      );
      final skeletons = find.byType(SmSkeleton);
      expect(tester.getSize(skeletons.at(0)), const Size(100, 40));
      expect(tester.getSize(skeletons.at(1)), const Size(80, 12));
      expect(tester.getSize(skeletons.at(2)), const Size(24, 24));
    });

    testWidgets('shimmer stops under reduced motion', (tester) async {
      await pumpMall(
        tester,
        const SmSkeleton.box(width: 100, height: 40),
        disableAnimations: true,
      );
      expect(tester.widget<Shimmer>(find.byType(Shimmer)).enabled, isFalse);
    });

    testWidgets('skeleton rail announces loading only', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMall(
        tester,
        const SmSkeletonRail(itemWidth: 140, height: 80, count: 3),
      );
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('MallEmptyState', () {
    testMallLayouts('icon, eyebrow, long title, body and action fit', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        MallEmptyState(
          icon: Icons.favorite_border_rounded,
          eyebrow: 'Saved',
          title: 'Nothing saved yet — start your wishlist',
          body:
              'Tap the heart on anything you love and it will wait for you '
              'here.',
          actionLabel: 'Explore the mall',
          onAction: () {},
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
    });

    testWidgets('display-face header title; action needs label and '
        'callback', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await pumpMall(
        tester,
        Column(
          children: [
            MallEmptyState(
              title: 'No reels yet',
              actionLabel: 'Browse creators',
              onAction: () => taps++,
            ),
            const MallEmptyState(
              title: 'Label without callback',
              actionLabel: 'Hidden',
            ),
          ],
        ),
      );
      final title = tester.widget<Text>(find.text('No reels yet'));
      expect(title.style?.fontFamily, 'InstrumentSerif');
      expect(
        tester.getSemantics(find.text('No reels yet')),
        isSemantics(isHeader: true),
      );
      expect(find.text('Hidden'), findsNothing);
      await tester.tap(find.text('Browse creators'));
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
    });

    // The kit owns this, so no caller needs its own SingleChildScrollView.
    Widget inExpanded() => Column(
      children: [
        Expanded(
          child: MallEmptyState(
            icon: Icons.favorite_border_rounded,
            eyebrow: 'Saved',
            title: 'Nothing saved yet — start your wishlist',
            body:
                'Tap the heart on anything you love and it will wait for you '
                'here, ready for the next time you are shopping.',
            actionLabel: 'Explore the mall',
            onAction: () {},
          ),
        ),
      ],
    );

    ScrollPosition emptyStateScroll(WidgetTester tester) => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(MallEmptyState),
            matching: find.byType(Scrollable),
          ),
        )
        .position;

    testWidgets('as the only child of a bounded Expanded it scrolls instead '
        'of overflowing at 320dp × text 1.3', (tester) async {
      await pumpMall(
        tester,
        inExpanded(),
        width: 320,
        textScale: 1.3,
        inList: false,
      );
      expectNoLayoutErrors(tester);

      // It did not fit — and it handled that itself.
      expect(emptyStateScroll(tester).maxScrollExtent, greaterThan(0));
      await tester.drag(
        find.byType(MallEmptyState),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);
      expect(find.text('Explore the mall'), findsOneWidget);
    });

    testWidgets('at a normal size it still fills and centres its space, with '
        'nothing to scroll', (tester) async {
      await pumpMall(tester, inExpanded(), inList: false);
      expectNoLayoutErrors(tester);

      expect(emptyStateScroll(tester).maxScrollExtent, 0);
      // Still centred in the height the Expanded gave it, exactly as before.
      final box = tester.getRect(find.byType(MallEmptyState));
      final content = tester.getRect(
        find
            .descendant(
              of: find.byType(MallEmptyState),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(content.height, lessThan(box.height));
      expect((content.center.dy - box.center.dy).abs(), lessThan(1));
    });
  });

  group('MallNetworkImage', () {
    testWidgets('null or blank URL renders the branded placeholder', (
      tester,
    ) async {
      await pumpMall(
        tester,
        const Row(
          children: [
            SizedBox(
              width: 100,
              height: 125,
              child: MallNetworkImage(url: null),
            ),
            SizedBox(
              width: 100,
              height: 125,
              child: MallNetworkImage(url: ' '),
            ),
          ],
        ),
      );
      expect(find.byType(MallImagePlaceholder), findsNWidgets(2));
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('a URL is cached, decoded near display size, and fades '
        'instantly under reduced motion', (tester) async {
      await pumpMall(
        tester,
        const Center(
          child: SizedBox(
            width: 100,
            height: 125,
            child: MallNetworkImage(url: 'https://example.com/look.jpg'),
          ),
        ),
        disableAnimations: true,
      );
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.fadeInDuration, Duration.zero);
      expect(image.memCacheWidth, 200);
    });
  });
}
