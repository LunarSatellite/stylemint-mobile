import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/product_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/item/service_item_bar.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/item/service_item_section.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../smoke/fake_api_client.dart';
import 'services_fakes.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

ProductDetail _item({
  required String id,
  required String name,
  ServiceItemType? type,
  ServiceItem? service,
  DisplayPrice? price,
}) => ProductDetail(
  id: id,
  name: name,
  description: 'A place to stay by the lake.',
  images: const [],
  price: const Money(amount: 4500, currency: 'NPR'),
  rating: 0,
  reviewCount: 0,
  vendorId: 'v1',
  vendorName: 'Barahi Group',
  vendorAvatarUrl: '',
  isInStock: true,
  variants: const [],
  specifications: const {},
  shippingInfo: '',
  isSaved: false,
  isInCart: false,
  defaultVariantId: 'variant-1',
  productKind: 3,
  serviceType: type,
  displayPrice: price,
  service: service,
);

final _stay = _item(
  id: stayId,
  name: 'Hotel Barahi',
  type: ServiceItemType.stay,
  service: stayItemBlock(),
  price: const DisplayPrice(
    amount: Money(amount: 4500, currency: 'NPR'),
    unit: 'night',
    isFrom: true,
    label: 'from Rs 4,500/night',
  ),
);

final _trip = _item(
  id: packageId,
  name: 'Annapurna Base Camp 7D',
  type: ServiceItemType.package,
  service: packageItemBlock(),
  price: const DisplayPrice(
    amount: Money(amount: 45000, currency: 'NPR'),
    unit: 'person',
    label: 'Rs 45,000 per person',
  ),
);

final _bank = _item(
  id: loanId,
  name: 'Home Loan',
  type: ServiceItemType.bank,
  service: bankItemBlock(),
  price: const DisplayPrice(),
);

/// Pumps the item page for [product] at `/product/{id}` (with [query]),
/// with the bank forms and checkout as stand-in pages.
Future<GoRouter> _pump(
  WidgetTester tester,
  ProductDetail product, {
  FakeBookingsRepository? bookings,
  FakeServiceCartRepository? serviceCart,
  String query = '',
}) async {
  final repository = _MockDiscoveryRepository();
  when(
    () => repository.getProductDetail(any()),
  ).thenAnswer((_) async => right(product));

  await tester.binding.setSurfaceSize(const Size(430, 6000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '${RouteNames.productDetailPath(product.id)}$query',
    routes: [
      GoRoute(
        path: RouteNames.productDetail,
        builder: (_, state) => ProductDetailScreen(
          productId: state.pathParameters['productId']!,
          replaceLineId:
              state.uri.queryParameters[RouteNames.productReplaceLineParam],
          reelTagContextId:
              state.uri.queryParameters[RouteNames.productReelTagParam],
        ),
      ),
      for (final path in [
        RouteNames.bankEnquiryForm,
        RouteNames.bankAppointmentForm,
        RouteNames.cart,
        RouteNames.checkout,
      ])
        GoRoute(
          path: path,
          builder: (_, state) =>
              Scaffold(body: Text('page:${state.uri}', key: Key(path))),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
        productDetailNotifierProvider.overrideWith(
          (ref, id) => ProductDetailNotifier(repository),
        ),
        ...servicesOverrides(bookings: bookings, serviceCart: serviceCart),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _frames(tester);
  return router;
}

Future<void> _frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  // Past the pricing debounce, and the quote's reply.
  await _frames(tester, 12);
}

/// The cart line the server would hold for a stay booked with [o].
CartItem _lineFor(ServiceOptions o) => CartItem(
  id: 'line-new',
  productId: stayId,
  productName: 'Hotel Barahi',
  productImageUrl: '',
  variantName: 'Deluxe Double',
  quantity: 1,
  unitPrice: npr(9000),
  isInStock: true,
  service: ServiceLine(
    lineId: 'line-new',
    kind: o.kind,
    listingId: o.listingId,
    listingTitle: 'Hotel Barahi',
    roomTypeId: o.roomTypeId,
    departureId: o.departureId,
    startDate: o.checkIn!,
    endDate: o.checkOut,
    rooms: o.rooms,
    adults: o.adults,
    children: o.children,
    paymentMode: o.paymentMode,
    totalPrice: npr(9000),
    payNow: npr(9000),
    payAtVenue: npr(0),
  ),
);

bool _enabled(WidgetTester tester, Key key) {
  final button = tester.widget<ButtonStyleButton>(find.byKey(key));
  return button.onPressed != null;
}

void main() {
  group('a stay', () {
    testWidgets('shows its price label and no size or colour', (tester) async {
      await _pump(tester, _stay);
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<Text>(find.byKey(ProductDetailScreen.displayPriceKey))
            .data,
        'from Rs 4,500/night',
      );
      expect(find.textContaining('Select '), findsNothing);
      expect(find.byKey(ServiceItemKeys.datesKey), findsOneWidget);
      expect(find.byKey(ServiceItemKeys.room(roomId)), findsOneWidget);
      expect(find.byKey(ServiceItemKeys.policyKey), findsOneWidget);
      // Nothing to add until a room is chosen and priced.
      expect(_enabled(tester, ServiceItemBar.addKey), isFalse);
      expect(
        tester.widget<Text>(find.byKey(ServiceItemBar.summaryKey)).data,
        'Choose dates and a room',
      );
    });

    testWidgets('a room is priced, a way to pay chosen, and it goes in the '
        'cart with its options', (tester) async {
      final bookings = FakeBookingsRepository();
      final cart = FakeServiceCartRepository();
      await _pump(tester, _stay, bookings: bookings, serviceCart: cart);

      await _tap(tester, find.byKey(ServiceItemKeys.room(roomId)));
      expect(bookings.stayQuotes, hasLength(1));
      expect(bookings.stayQuotes.single['roomTypeId'], roomId);
      expect(
        tester.widget<Text>(find.byKey(ServiceItemKeys.quoteTotalKey)).data,
        'Rs 9,000',
      );

      await _tap(tester, find.byKey(ServiceItemKeys.payMode(PaymentMode.deposit)));
      expect(
        tester.widget<Text>(find.byKey(ServiceItemBar.summaryKey)).data,
        'Total Rs 9,000 · Rs 2,700 now · Rs 6,300 at the venue',
      );
      expect(_enabled(tester, ServiceItemBar.addKey), isTrue);

      await _tap(tester, find.byKey(ServiceItemBar.addKey));
      final added = cart.added.single;
      expect(added['productId'], stayId);
      expect(added['variantId'], 'variant-1');
      final options = added['options']! as ServiceOptions;
      expect(options.roomTypeId, roomId);
      expect(options.paymentMode, PaymentMode.deposit);
      expect(options.adults, 2);
      expect(find.text('Added to cart'), findsOneWidget);
    });

    testWidgets('a sold-out choice says why and cannot be added', (
      tester,
    ) async {
      final bookings = FakeBookingsRepository()
        ..nextStayQuote = () => stayQuote(available: false, reason: 'sold_out');
      await _pump(tester, _stay, bookings: bookings);
      await _tap(tester, find.byKey(ServiceItemKeys.room(roomId)));
      expect(
        tester.widget<Text>(find.byKey(ServiceItemKeys.quoteErrorKey)).data,
        startsWith('Sold out'),
      );
      expect(_enabled(tester, ServiceItemBar.addKey), isFalse);
    });

    testWidgets('a cart refusal is shown, nothing else changes', (
      tester,
    ) async {
      final cart = FakeServiceCartRepository()
        ..addFailure = const ServiceFailure(
          ServiceFailureKind.conflict,
          code: 'cart.service_unavailable',
          statusCode: 409,
        );
      await _pump(tester, _stay, serviceCart: cart);
      await _tap(tester, find.byKey(ServiceItemKeys.room(roomId)));
      await _tap(tester, find.byKey(ServiceItemBar.addKey));
      expect(find.textContaining('Not available for that choice'), findsOneWidget);
    });

    testWidgets('opened from a reel tag, the add credits that tag', (
      tester,
    ) async {
      final cart = FakeServiceCartRepository();
      await _pump(tester, _stay, serviceCart: cart, query: '?tag=tag-9');
      await _tap(tester, find.byKey(ServiceItemKeys.room(roomId)));
      await _tap(tester, find.byKey(ServiceItemBar.buyKey));
      expect(cart.added.single['reelTagContextId'], 'tag-9');
      // Buy now opens the cart, never checkout.
      expect(find.byKey(const Key(RouteNames.cart)), findsOneWidget);
      expect(find.byKey(const Key(RouteNames.checkout)), findsNothing);
    });

    testWidgets('Buy now with this booking already in the cart adds nothing '
        'and opens the cart', (tester) async {
      final cart = FakeServiceCartRepository();
      await _pump(tester, _stay, serviceCart: cart);
      await _tap(tester, find.byKey(ServiceItemKeys.room(roomId)));
      await _tap(tester, find.byKey(ServiceItemBar.addKey));
      expect(cart.added, hasLength(1));
      // The fake answers every add with a cart holding one stay line; make
      // that line the booking just chosen, as the server would.
      final options = cart.added.single['options']! as ServiceOptions;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProductDetailScreen)),
      );
      container
          .read(cartNotifierProvider.notifier)
          .showCart(serviceCart(items: [_lineFor(options)]));
      await _frames(tester);

      await _tap(tester, find.byKey(ServiceItemBar.buyKey));

      expect(cart.added, hasLength(1));
      expect(find.byKey(const Key(RouteNames.cart)), findsOneWidget);
      expect(find.byKey(const Key(RouteNames.checkout)), findsNothing);
    });

    testWidgets('a sold-out room cannot be picked', (tester) async {
      await _pump(tester, _stay);
      // The suite has availableUnits 0 in the fixture.
      await _tap(tester, find.byKey(ServiceItemKeys.room(suiteId)));
      expect(find.text('Sold out for these dates'), findsOneWidget);
    });
  });

  group('a trip', () {
    testWidgets('a departure and travellers go in the cart', (tester) async {
      final bookings = FakeBookingsRepository();
      final cart = FakeServiceCartRepository();
      await _pump(tester, _trip, bookings: bookings, serviceCart: cart);
      expect(
        tester
            .widget<Text>(find.byKey(ProductDetailScreen.displayPriceKey))
            .data,
        'Rs 45,000 per person',
      );
      await _tap(tester, find.byKey(ServiceItemKeys.departure(departureId)));
      await _tap(tester, find.byKey(const Key('service-item-children-plus')));
      expect(bookings.packageQuotes.last['children'], 1);
      expect(bookings.packageQuotes.last['adults'], 2);

      await _tap(tester, find.byKey(ServiceItemBar.addKey));
      final options = cart.added.single['options']! as ServiceOptions;
      expect(options.departureId, departureId);
      expect(options.children, 1);
    });

    testWidgets('a full departure cannot be picked', (tester) async {
      final bookings = FakeBookingsRepository();
      await _pump(tester, _trip, bookings: bookings);
      await _tap(tester, find.byKey(ServiceItemKeys.departure(fullDepartureId)));
      expect(bookings.packageQuotes, isEmpty);
      expect(find.text('Full'), findsOneWidget);
    });
  });

  group('a bank product', () {
    testWidgets('Enquire and Book appointment, never Add to cart', (
      tester,
    ) async {
      await _pump(tester, _bank);
      expect(find.byKey(ServiceItemBar.addKey), findsNothing);
      expect(find.text('Add to Cart'), findsNothing);
      expect(find.byKey(ProductDetailScreen.displayPriceKey), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(ServiceItemKeys.bankRateKey)).data,
        '9.5% – 11.25% p.a.',
      );
      expect(find.text('New Road Branch'), findsOneWidget);

      await _tap(tester, find.byKey(BankItemBar.enquireKey));
      expect(
        find.text('page:${RouteNames.bankEnquiryFormPath(loanId)}'),
        findsOneWidget,
      );
    });

    testWidgets('Book appointment opens the branch form for the product', (
      tester,
    ) async {
      await _pump(tester, _bank);
      await _tap(tester, find.byKey(BankItemBar.appointmentKey));
      expect(
        find.text(
          'page:${RouteNames.bankAppointmentFormPath(bankId, productId: loanId)}',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('an item whose listing could not be read is "being set up"', (
    tester,
  ) async {
    await _pump(
      tester,
      _item(id: stayId, name: 'Hotel Barahi', type: ServiceItemType.stay),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(ServiceItemKeys.settingUpKey), findsOneWidget);
    expect(find.byKey(ServiceItemBar.addKey), findsNothing);
    expect(find.text('Buy Now'), findsNothing);
  });

  testWidgets('a product page is unchanged', (tester) async {
    await _pump(
      tester,
      _item(id: 'p1', name: 'Pashmina scarf').copyWith(productKind: 1),
    );
    expect(find.byKey(ServiceItemKeys.datesKey), findsNothing);
    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.text('Buy Now'), findsOneWidget);
  });
}
