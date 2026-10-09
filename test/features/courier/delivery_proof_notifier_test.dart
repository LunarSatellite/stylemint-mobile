import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/repositories/courier_repository.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_job_notifiers.dart';

class _MockCourierRepository extends Mock implements CourierRepository {}

final _now = DateTime.utc(2026, 10, 9, 8);

DeliveryProof _proof({
  DeliveryProofStatus status = DeliveryProofStatus.pending,
  String code = '482913',
  Duration left = const Duration(minutes: 30),
}) => DeliveryProof(
  hopId: 'hop-1',
  packageNumber: 'SM-D-00000013',
  status: status,
  qrPayload: 'https://stylemint.voyageritnepal.com/dc/tok_$code',
  code: code,
  expiresUtc: _now.add(left),
);

const _poll = Duration(milliseconds: 10);

/// Long enough for a few polls to run.
Future<void> _polls() => Future<void>.delayed(_poll * 5);

void main() {
  late _MockCourierRepository repository;

  setUp(() => repository = _MockCourierRepository());

  DeliveryProofNotifier notifier({DeliveryProof? initial}) {
    final n = DeliveryProofNotifier(
      repository,
      'hop-1',
      initial: initial,
      pollInterval: _poll,
      now: () => _now,
    );
    addTearDown(n.dispose);
    return n;
  }

  test('shows the code from "Complete ride" without reading it again', () {
    final n = notifier(initial: _proof());

    expect(n.state, isA<DeliveryProofShowing>());
    expect((n.state as DeliveryProofShowing).proof.code, '482913');
    expect(n.isPolling, isTrue);
    verifyNever(() => repository.getProof(any()));
  });

  test('polls until the recipient confirms, then stops', () async {
    when(
      () => repository.getProof('hop-1'),
    ).thenAnswer((_) async => right(_proof(status: DeliveryProofStatus.confirmed)));

    final n = notifier(initial: _proof());
    await _polls();

    expect(n.state, isA<DeliveryProofConfirmed>());
    expect(n.isPolling, isFalse);
  });

  test('a failed poll keeps the live code on screen', () async {
    when(() => repository.getProof('hop-1')).thenAnswer(
      (_) async => left(const NetworkExceptions.noInternetConnection()),
    );

    final n = notifier(initial: _proof());
    await _polls();

    expect(n.state, isA<DeliveryProofShowing>());
    expect(n.isPolling, isTrue);
  });

  test('Expired from the server stops polling and offers a new code', () async {
    when(
      () => repository.getProof('hop-1'),
    ).thenAnswer((_) async => right(_proof(status: DeliveryProofStatus.expired)));

    final n = notifier(initial: _proof());
    await _polls();

    expect(n.state, isA<DeliveryProofExpired>());
    expect(n.isPolling, isFalse);
  });

  test('a code past its expiry is expired at once, by the clock', () {
    final n = notifier(initial: _proof(left: Duration.zero));
    expect(n.state, isA<DeliveryProofExpired>());
    expect(n.isPolling, isFalse);
  });

  test('"New code" asks for a fresh proof and shows it', () async {
    when(
      () => repository.completeJob('hop-1'),
    ).thenAnswer((_) async => right(_proof(code: '111222')));

    final n = notifier(initial: _proof(left: Duration.zero));
    await n.renew();

    expect(n.state, isA<DeliveryProofShowing>());
    expect((n.state as DeliveryProofShowing).proof.code, '111222');
    expect(n.isPolling, isTrue);
    verify(() => repository.completeJob('hop-1')).called(1);
  });

  test('opened without a proof, it reads one', () async {
    when(
      () => repository.getProof('hop-1'),
    ).thenAnswer((_) async => right(_proof()));

    final n = notifier();
    await Future<void>.delayed(Duration.zero);

    expect(n.state, isA<DeliveryProofShowing>());
  });

  test('a proof that cannot be read at all is a failure with a retry', () async {
    when(() => repository.getProof('hop-1')).thenAnswer(
      (_) async => left(const NetworkExceptions.serverUnavailable()),
    );

    final n = notifier();
    await Future<void>.delayed(Duration.zero);

    expect(n.state, isA<DeliveryProofFailed>());
    expect(n.isPolling, isFalse);
  });
}
