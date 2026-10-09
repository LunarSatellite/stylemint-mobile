import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/delivery_confirmation_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_confirm_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../orders_test_harness.dart';

class _MockRepository extends Mock implements DeliveryConfirmationRepository {}

const _qr = 'https://stylemint.voyageritnepal.com/dc/tok_9f8e7d6c5b4a';

const _confirmation = DeliveryConfirmation(
  orderId: 'order-id',
  subOrderId: 'sub-1',
  packageNumber: 'SM-D-00000013',
  status: 'Delivered',
);

OrderDetail _order({
  bool awaiting = true,
  OrderTrackStatus status = OrderTrackStatus.outForDelivery,
}) => OrderDetail(
  id: 'order-id',
  orderNumber: 'NK2026-00015',
  status: status,
  placedAt: DateTime.utc(2026, 10, 1),
  estimatedDelivery: DateTime.utc(2026, 10, 9),
  items: const [],
  subtotal: const Money(amount: 1000, currency: 'NPR'),
  shipping: const Money(amount: 100, currency: 'NPR'),
  tax: const Money(amount: 0, currency: 'NPR'),
  total: const Money(amount: 1100, currency: 'NPR'),
  shippingAddress: 'Kupondole, Lalitpur',
  paymentMethod: 'eSewa',
  trackingNumber: 'SM-D-00000013',
  canCancel: false,
  canReturn: false,
  delivery: OrderDelivery(
    packageNumber: 'SM-D-00000013',
    status: awaiting ? 'AwaitingConfirmation' : 'InTransit',
    riderName: 'Ram',
    awaitingConfirmation: awaiting,
    subOrderId: 'sub-1',
  ),
);

void main() {
  late _MockRepository repository;
  late int confirmedCalls;

  setUp(() {
    repository = _MockRepository();
    confirmedCalls = 0;
  });

  Widget card({String? scanned}) => ProviderScope(
    overrides: [
      deliveryConfirmationRepositoryProvider.overrideWithValue(repository),
    ],
    child: ordersTestApp(
      SingleChildScrollView(
        child: DeliveryConfirmCard(
          order: _order(),
          onConfirmed: () async => confirmedCalls++,
          scanner: (_) async => scanned,
        ),
      ),
    ),
  );

  test('offered only while the rider waits and the order is open', () {
    expect(DeliveryConfirmCard.isOfferedFor(_order()), isTrue);
    expect(DeliveryConfirmCard.isOfferedFor(_order(awaiting: false)), isFalse);
    expect(
      DeliveryConfirmCard.isOfferedFor(
        _order(status: OrderTrackStatus.delivered),
      ),
      isFalse,
    );
  });

  testWidgets('says the parcel is at the door, with both ways to confirm', (
    tester,
  ) async {
    setPhoneView(tester);
    await tester.pumpWidget(card());

    expect(find.text(DeliveryConfirmCard.title), findsOneWidget);
    expect(find.textContaining('Ram is at your door'), findsOneWidget);
    expect(find.byKey(DeliveryConfirmCard.scanKey), findsOneWidget);
    expect(find.byKey(DeliveryConfirmCard.showCodeKey), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  testWidgets('a scanned rider QR confirms and reloads the order', (
    tester,
  ) async {
    setPhoneView(tester);
    when(
      () => repository.confirmByQr(_qr),
    ).thenAnswer((_) async => right(_confirmation));

    await tester.pumpWidget(card(scanned: _qr));
    await tester.tap(find.byKey(DeliveryConfirmCard.scanKey));
    await tester.pumpAndSettle();

    verify(() => repository.confirmByQr(_qr)).called(1);
    expect(confirmedCalls, 1);
    expect(find.text('Delivered ✓'), findsOneWidget);
  });

  testWidgets('a QR that is not the rider code sends nothing', (tester) async {
    setPhoneView(tester);
    await tester.pumpWidget(card(scanned: 'https://example.com/promo'));
    await tester.tap(find.byKey(DeliveryConfirmCard.scanKey));
    await tester.pumpAndSettle();

    verifyNever(() => repository.confirmByQr(any()));
    expect(find.textContaining("isn't the rider's delivery QR"), findsOneWidget);
    expect(confirmedCalls, 0);
  });

  testWidgets('the typed code confirms with the prefilled package number', (
    tester,
  ) async {
    setPhoneView(tester);
    when(
      () => repository.confirmByCode(
        packageNumber: any(named: 'packageNumber'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => right(_confirmation));

    await tester.pumpWidget(card());
    await tester.tap(find.byKey(DeliveryConfirmCard.showCodeKey));
    await tester.pumpAndSettle();

    final submit = find.byKey(DeliveryCodeForm.submitKey);
    expect(
      tester.widget<OutlinedButton>(submit).onPressed,
      isNull,
      reason: 'nothing to send before six digits',
    );

    await tester.enterText(find.byKey(DeliveryCodeForm.codeFieldKey), '482913');
    await tester.pump();
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    verify(
      () => repository.confirmByCode(
        packageNumber: 'SM-D-00000013',
        code: '482913',
      ),
    ).called(1);
    expect(confirmedCalls, 1);
  });

  testWidgets('a wrong code says so in words, and nothing reloads', (
    tester,
  ) async {
    setPhoneView(tester);
    when(
      () => repository.confirmByCode(
        packageNumber: any(named: 'packageNumber'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => left(const DeliveryConfirmInvalid()));

    await tester.pumpWidget(card());
    await tester.tap(find.byKey(DeliveryConfirmCard.showCodeKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(DeliveryCodeForm.codeFieldKey), '000000');
    await tester.pump();
    await tester.ensureVisible(find.byKey(DeliveryCodeForm.submitKey));
    await tester.tap(find.byKey(DeliveryCodeForm.submitKey));
    await tester.pumpAndSettle();

    expect(find.textContaining("doesn't match this parcel"), findsOneWidget);
    expect(confirmedCalls, 0);
    expectNoLayoutErrors(tester);
  });
}
