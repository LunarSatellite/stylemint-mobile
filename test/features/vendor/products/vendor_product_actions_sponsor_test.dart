import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/widgets/vendor_product_actions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/repositories/sponsored_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockRepository extends Mock implements SponsoredProductsRepository {}

VendorProduct _product(VendorProductStatus status) => VendorProduct(
  id: 'p-1',
  variantId: 'v-1',
  name: 'Linen shirt',
  imageUrl: '',
  price: const Money(amount: 1200, currency: 'NPR'),
  stockCount: 4,
  status: status,
  rating: 4.5,
  createdAt: DateTime(2026, 9),
);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(DateTime.utc(2000)));

  setUp(() => repository = _MockRepository());

  Future<void> openActions(WidgetTester tester, VendorProduct product) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sponsoredProductsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () =>
                    showVendorProductActions(context, ref, product),
                child: const Text('more'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('more'));
    await tester.pumpAndSettle();
  }

  testWidgets('an active product can be sponsored from its actions', (
    tester,
  ) async {
    when(
      () => repository.sponsor(
        productId: any(named: 'productId'),
        dailyImpressionCap: any(named: 'dailyImpressionCap'),
        endsUtc: any(named: 'endsUtc'),
      ),
    ).thenAnswer(
      (_) async => right(
        const SponsoredListing(
          id: 'l-1',
          productId: 'p-1',
          productName: 'Linen shirt',
          state: SponsoredListingState.active,
          isLive: true,
          dailyImpressionCap: 300,
        ),
      ),
    );

    await openActions(tester, _product(VendorProductStatus.active));
    await tester.tap(find.text('Sponsor this product'));
    await tester.pumpAndSettle();

    expect(find.text('Sponsor a product'), findsOneWidget);
    expect(find.text('Linen shirt'), findsOneWidget);
    expect(find.text('Choose a live product'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('sponsor-daily-cap')),
      '300',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => repository.sponsor(productId: 'p-1', dailyImpressionCap: 300),
    ).called(1);
    expect(find.text('Saved. Linen shirt is sponsored.'), findsOneWidget);
  });

  testWidgets('products that are not live have no sponsor row', (
    tester,
  ) async {
    for (final status in [
      VendorProductStatus.draft,
      VendorProductStatus.outOfStock,
    ]) {
      await openActions(tester, _product(status));
      expect(
        find.text('Sponsor this product'),
        findsNothing,
        reason: '$status',
      );
      await tester.pumpWidget(const SizedBox());
    }
  });
}
