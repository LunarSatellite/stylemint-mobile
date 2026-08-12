import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/identity_document.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_documents_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_documents_notifier.dart';

class _FakeRepository implements CreatorDocumentsRepository {
  _FakeRepository({this.uploadResult, this.listResult, this.submitResult});

  NetworkEither<IdentityDocument>? uploadResult;
  NetworkEither<List<IdentityDocument>>? listResult;
  NetworkEither<Unit>? submitResult;

  int uploadCalls = 0;
  int submitCalls = 0;

  @override
  Future<NetworkEither<IdentityDocument>> uploadIdentityDocument({
    required File file,
    required IdentityDocumentType type,
    IdentityDocumentSide side = IdentityDocumentSide.notApplicable,
  }) async {
    uploadCalls++;
    return uploadResult ?? networkRight(_doc());
  }

  @override
  Future<NetworkEither<List<IdentityDocument>>> listSubmittedDocuments() async =>
      listResult ?? networkRight(<IdentityDocument>[]);

  @override
  Future<NetworkEither<Unit>> submitForReview() async {
    submitCalls++;
    return submitResult ?? networkRight(unit);
  }
}

IdentityDocument _doc({String id = 'doc-1', String status = 'Pending'}) =>
    IdentityDocument(
      id: id,
      sessionId: 'session-1',
      type: IdentityDocumentType.nationalIdCard,
      side: IdentityDocumentSide.front,
      status: status,
      originalFilename: 'id-front.jpg',
    );

void main() {
  final file = File('id-front.jpg');

  group('CreatorDocumentsNotifier', () {
    test('load() populates documents on success', () async {
      final repo = _FakeRepository(listResult: networkRight([_doc()]));
      final notifier = CreatorDocumentsNotifier(repo);

      await notifier.load();

      expect(notifier.state.documents, hasLength(1));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('load() surfaces the repository message on failure', () async {
      final repo = _FakeRepository(
        listResult: networkLeft(const NetworkExceptions.noInternetConnection()),
      );
      final notifier = CreatorDocumentsNotifier(repo);

      await notifier.load();

      expect(notifier.state.errorMessage, 'No internet connection.');
      expect(notifier.state.isLoading, isFalse);
    });

    test('upload() appends the document and reports success', () async {
      final repo = _FakeRepository();
      final notifier = CreatorDocumentsNotifier(repo);

      final ok = await notifier.upload(
        file: file,
        type: IdentityDocumentType.nationalIdCard,
        side: IdentityDocumentSide.front,
      );

      expect(ok, isTrue);
      expect(notifier.state.documents, hasLength(1));
      expect(notifier.state.lastUploadedFilename, 'id-front.jpg');
      expect(notifier.state.isUploading, isFalse);
    });

    test('upload() returns false and does not append on failure', () async {
      final repo = _FakeRepository(
        uploadResult: networkLeft(const NetworkExceptions.unexpectedError()),
      );
      final notifier = CreatorDocumentsNotifier(repo);

      final ok = await notifier.upload(
        file: file,
        type: IdentityDocumentType.passport,
      );

      expect(ok, isFalse);
      expect(notifier.state.documents, isEmpty);
      expect(notifier.state.errorMessage, 'An unexpected error occurred.');
    });

    test('submitForReview() is refused until a document exists', () async {
      final repo = _FakeRepository();
      final notifier = CreatorDocumentsNotifier(repo);

      expect(notifier.state.canSubmit, isFalse);
      final ok = await notifier.submitForReview();

      expect(ok, isFalse);
      // Guarded client-side so an empty session never reaches the backend.
      expect(repo.submitCalls, 0);
    });

    test('submitForReview() succeeds once a document is attached', () async {
      final repo = _FakeRepository();
      final notifier = CreatorDocumentsNotifier(repo);
      await notifier.upload(
        file: file,
        type: IdentityDocumentType.nationalIdCard,
      );

      expect(notifier.state.canSubmit, isTrue);
      final ok = await notifier.submitForReview();

      expect(ok, isTrue);
      expect(repo.submitCalls, 1);
      expect(notifier.state.isSubmitting, isFalse);
    });

    test('rejected exposes only the rejected documents', () async {
      final repo = _FakeRepository(
        listResult: networkRight([
          _doc(),
          _doc(id: 'doc-2', status: 'Rejected'),
        ]),
      );
      final notifier = CreatorDocumentsNotifier(repo);

      await notifier.load();

      expect(notifier.state.rejected, hasLength(1));
      expect(notifier.state.rejected.single.id, 'doc-2');
    });

    test('two-sided document types are flagged for a front and back', () {
      expect(IdentityDocumentType.nationalIdCard.needsBothSides, isTrue);
      expect(IdentityDocumentType.driversLicense.needsBothSides, isTrue);
      expect(IdentityDocumentType.passport.needsBothSides, isFalse);
      expect(IdentityDocumentType.selfiePhoto.needsBothSides, isFalse);
    });

    test('wire values match the backend VerificationDocumentType enum', () {
      expect(IdentityDocumentType.passport.wireValue, 1);
      expect(IdentityDocumentType.nationalIdCard.wireValue, 2);
      expect(IdentityDocumentType.driversLicense.wireValue, 3);
      expect(IdentityDocumentType.addressProof.wireValue, 6);
      expect(IdentityDocumentSide.front.wireValue, 1);
      expect(IdentityDocumentSide.back.wireValue, 2);
    });
  });
}
