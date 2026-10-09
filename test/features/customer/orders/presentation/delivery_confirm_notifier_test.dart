import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/delivery_confirmation_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_confirm_notifier.dart';

class _MockRepository extends Mock implements DeliveryConfirmationRepository {}

const _qr = 'https://stylemint.voyageritnepal.com/dc/tok_9f8e7d6c5b4a';

const _confirmation = DeliveryConfirmation(
  orderId: 'order-1',
  subOrderId: 'sub-1',
  packageNumber: 'SM-D-00000013',
  status: 'Delivered',
);

void main() {
  late _MockRepository repository;
  late DeliveryConfirmNotifier notifier;

  setUp(() {
    repository = _MockRepository();
    notifier = DeliveryConfirmNotifier(repository);
  });

  tearDown(() => notifier.dispose());

  test('a scanned QR confirms, and the outcome is held', () async {
    when(
      () => repository.confirmByQr(_qr),
    ).thenAnswer((_) async => right(_confirmation));

    expect(await notifier.confirmQr(' $_qr '), isTrue);
    expect(notifier.state, isA<DeliveryConfirmDone>());
    expect(
      (notifier.state as DeliveryConfirmDone).confirmation?.packageNumber,
      'SM-D-00000013',
    );
  });

  test('a typed code is sent as the rider screen shows it, tidied', () async {
    when(
      () => repository.confirmByCode(
        packageNumber: any(named: 'packageNumber'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => right(_confirmation));

    await notifier.confirmCode(packageNumber: ' sm-d-00000013 ', code: '482 913');

    verify(
      () => repository.confirmByCode(
        packageNumber: 'SM-D-00000013',
        code: '482913',
      ),
    ).called(1);
  });

  test('already_confirmed is a success, not an error', () async {
    when(
      () => repository.confirmByQr(_qr),
    ).thenAnswer((_) async => left(const DeliveryConfirmAlreadyConfirmed()));

    expect(await notifier.confirmQr(_qr), isTrue);
    expect(notifier.state, isA<DeliveryConfirmDone>());
  });

  test('a failure is held with a message, and reset allows a retry', () async {
    when(
      () => repository.confirmByQr(_qr),
    ).thenAnswer((_) async => left(const DeliveryConfirmExpired()));

    expect(await notifier.confirmQr(_qr), isFalse);
    final state = notifier.state;
    expect(state, isA<DeliveryConfirmFailed>());
    expect((state as DeliveryConfirmFailed).message, contains('New code'));

    notifier.reset();
    expect(notifier.state, isA<DeliveryConfirmIdle>());
  });

  test('nothing more is sent once the parcel is delivered', () async {
    when(
      () => repository.confirmByQr(_qr),
    ).thenAnswer((_) async => right(_confirmation));

    await notifier.confirmQr(_qr);
    expect(await notifier.confirmQr(_qr), isTrue);
    verify(() => repository.confirmByQr(_qr)).called(1);
  });

  group('deliveryConfirmMessage', () {
    test('says what happened and what to do, for every failure', () {
      expect(
        deliveryConfirmMessage(const DeliveryConfirmNotRecipient()),
        contains("isn't for your account"),
      );
      expect(
        deliveryConfirmMessage(const DeliveryConfirmInvalid()),
        contains("doesn't match"),
      );
      expect(
        deliveryConfirmMessage(const DeliveryConfirmTooManyAttempts()),
        contains('15 minutes'),
      );
      expect(
        deliveryConfirmMessage(const DeliveryConfirmOtherFailure(offline: true)),
        contains('offline'),
      );
      expect(
        deliveryConfirmMessage(
          const DeliveryConfirmOtherFailure(message: 'Server says no'),
        ),
        'Server says no',
      );
      expect(
        deliveryConfirmMessage(const DeliveryConfirmOtherFailure()),
        contains('try again'),
      );
      for (final message in [
        deliveryConfirmMessage(const DeliveryConfirmNotRecipient()),
        deliveryConfirmMessage(const DeliveryConfirmExpired()),
        deliveryConfirmMessage(const DeliveryConfirmInvalid()),
      ]) {
        expect(message, isNot(contains('delivery_proof')));
      }
    });
  });
}
