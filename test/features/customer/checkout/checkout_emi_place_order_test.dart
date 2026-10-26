import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';

import '../emi/credit_fakes.dart';
import 'checkout_harness.dart';

class _MockCartRepository extends Mock implements CartRepository {}

/// The variant [agreementWire]'s plan is for.
const _variant = 'f0a10cdf-15d7-4402-8774-9ac69f7aa421';

const _cart = Cart(
  id: 'cart-1',
  items: [
    CartItem(
      id: 'line-1',
      productId: 'p-1',
      productName: 'Pashmina overcoat',
      productImageUrl: '',
      variantName: 'M',
      quantity: 1,
      unitPrice: Money(amount: 60000, currency: npr),
      isInStock: true,
      variantId: _variant,
    ),
  ],
  subtotal: Money(amount: 60000, currency: npr),
  shippingTotal: Money(amount: 0, currency: npr),
  taxTotal: Money(amount: 0, currency: npr),
  total: Money(amount: 60000, currency: npr),
);

/// Checkout with the seller-approved EMI for the cart's one item, still to be
/// checked out. Returns the credit fake and the payment pages opened.
Future<(FakeCreditRepository, List<Uri>)> _pumpApproved(
  WidgetTester tester, {
  bool cashAllowed = false,
}) async {
  final checkout = MockCheckoutRepository();
  stubCheckout(checkout);
  final cart = _MockCartRepository();
  when(() => cart.getCart()).thenAnswer((_) async => right(_cart));
  final wire = {
    ...agreementWire(checkedOut: false),
    'documentsSubmittedUtc': '2026-03-02T06:20:00+00:00',
    'cashOnDeliveryDownPaymentAllowed': cashAllowed,
  };
  final credit = FakeCreditRepository(agreement: wire);
  if (cashAllowed) credit.placedRedirect = null;
  final opened = <Uri>[];
  await pumpCheckout(
    tester,
    checkout,
    overrides: [
      cartRepositoryProvider.overrideWithValue(cart),
      creditRepositoryProvider.overrideWithValue(credit),
      emiSignedInProvider.overrideWithValue(true),
      myPaymentPlansProvider.overrideWith(
        (ref) async => [readCreditAgreement(wire)],
      ),
      planPaymentLauncherProvider.overrideWithValue((uri) async {
        opened.add(uri);
      }),
    ],
  );
  await tester.pumpAndSettle();
  return (credit, opened);
}

void main() {
  testWidgets('an approved EMI is paid on checkout itself: Place Order places '
      'the plan order and opens the down payment', (tester) async {
    final (credit, opened) = await _pumpApproved(tester);

    // No separate EMI payment page, no "use the button above" in its place.
    expect(find.textContaining('tap Place Order'), findsOneWidget);
    expect(find.textContaining('EMI approved: pay the'), findsOneWidget);
    // Cash is not offered when the seller does not allow it.
    expect(find.text('Cash on delivery'), findsNothing);

    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(credit.checkoutsStarted, 1);
    expect(credit.placements, hasLength(1));
    expect(credit.placements.single.addressId, defaultAddress.id);
    expect(
      credit.placements.single.rail,
      isNot(PlanPaymentRail.cashOnDelivery),
    );
    expect(opened, [Uri.parse('https://pay.example.test/first-payment')]);
    expect(find.text('Order NK2026-00042'), findsOneWidget);
  });

  testWidgets('connectIPS chosen on checkout pays the EMI down payment on the '
      'connectIPS rail', (tester) async {
    final (credit, opened) = await _pumpApproved(tester);

    expect(find.text('connectIPS'), findsOneWidget);
    await tester.tap(find.text('connectIPS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(credit.placements.single.rail, PlanPaymentRail.connectIps);
    expect(opened, [Uri.parse('https://pay.example.test/first-payment')]);
    expect(find.text('Order NK2026-00042'), findsOneWidget);
  });

  testWidgets('seller allows cash: Place Order with cash on delivery orders '
      'the plan with nothing to pay online', (tester) async {
    final (credit, opened) = await _pumpApproved(tester, cashAllowed: true);

    // Checkout's default method here is cash on delivery.
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(credit.placements.single.rail, PlanPaymentRail.cashOnDelivery);
    expect(opened, isEmpty);
    expect(find.text('Order NK2026-00042'), findsOneWidget);
  });
}
