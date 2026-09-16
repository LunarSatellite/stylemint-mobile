import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

/// Every reel id the fixtures use.
const List<String> _reelIds = ['pr-1', 'pr-2'];

Widget _tile(
  MallProductVm product, {
  MallCardSize size = MallCardSize.regular,
  MallReelPlaySlotController? slot,
  VoidCallback? onTap,
}) => SizedBox(
  width: MallProductTile.regularWidth,
  child: MallProductTile(
    product: product,
    size: size,
    onTap: onTap,
    playSlotController: slot,
  ),
);

/// URLs of every image the surface actually asked the network for.
Set<String> _loadedImageUrls(WidgetTester tester) => tester
    .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
    .map((image) => image.imageUrl)
    .toSet();

void main() {
  group('MallReelTile', () {
    testWidgets('renders the reel poster, its length and the play mark', (
      tester,
    ) async {
      await pumpMall(tester, _tile(reelProduct, onTap: () {}));

      expect(find.byType(MallReelTile), findsOneWidget);
      expect(find.byType(MallTypeTile), findsNothing);
      expect(find.byType(MallPlayMark), findsOneWidget);
      expect(find.text('0:12'), findsOneWidget);
      expect(find.text(productReel.hook!), findsOneWidget);
      // The poster is the only image, and it is the reel's — not the photo
      // the same product carries.
      expect(_loadedImageUrls(tester), {reelPosterUrl});
      // Brand, name and price still sit under the poster.
      expect(find.text('KATHMANDU ATELIER'), findsOneWidget);
      expect(find.text(longProductName), findsOneWidget);
    });

    testWidgets('a reel with no poster falls back to the designed ground', (
      tester,
    ) async {
      const noPoster = MallProductVm(
        id: 'p-no-poster',
        brandName: 'Loom',
        name: 'Hand-loomed scarf',
        price: Money(amount: 2100, currency: npr),
        imageUrl: productPhotoUrl,
        reel: MallReelRef(reelId: 'pr-3', durationSeconds: 9),
      );
      await pumpMall(tester, _tile(noPoster));

      expect(find.byType(MallReelTile), findsOneWidget);
      expect(find.byType(MallTypeGround), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });

  group('MallTypeTile', () {
    testWidgets('a product with no reel gets the type tile and no photo', (
      tester,
    ) async {
      await pumpMall(tester, _tile(photoOnlyProduct, onTap: () {}));

      expect(find.byType(MallTypeTile), findsOneWidget);
      expect(find.byType(MallReelTile), findsNothing);
      // The acceptance criterion, at tile level: the product has a photo on
      // its record and the tile does not build it.
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(MallNetworkImage), findsNothing);
      // It still carries brand, name and price.
      expect(find.text('KATHMANDU ATELIER'), findsOneWidget);
      expect(find.text(longProductName), findsOneWidget);
      expect(find.textContaining('1,800'), findsOneWidget);
    });

    testWidgets('the ground is stable per product and drawn from the palette', (
      tester,
    ) async {
      expect(
        MallTypeGround.groundIndexFor('p-photo'),
        MallTypeGround.groundIndexFor('p-photo'),
      );
      await pumpMall(tester, _tile(photoOnlyProduct));
      expect(find.byType(MallTypeGround), findsOneWidget);
    });
  });

  group('the AI-generated disclosure', () {
    testWidgets('shows only on the tile whose reel is flagged', (tester) async {
      await pumpMall(
        tester,
        Column(children: [_tile(reelProduct), _tile(aiReelProduct)]),
      );

      expect(find.byType(MallReelTile), findsNWidgets(2));
      expect(find.text('AI-generated'), findsOneWidget);
    });

    testWidgets('never appears on a type tile', (tester) async {
      await pumpMall(tester, _tile(photoOnlyProduct));
      expect(find.text('AI-generated'), findsNothing);
    });
  });

  group('the single play slot', () {
    testWidgets('exactly one tile holds it', (tester) async {
      final slot = MallReelPlaySlotController();
      await pumpMall(
        tester,
        Column(
          children: [
            _tile(reelProduct, slot: slot),
            _tile(aiReelProduct, slot: slot),
          ],
        ),
      );
      await tester.pump();

      expect(_reelIds.where(slot.holds).length, 1);
      expect(slot.holder, isNotNull);
    });

    testWidgets('a tile scrolled off screen gives the slot up', (tester) async {
      final slot = MallReelPlaySlotController();
      await pumpMall(
        tester,
        Column(
          children: [
            _tile(reelProduct, slot: slot),
            const SizedBox(height: 900),
            _tile(aiReelProduct, slot: slot),
          ],
        ),
      );
      await tester.pump();
      expect(slot.holds('pr-1'), isTrue);

      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pump();
      await tester.pump();

      expect(slot.holds('pr-1'), isFalse);
      expect(_reelIds.where(slot.holds).length, lessThanOrEqualTo(1));
    });

    testWidgets('reduced motion grants no slot at all', (tester) async {
      final slot = MallReelPlaySlotController();
      await pumpMall(
        tester,
        Column(
          children: [
            _tile(reelProduct, slot: slot),
            _tile(aiReelProduct, slot: slot),
          ],
        ),
        disableAnimations: true,
      );
      await tester.pump();
      await tester.pump();

      expect(slot.holder, isNull);
    });
  });

  group('Mall surfaces', () {
    testWidgets('build no product photo in a rail or a grid', (tester) async {
      var railHeight = 0.0;
      await pumpMall(
        tester,
        Builder(
          builder: (context) {
            railHeight = MallProductTile.heightFor(
              context,
              width: MallProductTile.compactWidth,
              size: MallCardSize.compact,
            );
            return Column(
              children: [
                MallRail<MallProductVm>(
                  items: const [reelProduct, photoOnlyProduct, aiReelProduct],
                  itemWidth: MallProductTile.compactWidth,
                  height: railHeight,
                  semanticLabel: 'Picks',
                  itemBuilder: (_, product, _) => MallProductTile(
                    product: product,
                    size: MallCardSize.compact,
                    onTap: () {},
                  ),
                ),
                MallProductGrid(
                  products: const [
                    reelProduct,
                    photoOnlyProduct,
                    aiReelProduct,
                  ],
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onProductTap: (_) {},
                  onSaveTap: (_) {},
                ),
              ],
            );
          },
        ),
      );

      // The directive's acceptance criterion: no product photo anywhere on a
      // Mall surface. Reel posters are the only images.
      expect(_loadedImageUrls(tester), isNot(contains(productPhotoUrl)));
      expect(find.byType(MallProductCard), findsNothing);
    });

    testWidgets('a grid tap opens the product and a reel tile opens its reel', (
      tester,
    ) async {
      String? openedProduct;
      String? openedReel;
      await pumpMall(
        tester,
        CustomScrollView(
          slivers: [
            MallSliverProductGrid(
              products: const [photoOnlyProduct, reelProduct],
              onProductTap: (product) => openedProduct = product.id,
              onReelTap: (_, reel) => openedReel = reel.reelId,
            ),
          ],
        ),
        inList: false,
      );

      await tester.tap(find.byType(MallTypeTile).first);
      expect(openedProduct, 'p-photo');
      expect(openedReel, isNull);

      await tester.tap(find.byType(MallReelTile).first);
      expect(openedReel, 'pr-1');
    });
  });

  testMallLayouts('a rail and a grid of mixed tiles fit', (
    tester,
    width,
    scale,
  ) async {
    var railHeight = 0.0;
    await pumpMall(
      tester,
      Builder(
        builder: (context) {
          railHeight = MallProductTile.heightFor(
            context,
            width: MallProductTile.compactWidth,
            size: MallCardSize.compact,
          );
          return Column(
            children: [
              MallRail<MallProductVm>(
                items: const [reelProduct, photoOnlyProduct, aiReelProduct],
                itemWidth: MallProductTile.compactWidth,
                height: railHeight,
                semanticLabel: 'Picks',
                itemBuilder: (_, product, _) => MallProductTile(
                  product: product,
                  size: MallCardSize.compact,
                  onTap: () {},
                  onSaveTap: () {},
                ),
              ),
              MallProductGrid(
                products: const [reelProduct, photoOnlyProduct, aiReelProduct],
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
      tester.getSize(find.byType(MallProductTile).first).height,
      lessThanOrEqualTo(railHeight),
    );
  });
}
