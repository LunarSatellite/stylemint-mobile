import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/widgets/store_product_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/entities/saved_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saved_item_card.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_button.dart';

/// The product photographs that used to sit on the browse surfaces were
/// replaced by the Mall kit's typographic ground (owner directive,
/// 2026-09-16: the Mall is video-first, product photos live on product
/// detail). A photo is a fixed box; a tonal ground plus a monogram is not, so
/// these check the swap cannot overflow the smallest phone at the largest
/// comfortable text scale.

const _money = Money(amount: 1800, currency: 'NPR');

Widget _host(Widget child) => MediaQuery(
  data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
  child: MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  late StoreProduct storeProduct;
  late SavedItem savedItem;

  setUp(() {
    storeProduct = const StoreProduct(
      id: 'p-tote-001',
      name: 'Nomad Canvas Tote, water resistant, long strap',
      price: _money,
    );
    savedItem = SavedItem(
      id: 's-1',
      productId: 'p-tote-001',
      productName: 'Nomad Canvas Tote, water resistant, long strap',
      productImageUrl: '',
      price: _money,
      rating: 4.5,
      savedAt: DateTime.utc(2026, 9, 16),
    );
  });

  Future<void> pumpNarrow(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_host(child));
    await tester.pump();
  }

  testWidgets('the store grid card holds at 320dp and text scale 1.3', (
    tester,
  ) async {
    // Two columns with the grid's gutters: the real cell on a 320dp phone.
    await pumpNarrow(
      tester,
      SizedBox(
        width: 150,
        height: 230,
        child: StoreProductCard(product: storeProduct, onTap: () {}),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MallTypeGround), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('the saved-items card holds at 320dp and text scale 1.3', (
    tester,
  ) async {
    await pumpNarrow(
      tester,
      SizedBox(
        width: 150,
        child: SavedItemCard(
          item: savedItem,
          onTap: () {},
          onRemove: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MallTypeGround), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('the reel rail product tile holds at 320dp and text scale 1.3', (
    tester,
  ) async {
    await pumpNarrow(
      tester,
      const ReelRailProductTile(
        productId: 'p-tote-001',
        monogram: 'N',
        priceLabel: 'Rs 1.8K',
        label: 'Shop Nomad Canvas Tote, Rs 1,800',
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MallTypeGround), findsOneWidget);
  });

  testWidgets('the ground holds every box the browse surfaces give it', (
    tester,
  ) async {
    // Every size a replaced photograph used to occupy: the feed's tagged
    // chip, the recommendation chip, the thread row, the saved row, the
    // reel's tagged tile, the mission item and the group's top-product card.
    const boxes = <Size>[
      Size(24, 24),
      Size(32, 32),
      Size(48, 48),
      Size(64, 64),
      Size(72, 72),
      Size(88, 108),
      Size(140, 100),
    ];

    for (final box in boxes) {
      await pumpNarrow(
        tester,
        SizedBox(
          width: box.width,
          height: box.height,
          child: const MallTypeGround(seed: 'p-tote-001', monogram: 'N'),
        ),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'MallTypeGround overflowed at ${box.width}x${box.height}',
      );
    }
  });

  testWidgets('the same product keeps the same face on every surface', (
    tester,
  ) async {
    // MallTypeGround is seeded on the product id, so the tote the buyer saved
    // wears the ground it wore in the store grid. This is the whole reason
    // the replacements pass an id rather than an index or a name.
    expect(
      MallTypeGround.groundIndexFor(storeProduct.id),
      MallTypeGround.groundIndexFor(savedItem.productId),
    );
  });
}
