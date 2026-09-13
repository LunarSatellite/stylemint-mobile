import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_acceptance_notifier.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _tracking = 'SM-D-00000001';

const _outForDeliverySealed = DeliveryPackageStatus(
  state: DeliveryPackageState.outForDelivery,
  hasSeal: true,
);
const _deliveredUnsealed = DeliveryPackageStatus(
  state: DeliveryPackageState.delivered,
  hasSeal: false,
);
const _inTransit = DeliveryPackageStatus(
  state: DeliveryPackageState.inTransit,
  hasSeal: true,
);

final _saved = DeliveryAcceptance(
  id: 'acc-1',
  packageId: 'pkg-1',
  trackingNumber: _tracking,
  outcome: DeliveryAcceptanceOutcome.accepted,
  sealIntact: true,
  recordedUtc: DateTime.utc(2026, 9, 13, 12),
);

final _reportedIssue = DeliveryAcceptance(
  id: 'acc-2',
  packageId: 'pkg-1',
  trackingNumber: _tracking,
  outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
  sealIntact: false,
  issueNote: 'Box crushed',
  recordedUtc: DateTime.utc(2026, 9, 13, 12),
);

void main() {
  late _MockOrdersRepository repository;

  setUpAll(() => registerFallbackValue(DeliveryAcceptanceOutcome.accepted));
  setUp(() => repository = _MockOrdersRepository());

  void stubPackage(Either<NetworkExceptions, DeliveryPackageStatus> result) {
    when(
      () => repository.getDeliveryPackageStatus(_tracking),
    ).thenAnswer((_) async => result);
  }

  void stubSaved(Either<NetworkExceptions, DeliveryAcceptance> result) {
    when(
      () => repository.getDeliveryAcceptance(_tracking),
    ).thenAnswer((_) async => result);
  }

  void stubRecord(
    Future<Either<NetworkExceptions, DeliveryAcceptance>> Function() answer,
  ) {
    when(
      () => repository.recordDeliveryAcceptance(
        any(),
        outcome: any(named: 'outcome'),
        sealIntact: any(named: 'sealIntact'),
        issueNote: any(named: 'issueNote'),
      ),
    ).thenAnswer((_) => answer());
  }

  Future<DeliveryAcceptanceNotifier> loaded() async {
    final notifier = DeliveryAcceptanceNotifier(repository, _tracking);
    addTearDown(notifier.dispose);
    await pumpEventQueue();
    return notifier;
  }

  void verifyNothingSent() => verifyNever(
    () => repository.recordDeliveryAcceptance(
      any(),
      outcome: any(named: 'outcome'),
      sealIntact: any(named: 'sealIntact'),
      issueNote: any(named: 'issueNote'),
    ),
  );

  group('checking', () {
    test('asks, with the seal question, when a sealed parcel is out for '
        'delivery and not answered yet', () async {
      stubPackage(right(_outForDeliverySealed));
      stubSaved(left(const NetworkExceptions.notFound()));

      final notifier = DeliveryAcceptanceNotifier(repository, _tracking);
      addTearDown(notifier.dispose);
      expect(notifier.state, isA<DeliveryAcceptanceChecking>());
      await pumpEventQueue();

      final state = notifier.state as DeliveryAcceptanceAsking;
      expect(state.hasSeal, isTrue);
      expect(state.sending, isFalse);
      expect(state.errorMessage, isNull);
    });

    test(
      'asks without the seal question for an unsealed delivered parcel',
      () async {
        stubPackage(right(_deliveredUnsealed));
        stubSaved(left(const NetworkExceptions.notFound()));

        final notifier = await loaded();

        expect((notifier.state as DeliveryAcceptanceAsking).hasSeal, isFalse);
      },
    );

    test('shows a saved answer whatever the package state', () async {
      stubPackage(right(_inTransit));
      stubSaved(right(_saved));

      final notifier = await loaded();

      final state = notifier.state as DeliveryAcceptanceRecorded;
      expect(state.acceptance, same(_saved));
      expect(state.notice, isNull);
    });

    test('hides before the parcel is out for delivery', () async {
      stubPackage(right(_inTransit));
      stubSaved(left(const NetworkExceptions.notFound()));

      expect((await loaded()).state, isA<DeliveryAcceptanceHidden>());
    });

    test('hides when the package is not found', () async {
      stubPackage(left(const NetworkExceptions.notFound()));
      stubSaved(left(const NetworkExceptions.notFound()));

      expect((await loaded()).state, isA<DeliveryAcceptanceHidden>());
    });

    test(
      'hides when the saved-answer check fails for another reason',
      () async {
        stubPackage(right(_outForDeliverySealed));
        stubSaved(left(const NetworkExceptions.serverUnavailable()));

        expect((await loaded()).state, isA<DeliveryAcceptanceHidden>());
      },
    );

    test('hides when the repository throws', () async {
      when(
        () => repository.getDeliveryPackageStatus(_tracking),
      ).thenThrow(StateError('boom'));
      stubSaved(left(const NetworkExceptions.notFound()));

      expect((await loaded()).state, isA<DeliveryAcceptanceHidden>());
    });
  });

  group('submit', () {
    test('sends the answer and shows what was saved', () async {
      stubPackage(right(_outForDeliverySealed));
      stubSaved(left(const NetworkExceptions.notFound()));
      stubRecord(() async => right(_reportedIssue));
      final notifier = await loaded();

      await notifier.submit(
        outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
        sealIntact: false,
        issueNote: '  Box crushed  ',
      );

      final state = notifier.state as DeliveryAcceptanceRecorded;
      expect(state.acceptance, same(_reportedIssue));
      verify(
        () => repository.recordDeliveryAcceptance(
          _tracking,
          outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
          sealIntact: false,
          issueNote: 'Box crushed',
        ),
      ).called(1);
    });

    test(
      'is sending while the answer is on its way, ignoring repeat taps',
      () async {
        stubPackage(right(_outForDeliverySealed));
        stubSaved(left(const NetworkExceptions.notFound()));
        final pending =
            Completer<Either<NetworkExceptions, DeliveryAcceptance>>();
        stubRecord(() => pending.future);
        final notifier = await loaded();

        final sending = notifier.submit(
          outcome: DeliveryAcceptanceOutcome.accepted,
          sealIntact: true,
        );
        expect((notifier.state as DeliveryAcceptanceAsking).sending, isTrue);
        await notifier.submit(
          outcome: DeliveryAcceptanceOutcome.accepted,
          sealIntact: true,
        );

        pending.complete(right(_saved));
        await sending;
        expect(notifier.state, isA<DeliveryAcceptanceRecorded>());
        verify(
          () => repository.recordDeliveryAcceptance(
            any(),
            outcome: any(named: 'outcome'),
            sealIntact: any(named: 'sealIntact'),
            issueNote: any(named: 'issueNote'),
          ),
        ).called(1);
      },
    );

    test('does not send "all good" for a broken seal', () async {
      stubPackage(right(_outForDeliverySealed));
      stubSaved(left(const NetworkExceptions.notFound()));
      final notifier = await loaded();

      await notifier.submit(
        outcome: DeliveryAcceptanceOutcome.accepted,
        sealIntact: false,
      );

      final state = notifier.state as DeliveryAcceptanceAsking;
      expect(state.errorMessage, contains('broken seal'));
      verifyNothingSent();
    });

    test('does not send a refusal without saying why', () async {
      stubPackage(right(_deliveredUnsealed));
      stubSaved(left(const NetworkExceptions.notFound()));
      final notifier = await loaded();

      await notifier.submit(
        outcome: DeliveryAcceptanceOutcome.refused,
        issueNote: '   ',
      );

      expect(
        (notifier.state as DeliveryAcceptanceAsking).errorMessage,
        'Tell us what was wrong.',
      );
      verifyNothingSent();
    });

    test('leaves out the seal for an unsealed parcel and the note for '
        '"all good"', () async {
      stubPackage(right(_deliveredUnsealed));
      stubSaved(left(const NetworkExceptions.notFound()));
      stubRecord(() async => right(_saved));
      final notifier = await loaded();

      await notifier.submit(
        outcome: DeliveryAcceptanceOutcome.accepted,
        sealIntact: true,
        issueNote: 'Lovely',
      );

      verify(
        () => repository.recordDeliveryAcceptance(
          _tracking,
          outcome: DeliveryAcceptanceOutcome.accepted,
          sealIntact: null,
          issueNote: null,
        ),
      ).called(1);
    });

    test(
      'on a 409 reloads and shows the answer that was already saved',
      () async {
        stubPackage(right(_outForDeliverySealed));
        stubSaved(left(const NetworkExceptions.notFound()));
        stubRecord(() async => left(const NetworkExceptions.conflict()));
        final notifier = await loaded();

        stubSaved(right(_saved));
        await notifier.submit(
          outcome: DeliveryAcceptanceOutcome.refused,
          sealIntact: true,
          issueNote: 'Wrong item',
        );

        final state = notifier.state as DeliveryAcceptanceRecorded;
        expect(state.acceptance, same(_saved));
        expect(state.notice, DeliveryAcceptanceNotifier.alreadySavedNotice);
      },
    );

    test("keeps asking with the backend's sentence on a 400", () async {
      const sentence =
          'You can confirm a parcel once it is out for delivery or delivered.';
      stubPackage(right(_outForDeliverySealed));
      stubSaved(left(const NetworkExceptions.notFound()));
      stubRecord(
        () async => left(
          const NetworkExceptions.validation(
            code: 'business_rule',
            message: sentence,
          ),
        ),
      );
      final notifier = await loaded();

      await notifier.submit(
        outcome: DeliveryAcceptanceOutcome.accepted,
        sealIntact: true,
      );

      final state = notifier.state as DeliveryAcceptanceAsking;
      expect(state.sending, isFalse);
      expect(state.hasSeal, isTrue);
      expect(state.errorMessage, sentence);
    });

    test('says so plainly when offline', () async {
      stubPackage(right(_deliveredUnsealed));
      stubSaved(left(const NetworkExceptions.notFound()));
      stubRecord(
        () async => left(const NetworkExceptions.noInternetConnection()),
      );
      final notifier = await loaded();

      await notifier.submit(outcome: DeliveryAcceptanceOutcome.accepted);

      expect(
        (notifier.state as DeliveryAcceptanceAsking).errorMessage,
        'No internet connection. Please try again.',
      );
    });

    test('hides the card when the package is gone (404)', () async {
      stubPackage(right(_deliveredUnsealed));
      stubSaved(left(const NetworkExceptions.notFound()));
      stubRecord(() async => left(const NetworkExceptions.notFound()));
      final notifier = await loaded();

      await notifier.submit(outcome: DeliveryAcceptanceOutcome.accepted);

      expect(notifier.state, isA<DeliveryAcceptanceHidden>());
    });
  });

  group('deliveryAcceptanceProblem', () {
    test('null when the answer is complete', () {
      expect(
        deliveryAcceptanceProblem(
          outcome: DeliveryAcceptanceOutcome.accepted,
          hasSeal: true,
          sealIntact: true,
        ),
        isNull,
      );
      expect(
        deliveryAcceptanceProblem(
          outcome: DeliveryAcceptanceOutcome.accepted,
          hasSeal: false,
        ),
        isNull,
      );
      expect(
        deliveryAcceptanceProblem(
          outcome: DeliveryAcceptanceOutcome.refused,
          hasSeal: true,
          sealIntact: false,
          issueNote: 'x' * deliveryAcceptanceMaxNoteLength,
        ),
        isNull,
      );
    });

    test('requires the seal answer and a choice', () {
      expect(
        deliveryAcceptanceProblem(
          outcome: DeliveryAcceptanceOutcome.accepted,
          hasSeal: true,
        ),
        'Tell us whether the seal was intact.',
      );
      expect(
        deliveryAcceptanceProblem(outcome: null, hasSeal: false),
        'Choose what happened with your parcel.',
      );
      expect(
        deliveryAcceptanceProblem(
          outcome: DeliveryAcceptanceOutcome.unknown,
          hasSeal: false,
        ),
        'Choose what happened with your parcel.',
      );
    });

    test('issue choices need a note of at most 1000 characters', () {
      expect(
        deliveryAcceptanceProblem(
          outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
          hasSeal: false,
        ),
        'Tell us what was wrong.',
      );
      expect(
        deliveryAcceptanceProblem(
          outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
          hasSeal: false,
          issueNote: 'x' * (deliveryAcceptanceMaxNoteLength + 1),
        ),
        'Keep your note to 1,000 characters or fewer.',
      );
    });
  });
}
