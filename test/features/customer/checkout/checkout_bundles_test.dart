import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/models/checkout_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/checkout_bundle_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart'
    show PlanOptions;
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';

import '../bundles/bundle_fixtures.dart';
import 'checkout_harness.dart';

class _MockCartRepository extends Mock
    implements CartRepository, CartBundlesRepository {}

const _bundleItems = [
  CheckoutItem(
    productId: 'p-jacket',
    productName: 'Down jacket',
    imageUrl: '',
    variantName: 'M',
    quantity: 1,
    unitPrice: Money(amount: 10800, currency: npr),
    bundleGroupId: 'g-1',
    bundleTitle: 'Trekking kit',
    vendorAccountId: 'v-peak',
    vendorName: 'Peak Gear',
  ),
  CheckoutItem(
    productId: 'p-socks',
    productName: 'Wool socks',
    imageUrl: '',
    variantName: '',
    quantity: 2,
    unitPrice: Money(amount: 450, currency: npr),
    bundleGroupId: 'g-1',
    bundleTitle: 'Trekking kit',
    vendorAccountId: 'v-sock',
    vendorName: 'Sock Co',
  ),
];

const _bundleSummary = CheckoutSummary(
  shippingAddress: defaultAddress,
  paymentMethod: codMethod,
  items: _bundleItems,
  subtotal: Money(amount: 11700, currency: npr),
  shipping: Money(amount: 0, currency: npr),
  tax: Money(amount: 0, currency: npr),
  discount: Money(amount: 0, currency: npr),
  total: Money(amount: 11700, currency: npr),
  availableAddresses: [defaultAddress],
  availablePaymentMethods: [codMethod],
  deliveryChoices: longDeliveryChoiceList,
);

Cart _cart({bool purchasable = true, bool withBundle = true}) => CartDto.fromJson(
  bundleCartWire(
    purchasable: purchasable,
    withBundle: withBundle,
    // No ordinary line: its EMI plans would load from the network.
    withLoose: false,
  ),
).toDomain();

void main() {
  test('checkout lines read their bundle and shop', () {
    final item = CheckoutItemDto.fromJson({
      'productId': 'p-1',
      'quantity': 1,
      'unitPriceAmount': 10800,
      'productTitleSnapshot': 'Down jacket',
      'bundleGroupId': 'g-1',
      'bundleTitleSnapshot': 'Trekking kit',
      'vendorAccountId': 'v-peak',
      'vendorNameSnapshot': 'Peak Gear',
    }).toDomain();
    expect(item.isBundleLine, isTrue);
    expect(item.bundleTitle, 'Trekking kit');
    expect(item.vendorName, 'Peak Gear');
  });

  test('parcels: one per shop, none when a line has no shop', () {
    final parcels = checkoutParcels(_bundleItems);
    expect(parcels.map((p) => p.shopName), ['Peak Gear', 'Sock Co']);
    expect(
      checkoutParcels(const [
        CheckoutItem(
          productId: 'p',
          productName: 'x',
          imageUrl: '',
          variantName: '',
          quantity: 1,
          unitPrice: Money(amount: 1, currency: npr),
        ),
      ]),
      isEmpty,
    );
  });

  Future<(MockCheckoutRepository, _MockCartRepository)> pump(
    WidgetTester tester, {
    required Either<NetworkExceptions, CheckoutSummary> first,
    Cart? cart,
  }) async {
    final checkout = MockCheckoutRepository();
    stubCheckout(checkout, summary: _bundleSummary);
    var calls = 0;
    when(() => checkout.getCheckoutSummary()).thenAnswer((_) async {
      calls++;
      return calls == 1 ? first : right(_bundleSummary);
    });
    final cartRepo = _MockCartRepository();
    when(() => cartRepo.getCart()).thenAnswer((_) async => right(cart ?? _cart()));
    await pumpCheckout(
      tester,
      checkout,
      overrides: [
        cartRepositoryProvider.overrideWithValue(cartRepo),
        emiSignedInProvider.overrideWithValue(false),
        myPaymentPlansProvider.overrideWith((ref) async => []),
        // No plans offered: the EMI option never reaches the network.
        planOptionsProvider.overrideWith(
          (ref, variantId) async => PlanOptions(
            variantId: variantId,
            price: const Money(amount: 0, currency: npr),
            options: const [],
          ),
        ),
      ],
    );
    return (checkout, cartRepo);
  }

  testWidgets('a bundle order shows one parcel per shop and no EMI', (
    tester,
  ) async {
    await pump(tester, first: right(_bundleSummary));

    expect(find.byKey(CheckoutParcelsCard.cardKey), findsOneWidget);
    expect(find.text('Arrives in 2 parcels'), findsOneWidget);
    expect(find.text('Parcel 1 · Peak Gear'), findsOneWidget);
    expect(find.text('Parcel 2 · Sock Co'), findsOneWidget);
    expect(find.byKey(CheckoutBundleEmiNote.noteKey), findsOneWidget);
  });

  testWidgets('bundle_unavailable at start: buy separately, then checkout '
      'starts again', (tester) async {
    final (checkout, cartRepo) = await pump(
      tester,
      first: left(const NetworkExceptions.validation(code: 'bundle_unavailable')),
      cart: _cart(purchasable: false),
    );
    when(() => cartRepo.unbundle('g-1')).thenAnswer(
      (_) async => right(_cart(withBundle: false)),
    );

    expect(find.byKey(CheckoutBundleUnavailable.viewKey), findsOneWidget);
    expect(find.text('Trekking kit'), findsOneWidget);

    await tester.tap(find.byKey(CheckoutBundleUnavailable.unbundleKey('g-1')));
    await tester.pumpAndSettle();

    verify(() => cartRepo.unbundle('g-1')).called(1);
    verify(() => checkout.getCheckoutSummary()).called(2);
    expect(find.byKey(CheckoutBundleUnavailable.viewKey), findsNothing);
  });

  testWidgets('bundle_unavailable at start: remove the bundle', (tester) async {
    final (_, cartRepo) = await pump(
      tester,
      first: left(const NetworkExceptions.validation(code: 'bundle_unavailable')),
    );
    when(() => cartRepo.removeBundle('g-1')).thenAnswer(
      (_) async => right(_cart(withBundle: false)),
    );

    await tester.tap(find.byKey(CheckoutBundleUnavailable.removeKey('g-1')));
    await tester.pumpAndSettle();

    verify(() => cartRepo.removeBundle('g-1')).called(1);
    expect(find.byKey(CheckoutBundleUnavailable.viewKey), findsNothing);
  });

  testWidgets('an ordinary order shows no parcels card', (tester) async {
    final checkout = MockCheckoutRepository();
    stubCheckout(
      checkout,
      summary: _bundleSummary.copyWith(
        items: const [
          CheckoutItem(
            productId: 'p',
            productName: 'Shirt',
            imageUrl: '',
            variantName: '',
            quantity: 1,
            unitPrice: Money(amount: 2500, currency: npr),
            vendorAccountId: 'v-1',
          ),
        ],
      ),
    );
    final cartRepo = _MockCartRepository();
    when(() => cartRepo.getCart()).thenAnswer(
      (_) async => right(
        const Cart(
          id: 'c',
          items: [],
          subtotal: Money(amount: 0, currency: npr),
          shippingTotal: Money(amount: 0, currency: npr),
          taxTotal: Money(amount: 0, currency: npr),
          total: Money(amount: 0, currency: npr),
        ),
      ),
    );
    await pumpCheckout(
      tester,
      checkout,
      overrides: [
        cartRepositoryProvider.overrideWithValue(cartRepo),
        emiSignedInProvider.overrideWithValue(false),
        myPaymentPlansProvider.overrideWith((ref) async => []),
        // No plans offered: the EMI option never reaches the network.
        planOptionsProvider.overrideWith(
          (ref, variantId) async => PlanOptions(
            variantId: variantId,
            price: const Money(amount: 0, currency: npr),
            options: const [],
          ),
        ),
      ],
    );

    expect(find.byKey(CheckoutParcelsCard.cardKey), findsNothing);
    expect(find.byKey(CheckoutBundleEmiNote.noteKey), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
