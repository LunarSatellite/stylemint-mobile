import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/models/checkout_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';

import '../../codes/support/recording_api_client.dart';
import 'checkout_harness.dart';

/// connectIPS (NCHL) is an online payment method like eSewa — connectIPS
/// contract v1.0 §1 and §5. On the wire it is backend `PaymentMethod` 5.
void main() {
  group('the wire', () {
    test('placing an order with connectIPS sends payment method 5', () async {
      final client = RecordingApiClient((call) {
        if (call.uri.endsWith('/place')) {
          return {
            'orderNumber': 'NK2026-00077',
            'paymentRequiresAction': true,
            'paymentRedirectUrl': 'https://pay.example.test/connectips',
          };
        }
        return {'id': 'sess-1'};
      });

      final placed = await CheckoutRemoteDataSource(apiClient: client)
          .placeOrder(
            addressId: 'addr-1',
            paymentMethod: PaymentMethodType.connectIps,
            idempotencyKey: 'place-connectips',
          );

      final method = client.calls.singleWhere(
        (call) => call.uri.endsWith('/payment-method'),
      );
      expect(method.data, {'paymentMethod': 5});
      // Handed off exactly like eSewa: the order exists, payment pending.
      expect(placed.requiresPaymentAction, isTrue);
      expect(placed.paymentRedirectUrl, 'https://pay.example.test/connectips');
    });

    test('a saved method reads "ConnectIps", "connectIps" and 5', () {
      for (final code in ['ConnectIps', 'connectIps', 'CONNECTIPS', '5']) {
        final method = PaymentMethodDto(
          id: 'pm-$code',
          type: code,
          label: 'connectIPS',
          isDefault: false,
        ).toDomain();
        expect(method.type, PaymentMethodType.connectIps, reason: code);
      }
    });
  });

  group('EMI rails', () {
    test('connectIPS is an online plan rail on wire 5', () {
      expect(PlanPaymentRail.online, contains(PlanPaymentRail.connectIps));
      expect(
        PlanPaymentRail.online,
        isNot(contains(PlanPaymentRail.cashOnDelivery)),
      );
      expect(PlanPaymentRail.connectIps.wire, 5);
      expect(PlanPaymentRail.connectIps.label, 'connectIPS');
    });
  });

  group('the checkout screen', () {
    late MockCheckoutRepository repository;

    setUp(() {
      registerFallbackValue(PaymentMethodType.cod);
      repository = MockCheckoutRepository();
      stubCheckout(repository);
      when(
        () => repository.placeOrder(
          addressId: any(named: 'addressId'),
          paymentMethod: any(named: 'paymentMethod'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer(
        (_) async => right(
          const PlaceOrderResult(
            orderNumber: 'NK2026-00077',
            requiresPaymentAction: false,
          ),
        ),
      );
    });

    testWidgets('lists connectIPS as paying from a bank account', (
      tester,
    ) async {
      await pumpCheckout(tester, repository);

      expect(find.text('connectIPS'), findsOneWidget);
      expect(find.text('Pay from your bank account'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('choosing connectIPS places the order with connectIPS', (
      tester,
    ) async {
      await pumpCheckout(tester, repository);

      await tester.tap(find.text('connectIPS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();

      verify(
        () => repository.placeOrder(
          addressId: any(named: 'addressId'),
          paymentMethod: PaymentMethodType.connectIps,
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
    });
  });
}
