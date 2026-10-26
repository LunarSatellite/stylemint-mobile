import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/checkout_emi_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../emi/credit_fakes.dart';

const _variant = 'f0a10cdf-15d7-4402-8774-9ac69f7aa421';

CartItem _item({String variantId = _variant}) => CartItem(
  id: 'line-1',
  productId: 'p-1',
  productName: 'Pashmina overcoat',
  productImageUrl: '',
  variantName: 'M',
  quantity: 1,
  unitPrice: const Money(amount: 60000, currency: 'NPR'),
  isInStock: true,
  variantId: variantId,
);

CreditAgreement _plan({
  int state = 2,
  bool checkedOut = false,
  bool documents = true,
}) => readCreditAgreement({
  ...agreementWire(state: state, checkedOut: checkedOut),
  'documentsSubmittedUtc': documents ? '2026-03-02T05:00:00+00:00' : null,
});

/// Pumps a probe that reads [hasApprovedEmiAwaitingCheckout] the way the
/// checkout screen does to decide what Place Order places.
Future<bool> _probe(
  WidgetTester tester, {
  required List<CreditAgreement> plans,
  List<CartItem>? items,
  bool signedIn = true,
}) async {
  bool? result;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        emiSignedInProvider.overrideWithValue(signedIn),
        myPaymentPlansProvider.overrideWith((ref) async => plans),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            result = hasApprovedEmiAwaitingCheckout(ref, items ?? [_item()]);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return result!;
}

void main() {
  testWidgets('an approved EMI not yet checked out turns Place Order into the EMI order', (
    tester,
  ) async {
    expect(await _probe(tester, plans: [_plan()]), isTrue);
  });

  testWidgets('once the EMI is ordered, Place Order is an ordinary order again', (
    tester,
  ) async {
    expect(await _probe(tester, plans: [_plan(checkedOut: true)]), isFalse);
  });

  testWidgets('a pending or declined application leaves Place Order ordinary', (
    tester,
  ) async {
    expect(await _probe(tester, plans: [_plan(state: 1)]), isFalse);
    expect(await _probe(tester, plans: [_plan(state: 6)]), isFalse);
  });

  testWidgets('an approval without documents does not count', (tester) async {
    expect(await _probe(tester, plans: [_plan(documents: false)]), isFalse);
  });

  testWidgets('an approval for another item leaves Place Order ordinary', (
    tester,
  ) async {
    expect(
      await _probe(tester, plans: [_plan()], items: [_item(variantId: 'other')]),
      isFalse,
    );
  });

  testWidgets('signed out: no EMI order', (tester) async {
    expect(await _probe(tester, plans: [_plan()], signedIn: false), isFalse);
  });
}
