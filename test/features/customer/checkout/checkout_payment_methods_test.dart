import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';

void main() {
  test('always exposes the four approved checkout payment methods', () {
    final methods = checkoutPaymentMethods();

    expect(
      methods.map((method) => method.type),
      [
        PaymentMethodType.card,
        PaymentMethodType.paypal,
        PaymentMethodType.eSewa,
        PaymentMethodType.cod,
      ],
    );
  });

  test('retains a saved card display value without hiding other methods', () {
    final methods = checkoutPaymentMethods(
      savedCard: const PaymentMethod(
        id: 'payment-method-1',
        type: PaymentMethodType.card,
        label: 'Visa Card',
        lastFour: '0689',
        isDefault: true,
      ),
    );

    expect(methods.first.id, 'payment-method-1');
    expect(methods.first.lastFour, '0689');
    expect(methods, hasLength(4));
  });
}
