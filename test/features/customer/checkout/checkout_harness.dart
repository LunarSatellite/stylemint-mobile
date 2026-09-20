import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/payment_method_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

export 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
export 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A mocked [CheckoutRepository], stubbed by [stubCheckout].
class MockCheckoutRepository extends Mock implements CheckoutRepository {}

// ── Layout matrix ───────────────────────────────────────────────────────────
//
// The same shape the Mall kit uses (`mallTestWidths` × `mallTestTextScales`
// in test/shared/presentation/mall/mall_harness.dart), narrowed to the two
// phone widths checkout actually has to survive. 320dp × 1.3 is the pair
// that broke the cart's `_CheckoutBar`, and it is the pair that breaks
// checkout.

/// Logical widths every checkout surface is laid out at.
const List<double> checkoutTestWidths = [320, 390];

/// Default and enlarged accessibility text scales.
const List<double> checkoutTestTextScales = [1, 1.3];

/// Checkout's body is a lazy `ListView`, so a phone-height viewport never
/// builds the bill card or the payment list and a sweep would silently pass
/// on widgets that were never laid out. The default viewport is therefore
/// tall enough to build the whole page in one pass — the same trick
/// `pumpCart` uses with its 1080×2400 default. Horizontal overflow, which is
/// what every bug in this file is, does not care how tall the screen is.
/// Pass [phoneHeight] to get a real phone instead and scroll.
const double fullPageHeight = 4000;

/// A real small-phone viewport, for tests that scroll.
const double phoneHeight = 640;

/// Registers one widget test per width in [checkoutTestWidths] × text scale
/// in [checkoutTestTextScales]. Mirrors `testMallLayouts`.
void testCheckoutLayouts(
  String description,
  Future<void> Function(WidgetTester tester, double width, double textScale)
  body,
) {
  for (final width in checkoutTestWidths) {
    for (final scale in checkoutTestTextScales) {
      testWidgets(
        '$description — ${width.toInt()}dp, text ×$scale',
        (tester) => body(tester, width, scale),
      );
    }
  }
}

/// Fails if layout reported an exception such as a RenderFlex overflow.
void expectNoLayoutErrors(WidgetTester tester) =>
    expect(tester.takeException(), isNull);

// ── Pumping ─────────────────────────────────────────────────────────────────

/// Stubs every [CheckoutRepository] read the checkout notifier makes on load.
///
/// Defaults to [longCheckoutSummary] — the realistic, worst-case content —
/// so a caller that only cares about layout does not have to name fixtures.
void stubCheckout(
  MockCheckoutRepository repository, {
  CheckoutSummary? summary,
  List<ShippingAddress>? addresses,
  List<PaymentMethod>? methods,
  DeliveryChoices? delivery,
}) {
  registerFallbackValue(longDeliveryChoiceList.first);
  registerFallbackValue(const DeliveryPreference());
  final value = summary ?? longCheckoutSummary;
  when(
    () => repository.getCheckoutSummary(),
  ).thenAnswer((_) async => right(value));
  when(() => repository.getShippingAddresses()).thenAnswer(
    (_) async => right(addresses ?? value.availableAddresses),
  );
  when(() => repository.getPaymentMethods()).thenAnswer(
    (_) async => right(methods ?? value.availablePaymentMethods),
  );
  when(
    () => repository.getDeliveryChoices(),
  ).thenAnswer((_) async => right(delivery ?? longDeliveryChoices));
  when(
    () => repository.selectDeliveryChoice(any()),
  ).thenAnswer((_) async => right(unit));
  when(
    () => repository.selectPickupLocation(
      sellerId: any(named: 'sellerId'),
      locationId: any(named: 'locationId'),
    ),
  ).thenAnswer((_) async => right(unit));
  when(() => repository.updateDeliveryPreference(any())).thenAnswer(
    (invocation) async =>
        right(invocation.positionalArguments.first as DeliveryPreference),
  );
}

/// Pumps [RouteNames.checkout] on a [width]-wide screen at [textScale], in
/// the dark app theme, with [repository] behind the checkout providers.
///
/// Follows `pumpCart` in
/// test/features/customer/cart/presentation/basket_findings_test.dart: a real
/// `GoRouter` (checkout pushes to the payment, address-edit and order-success
/// routes), a `ProviderScope` with the repository overridden, and a
/// `MediaQuery` that carries the text scaler.
Future<void> pumpCheckout(
  WidgetTester tester,
  MockCheckoutRepository repository, {
  double width = 390,
  double textScale = 1,
  double height = fullPageHeight,
  String initialLocation = RouteNames.checkout,
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RouteNames.checkout,
        builder: (_, _) => const CheckoutScreen(),
      ),
      GoRoute(
        path: RouteNames.checkoutPayment,
        builder: (_, _) => const PaymentMethodScreen(),
      ),
      GoRoute(
        path: RouteNames.shippingAddEdit,
        builder: (_, _) => const Scaffold(body: Text('Edit address')),
      ),
      GoRoute(
        path: RouteNames.orderSuccess,
        builder: (_, state) =>
            Scaffold(body: Text('Order ${state.pathParameters['orderId']}')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [checkoutRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps the standalone payment-method screen on the same matrix.
Future<void> pumpPaymentMethods(
  WidgetTester tester,
  MockCheckoutRepository repository, {
  double width = 390,
  double textScale = 1,
}) => pumpCheckout(
  tester,
  repository,
  width: width,
  textScale: textScale,
  initialLocation: RouteNames.checkoutPayment,
);

// ── Fixtures ────────────────────────────────────────────────────────────────
//
// Real content, not placeholders. A customer types their own address label,
// vendors name their products at length, and a Kathmandu basket of a few
// garments runs to six figures in rupees. Every one of the three known
// overflows only shows up under strings this long.

const String npr = 'NPR';

/// What a customer actually types into "Label" — not "Home".
const String typedAddressLabel = "Mum's place, Baluwatar";

const String secondTypedAddressLabel = 'Sanepa flat — ring the top-floor bell';

const String longVendorName = 'Kathmandu Atelier & Handloom Collective';

const String longProductName =
    'Hand-loomed pashmina wrap in monsoon grey with contrast selvedge';

/// A basket that costs real money: Rs 1,24,850.00 worth of characters beside
/// a text-scaled "Grand Total".
const Money largeTotal = Money(amount: 124850, currency: npr);

const ShippingAddress defaultAddress = ShippingAddress(
  id: 'addr-1',
  label: typedAddressLabel,
  countryCode: 'NP',
  isDefault: true,
  locationNote: 'Green gate opposite the Baluwatar police post, second floor.',
  latitude: 27.7397,
  longitude: 85.3312,
);

const ShippingAddress secondAddress = ShippingAddress(
  id: 'addr-2',
  label: secondTypedAddressLabel,
  countryCode: 'NP',
  isDefault: false,
  locationNote: 'Behind the Sanepa chowk bakery, blue shutter.',
  latitude: 27.6822,
  longitude: 85.3067,
);

const PaymentMethod codMethod = PaymentMethod(
  id: 'pm-cod',
  type: PaymentMethodType.cod,
  label: 'Cash on delivery',
  isDefault: true,
);

const PaymentMethod cardMethod = PaymentMethod(
  id: 'pm-card',
  type: PaymentMethodType.card,
  label: 'Nabil Bank Visa Debit',
  lastFour: '4417',
  isDefault: false,
);

const List<CheckoutItem> longCheckoutItems = [
  CheckoutItem(
    productId: 'p-1',
    productName: longProductName,
    imageUrl: 'https://example.test/wrap.jpg',
    variantName: 'One size / Monsoon grey',
    quantity: 2,
    unitPrice: Money(amount: 38900, currency: npr),
  ),
  CheckoutItem(
    productId: 'p-2',
    productName: 'Oversized linen co-ord set in washed sand',
    imageUrl: 'https://example.test/coord.jpg',
    variantName: 'M / Washed sand',
    quantity: 1,
    unitPrice: Money(amount: 34950, currency: npr),
  ),
];

const String longEmissionsNote =
    'Fewer vans on the ring road. We measure this per package, honestly.';

const String longPickupNote =
    'Collect from the seller and nothing is shipped at all.';

const List<DeliveryChoice> longDeliveryChoiceList = [
  DeliveryChoice(
    kind: DeliveryChoiceKind.homeDelivery,
    title: 'Home delivery in one consolidated package',
    detail: 'Everything arrives together, two days after dispatch.',
    deliveries: 1,
    readyInDays: 2,
    selected: true,
    recommended: true,
  ),
  DeliveryChoice(
    kind: DeliveryChoiceKind.pickupFromSeller,
    title: 'Pick up from $longVendorName',
    detail: 'Ready to collect in Patan tomorrow afternoon.',
    deliveries: 0,
    readyInDays: 1,
    sellerAccountId: 'seller-1',
    sellerName: longVendorName,
    selected: false,
  ),
];

const DeliveryChoices longDeliveryChoices = DeliveryChoices(
  choices: longDeliveryChoiceList,
  emissionsNote: longEmissionsNote,
  pickupNote: longPickupNote,
);

// ── Pickup counters ─────────────────────────────────────────────────────────
//
// Real registry rows, including the ragged ones. `codes.vendor_stores` records
// what a seller typed and nothing more, so a counter genuinely can have no
// name, no hours, or nothing at all beyond its id.

/// The same delivery choices with collection already selected — the only state
/// in which the counter picker is on screen.
const List<DeliveryChoice> pickupSelectedChoiceList = [
  DeliveryChoice(
    kind: DeliveryChoiceKind.homeDelivery,
    title: 'Home delivery in one consolidated package',
    detail: 'Everything arrives together, two days after dispatch.',
    deliveries: 1,
    readyInDays: 2,
    selected: false,
  ),
  DeliveryChoice(
    kind: DeliveryChoiceKind.pickupFromSeller,
    title: 'Pick up from $longVendorName',
    detail: 'Ready to collect in Patan tomorrow afternoon.',
    deliveries: 0,
    readyInDays: 1,
    sellerAccountId: 'seller-1',
    sellerName: longVendorName,
    selected: true,
  ),
];

/// A fully filled row: everything the registry can hold.
const PickupLocation fullCounter = PickupLocation(
  id: 'loc-1',
  name: 'Patan Durbar Square flagship counter',
  addressLine: 'Mangal Bazaar Road, opposite the Patan Museum ticket window',
  city: 'Lalitpur',
  openingHours: 'Sun–Fri 10:30–19:00, Sat closed',
  confirmation: PickupLocationConfirmation.confirmed,
  confirmationNote: 'The seller confirmed these details this month.',
);

/// A second counter, with no hours recorded — the common half-filled row.
const PickupLocation counterWithoutHours = PickupLocation(
  id: 'loc-2',
  name: 'Thamel pickup desk',
  addressLine: 'Chaksibari Marg, first floor above the bookshop',
  city: 'Kathmandu',
  confirmation: PickupLocationConfirmation.stale,
  confirmationNote: 'Nobody has confirmed these details in over a year.',
);

/// A counter the seller never named. It must never render as "Store".
const PickupLocation unnamedCounter = PickupLocation(
  id: 'loc-3',
  addressLine: 'Jawalakhel chowk, beside the fountain',
  city: 'Lalitpur',
  confirmationNote: 'Nobody has ever confirmed these details.',
);

/// A row with nothing recorded but its id.
const PickupLocation bareCounter = PickupLocation(id: 'loc-4');

const String pickupLocationsNote =
    'These are the seller’s recorded counters, not where your order is now.';

/// Collection selected, with counters to choose from and none chosen yet.
const DeliveryChoices countersAvailableChoices = DeliveryChoices(
  choices: pickupSelectedChoiceList,
  emissionsNote: longEmissionsNote,
  pickupNote: longPickupNote,
  pickupLocations: [fullCounter, counterWithoutHours],
  pickupLocationsNote: pickupLocationsNote,
);

/// Collection selected by a seller who has registered no counter at all. This
/// is the pre-existing behaviour and must stay exactly as it was.
const DeliveryChoices noCounterChoices = DeliveryChoices(
  choices: pickupSelectedChoiceList,
  emissionsNote: longEmissionsNote,
  pickupNote: longPickupNote,
);

/// The basket with collection selected, for counter-picker tests.
const CheckoutSummary pickupCheckoutSummary = CheckoutSummary(
  shippingAddress: defaultAddress,
  paymentMethod: codMethod,
  items: longCheckoutItems,
  subtotal: Money(amount: 112750, currency: npr),
  shipping: Money(amount: 2500, currency: npr),
  tax: Money(amount: 14657.5, currency: npr),
  discount: Money(amount: 5057.5, currency: npr),
  total: largeTotal,
  availableAddresses: [defaultAddress, secondAddress],
  availablePaymentMethods: [codMethod, cardMethod],
  deliveryChoices: pickupSelectedChoiceList,
  emissionsNote: longEmissionsNote,
  pickupNote: longPickupNote,
);

/// The worst realistic case: a typed address label with a default badge, a
/// second saved address, a six-figure total and long product names.
const CheckoutSummary longCheckoutSummary = CheckoutSummary(
  shippingAddress: defaultAddress,
  paymentMethod: codMethod,
  items: longCheckoutItems,
  subtotal: Money(amount: 112750, currency: npr),
  shipping: Money(amount: 2500, currency: npr),
  tax: Money(amount: 14657.5, currency: npr),
  discount: Money(amount: 5057.5, currency: npr),
  total: largeTotal,
  availableAddresses: [defaultAddress, secondAddress],
  availablePaymentMethods: [codMethod, cardMethod],
  deliveryChoices: longDeliveryChoiceList,
  emissionsNote: longEmissionsNote,
  pickupNote: longPickupNote,
);

/// The same basket before any address is saved — checkout shows
/// `_NoAddressCard` and the "Add Shipping Address" bar instead.
const CheckoutSummary noAddressSummary = CheckoutSummary(
  shippingAddress: ShippingAddress.empty(),
  paymentMethod: codMethod,
  items: longCheckoutItems,
  subtotal: Money(amount: 112750, currency: npr),
  shipping: Money(amount: 2500, currency: npr),
  tax: Money(amount: 14657.5, currency: npr),
  discount: Money(amount: 0, currency: npr),
  total: largeTotal,
  availablePaymentMethods: [codMethod, cardMethod],
  deliveryChoices: longDeliveryChoiceList,
  emissionsNote: longEmissionsNote,
);

/// A load failure, for the error path.
const NetworkExceptions checkoutFailure = NetworkExceptions.unexpectedError();
