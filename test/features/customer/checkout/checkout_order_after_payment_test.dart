import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/notifiers/checkout_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';

import 'checkout_harness.dart';

// Order only after payment (contract v1.0, 2026-10-28): Place Order with an
// online method creates no order. The reply is the checkout session, waiting
// for its payment, with no order number — so checkout opens the provider's
// page and then waits on the session, never on an order. Cash on delivery,
// and a server from before the change (whose reply still names an order),
// behave exactly as they did.

class _MockCartRepository extends Mock implements CartRepository {}

const _sessionId = '7d1c0f2e-5b9a-4c33-9e61-0a4f8b2d9c17';
const _redirect = 'https://pay.example.test/esewa/checkout?session=7d1c';

const _cart = Cart(
  id: 'cart-1',
  items: [
    CartItem(
      id: 'line-1',
      productId: 'p-1',
      productName: longProductName,
      productImageUrl: '',
      variantName: 'One size / Monsoon grey',
      quantity: 1,
      unitPrice: Money(amount: 38900, currency: npr),
      isInStock: true,
    ),
  ],
  subtotal: Money(amount: 38900, currency: npr),
  shippingTotal: Money(amount: 0, currency: npr),
  taxTotal: Money(amount: 0, currency: npr),
  total: Money(amount: 38900, currency: npr),
);

/// Checkout whose default method is [method], with Place Order answering
/// [placed]. Returns the payment pages opened and the repository.
Future<(List<Uri>, MockCheckoutRepository)> _pumpPlacing(
  WidgetTester tester, {
  required PaymentMethod method,
  required PlaceOrderResult placed,
}) async {
  registerFallbackValue(PaymentMethodType.card);
  final checkout = MockCheckoutRepository();
  stubCheckout(checkout, methods: [method]);
  when(
    () => checkout.placeOrder(
      addressId: any(named: 'addressId'),
      paymentMethod: any(named: 'paymentMethod'),
      idempotencyKey: any(named: 'idempotencyKey'),
    ),
  ).thenAnswer((_) async => right(placed));
  final cart = _MockCartRepository();
  when(() => cart.getCart()).thenAnswer((_) async => right(_cart));

  final opened = <Uri>[];
  await pumpCheckout(
    tester,
    checkout,
    overrides: [
      cartRepositoryProvider.overrideWithValue(cart),
      emiSignedInProvider.overrideWithValue(false),
      checkoutPaymentLauncherProvider.overrideWithValue((uri) async {
        opened.add(uri);
      }),
    ],
  );
  return (opened, checkout);
}

const _esewa = PaymentMethod(
  id: 'pm-esewa',
  type: PaymentMethodType.eSewa,
  label: 'eSewa',
  isDefault: true,
);

void main() {
  testWidgets('an online method with no order yet opens the payment page, '
      'then waits on the checkout session', (tester) async {
    final (opened, checkout) = await _pumpPlacing(
      tester,
      method: _esewa,
      placed: const PlaceOrderResult(
        orderNumber: null,
        requiresPaymentAction: true,
        paymentRedirectUrl: _redirect,
        checkoutSessionId: _sessionId,
      ),
    );

    await tester.tap(find.text('Proceed to Payment'));
    await tester.pumpAndSettle();

    verify(
      () => checkout.placeOrder(
        addressId: defaultAddress.id,
        paymentMethod: PaymentMethodType.eSewa,
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(1);
    expect(opened, [Uri.parse(_redirect)]);
    expect(find.text('Awaiting session $_sessionId'), findsOneWidget);
    // No order exists, so no order screen of any kind.
    expect(find.textContaining('Order '), findsNothing);
  });

  testWidgets('cash on delivery still goes straight to the placed order', (
    tester,
  ) async {
    final (opened, _) = await _pumpPlacing(
      tester,
      method: codMethod,
      placed: const PlaceOrderResult(
        orderNumber: 'NK2026-00051',
        requiresPaymentAction: false,
        checkoutSessionId: _sessionId,
      ),
    );

    // Nothing to pay now, so the button places the order.
    expect(find.text('Proceed to Payment'), findsNothing);
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.text('Order NK2026-00051'), findsOneWidget);
    expect(find.text(orderSuccessPaymentPendingMarker), findsNothing);
    expect(find.textContaining('Awaiting session'), findsNothing);
  });

  testWidgets('a server from before the change still names the order: the '
      'order screen opens waiting for its payment, as before', (tester) async {
    final (opened, _) = await _pumpPlacing(
      tester,
      method: _esewa,
      placed: const PlaceOrderResult(
        orderNumber: 'NK2026-00052',
        requiresPaymentAction: true,
        paymentRedirectUrl: _redirect,
        checkoutSessionId: _sessionId,
      ),
    );

    await tester.tap(find.text('Proceed to Payment'));
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse(_redirect)]);
    expect(find.text('Order NK2026-00052'), findsOneWidget);
    expect(find.text(orderSuccessPaymentPendingMarker), findsOneWidget);
    expect(find.textContaining('Awaiting session'), findsNothing);
  });

  group('CheckoutNotifier.placeOrder', () {
    Future<CheckoutNotifier> loaded(PlaceOrderResult placed) async {
      registerFallbackValue(PaymentMethodType.card);
      final repository = MockCheckoutRepository();
      stubCheckout(repository);
      when(
        () => repository.placeOrder(
          addressId: any(named: 'addressId'),
          paymentMethod: any(named: 'paymentMethod'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => right(placed));
      final notifier = CheckoutNotifier(repository);
      addTearDown(notifier.dispose);
      for (var i = 0; i < 50; i++) {
        final ready = notifier.state.maybeWhen(
          loadSuccess: (_, _) => true,
          orElse: () => false,
        );
        if (ready) break;
        await Future<void>.delayed(Duration.zero);
      }
      await notifier.placeOrder(
        addressId: defaultAddress.id,
        paymentMethod: PaymentMethodType.eSewa,
        idempotencyKey: 'key-1',
      );
      return notifier;
    }

    PlaceOrderState placeState(CheckoutNotifier notifier) =>
        notifier.state.maybeWhen(
          loadSuccess: (_, placeOrderState) => placeOrderState,
          orElse: () => throw StateError('checkout did not load'),
        );

    test('no order number but a session: awaiting payment on it', () async {
      final notifier = await loaded(
        const PlaceOrderResult(
          orderNumber: null,
          requiresPaymentAction: true,
          paymentRedirectUrl: _redirect,
          checkoutSessionId: _sessionId,
        ),
      );
      expect(
        placeState(notifier),
        const PlaceOrderState.awaitingPayment(_sessionId),
      );
    });

    test('an order number: placed, as before', () async {
      final notifier = await loaded(
        const PlaceOrderResult(
          orderNumber: 'NK2026-00053',
          requiresPaymentAction: true,
          paymentRedirectUrl: _redirect,
          checkoutSessionId: _sessionId,
        ),
      );
      expect(
        placeState(notifier),
        const PlaceOrderState.success('NK2026-00053'),
      );
    });

    test('neither an order nor a session is not a placement', () async {
      final notifier = await loaded(
        const PlaceOrderResult(orderNumber: '', requiresPaymentAction: true),
      );
      expect(
        placeState(notifier).maybeWhen(
          failure: (_) => true,
          orElse: () => false,
        ),
        isTrue,
      );
    });
  });
}
