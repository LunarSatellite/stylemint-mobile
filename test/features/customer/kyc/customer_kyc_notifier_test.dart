import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/kyc_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/repositories/customer_kyc_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/presentation/notifiers/customer_kyc_notifier.dart';

class _MockKycRepository extends Mock implements CustomerKycRepository {}

final _today = DateTime(2026, 10, 9);

KycDetails _details({
  KycDocumentType type = KycDocumentType.citizenship,
  DateTime? dateOfBirth,
  String fullName = 'Aarati Shrestha',
  String addressId = 'addr-1',
}) => KycDetails(
  fullName: fullName,
  dateOfBirth: dateOfBirth ?? DateTime(1995, 4, 12),
  documentType: type,
  documentNumber: '12-34-56789',
  addressId: addressId,
);

Map<KycDocumentKind, File> _photos(Iterable<KycDocumentKind> kinds) => {
  for (final kind in kinds) kind: File('/tmp/${kind.wire}.jpg'),
};

CustomerKyc _session({
  KycStatus status = KycStatus.pending,
  List<KycDocumentKind> onServer = const [],
}) => CustomerKyc(
  tier: 0,
  status: status,
  sessionId: 's1',
  documents: [
    for (final kind in onServer)
      CustomerKycDocument(id: 'd-${kind.wire}', kind: kind),
  ],
);

void main() {
  late _MockKycRepository repository;

  setUpAll(() {
    registerFallbackValue(KycDocumentKind.selfie);
    registerFallbackValue(File('/tmp/fallback.jpg'));
    registerFallbackValue(_details());
  });

  setUp(() => repository = _MockKycRepository());

  CustomerKycNotifier notifier() {
    final n = CustomerKycNotifier(repository, now: () => _today);
    addTearDown(n.dispose);
    return n;
  }

  void uploadsSucceed() {
    when(
      () => repository.uploadDocument(
        sessionId: any(named: 'sessionId'),
        kind: any(named: 'kind'),
        file: any(named: 'file'),
      ),
    ).thenAnswer(
      (invocation) async => right(
        CustomerKycDocument(
          id: 'd',
          kind: invocation.namedArguments[#kind] as KycDocumentKind,
        ),
      ),
    );
  }

  group('load', () {
    test('reads the record', () async {
      when(() => repository.getKyc()).thenAnswer(
        (_) async => right(_session(status: KycStatus.underReview)),
      );
      final n = notifier();
      expect(n.state.loading, isTrue);

      await n.load();

      expect(n.state.loading, isFalse);
      expect(n.state.kyc?.status, KycStatus.underReview);
      expect(n.state.isUnavailable, isFalse);
    });

    test('a 404 means verification is not open yet, not an error', () async {
      when(() => repository.getKyc()).thenAnswer(
        (_) async => left(const EmiFailure(EmiFailureKind.notFound)),
      );
      final n = notifier();
      await n.load();

      expect(n.state.isUnavailable, isTrue);
      expect(n.state.kyc, isNull);
    });
  });

  group('submit', () {
    test('starts a session, uploads every photo, then submits', () async {
      when(
        () => repository.startSession(),
      ).thenAnswer((_) async => right(_session()));
      uploadsSucceed();
      when(
        () => repository.submit(
          sessionId: any(named: 'sessionId'),
          details: any(named: 'details'),
        ),
      ).thenAnswer(
        (_) async => right(_session(status: KycStatus.submitted)),
      );

      final n = notifier();
      final phases = <KycSubmitPhase>[];
      n.addListener((s) {
        if (phases.isEmpty || phases.last != s.phase) phases.add(s.phase);
      }, fireImmediately: false);

      final ok = await n.submit(
        details: _details(),
        captures: _photos(KycDocumentType.citizenship.requiredKinds),
      );

      expect(ok, isTrue);
      expect(phases, [
        KycSubmitPhase.idle,
        KycSubmitPhase.startingSession,
        KycSubmitPhase.uploading,
        KycSubmitPhase.submitting,
        KycSubmitPhase.submitted,
      ]);
      expect(n.state.kyc?.status, KycStatus.submitted);
      expect(n.state.uploadedCount, 3);
      expect(n.state.submitFailure, isNull);
      verify(
        () => repository.uploadDocument(
          sessionId: 's1',
          kind: any(named: 'kind'),
          file: any(named: 'file'),
        ),
      ).called(3);
      verify(
        () => repository.submit(
          sessionId: 's1',
          details: any(named: 'details'),
        ),
      ).called(1);
    });

    test('a passport needs only its bio page and a selfie', () async {
      when(
        () => repository.startSession(),
      ).thenAnswer((_) async => right(_session()));
      uploadsSucceed();
      when(
        () => repository.submit(
          sessionId: any(named: 'sessionId'),
          details: any(named: 'details'),
        ),
      ).thenAnswer((_) async => right(_session(status: KycStatus.submitted)));

      final ok = await notifier().submit(
        details: _details(type: KycDocumentType.passport),
        captures: _photos(const [
          KycDocumentKind.passportBio,
          KycDocumentKind.selfie,
        ]),
      );

      expect(ok, isTrue);
      verify(
        () => repository.uploadDocument(
          sessionId: 's1',
          kind: any(named: 'kind'),
          file: any(named: 'file'),
        ),
      ).called(2);
    });

    test(
      'photos already in the open session are not asked for again',
      () async {
        when(() => repository.startSession()).thenAnswer(
          (_) async => right(
            _session(
              onServer: const [
                KycDocumentKind.citizenshipFront,
                KycDocumentKind.citizenshipBack,
              ],
            ),
          ),
        );
        uploadsSucceed();
        when(
          () => repository.submit(
            sessionId: any(named: 'sessionId'),
            details: any(named: 'details'),
          ),
        ).thenAnswer((_) async => right(_session(status: KycStatus.submitted)));
        when(() => repository.getKyc()).thenAnswer(
          (_) async => right(
            _session(
              onServer: const [
                KycDocumentKind.citizenshipFront,
                KycDocumentKind.citizenshipBack,
              ],
            ),
          ),
        );

        final n = notifier();
        await n.load();
        final ok = await n.submit(
          details: _details(),
          captures: _photos(const [KycDocumentKind.selfie]),
        );

        expect(ok, isTrue);
        verify(
          () => repository.uploadDocument(
            sessionId: 's1',
            kind: KycDocumentKind.selfie,
            file: any(named: 'file'),
          ),
        ).called(1);
      },
    );

    test('under 18 is refused before anything is sent', () async {
      final n = notifier();
      final ok = await n.submit(
        // Turns 18 tomorrow.
        details: _details(dateOfBirth: DateTime(2008, 10, 10)),
        captures: _photos(KycDocumentType.citizenship.requiredKinds),
      );

      expect(ok, isFalse);
      expect(n.state.phase, KycSubmitPhase.idle);
      expect(n.state.submitFailure?.code, KycErrorCode.underage);
      expect(n.state.submitError, contains('18 or older'));
      verifyNever(() => repository.startSession());
    });

    test('the 18th birthday itself is old enough', () {
      expect(isAtLeast18(DateTime(2008, 10, 9), _today), isTrue);
      expect(isAtLeast18(DateTime(2008, 10, 10), _today), isFalse);
    });

    test('a missing selfie is named before any upload', () async {
      final n = notifier();
      final ok = await n.submit(
        details: _details(),
        captures: _photos(const [
          KycDocumentKind.citizenshipFront,
          KycDocumentKind.citizenshipBack,
        ]),
      );

      expect(ok, isFalse);
      expect(n.state.submitFailure?.code, KycErrorCode.documentsMissing);
      expect(n.state.submitFailure?.missing, ['Selfie']);
      expect(n.state.submitError, 'Add Selfie before you submit.');
      verifyNever(() => repository.startSession());
    });

    test('blank details are refused', () async {
      final n = notifier();
      final ok = await n.submit(
        details: _details(fullName: '  ', addressId: ''),
        captures: _photos(KycDocumentType.citizenship.requiredKinds),
      );
      expect(ok, isFalse);
      expect(n.state.submitFailure?.code, KycLocalCode.detailsIncomplete);
    });

    test('a failed upload stops before the submit and says why', () async {
      when(
        () => repository.startSession(),
      ).thenAnswer((_) async => right(_session()));
      when(
        () => repository.uploadDocument(
          sessionId: any(named: 'sessionId'),
          kind: any(named: 'kind'),
          file: any(named: 'file'),
        ),
      ).thenAnswer(
        (_) async => left(const EmiFailure(EmiFailureKind.offline)),
      );

      final n = notifier();
      final ok = await n.submit(
        details: _details(),
        captures: _photos(KycDocumentType.citizenship.requiredKinds),
      );

      expect(ok, isFalse);
      expect(n.state.phase, KycSubmitPhase.idle);
      expect(n.state.submitError, contains('offline'));
      verifyNever(
        () => repository.submit(
          sessionId: any(named: 'sessionId'),
          details: any(named: 'details'),
        ),
      );
    });

    test('the server’s document_number_in_use reaches the buyer', () async {
      when(
        () => repository.startSession(),
      ).thenAnswer((_) async => right(_session()));
      uploadsSucceed();
      when(
        () => repository.submit(
          sessionId: any(named: 'sessionId'),
          details: any(named: 'details'),
        ),
      ).thenAnswer(
        (_) async => left(
          const EmiFailure(
            EmiFailureKind.rejected,
            code: KycErrorCode.documentNumberInUse,
            statusCode: 409,
          ),
        ),
      );

      final n = notifier();
      final ok = await n.submit(
        details: _details(),
        captures: _photos(KycDocumentType.citizenship.requiredKinds),
      );

      expect(ok, isFalse);
      expect(n.state.submitError, contains('another StyleMint account'));

      n.clearSubmitError();
      expect(n.state.submitFailure, isNull);
    });

    test('an already approved buyer is told so', () async {
      when(() => repository.startSession()).thenAnswer(
        (_) async => left(
          const EmiFailure(
            EmiFailureKind.rejected,
            code: KycErrorCode.alreadyApproved,
          ),
        ),
      );
      final n = notifier();
      final ok = await n.submit(
        details: _details(),
        captures: _photos(KycDocumentType.citizenship.requiredKinds),
      );
      expect(ok, isFalse);
      expect(n.state.submitError, contains('already verified'));
    });
  });

  group('kycErrorMessage', () {
    String message(String code, {List<String> missing = const []}) =>
        kycErrorMessage(
          EmiFailure(EmiFailureKind.rejected, code: code, missing: missing),
        );

    test('has a sentence for every contract code', () {
      expect(message(KycErrorCode.alreadyApproved), contains('already'));
      expect(
        message(
          KycErrorCode.documentsMissing,
          missing: ['CitizenshipBack', 'Selfie'],
        ),
        'Add Back of your citizenship and Selfie before you submit.',
      );
      expect(message(KycErrorCode.underage), contains('18'));
      expect(message(KycErrorCode.addressNotFound), contains('address'));
      expect(
        message(KycErrorCode.documentNumberInUse),
        contains('one account'),
      );
    });

    test('local photo problems name the page', () {
      expect(
        message(KycLocalCode.photoTooLarge, missing: ['Selfie']),
        contains('selfie is larger than 10 MB'),
      );
      expect(
        message(KycLocalCode.photoGone, missing: ['PassportBio']),
        contains('passport photo page'),
      );
    });

    test('transport failures', () {
      expect(
        kycErrorMessage(const EmiFailure(EmiFailureKind.notFound)),
        contains('not open yet'),
      );
      expect(
        kycErrorMessage(const EmiFailure(EmiFailureKind.tooLarge)),
        contains('10 MB'),
      );
      expect(
        kycErrorMessage(const EmiFailure(EmiFailureKind.auth)),
        contains('Sign in again'),
      );
      expect(
        kycErrorMessage(
          const EmiFailure(EmiFailureKind.rejected, message: 'Nope.'),
        ),
        'Nope.',
      );
    });
  });
}
