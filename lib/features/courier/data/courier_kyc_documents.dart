import 'dart:io';

import 'package:stylemint_mobile_frontend/features/creator/apply/data/datasources/creator_documents_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/identity_document.dart';
import 'package:uuid/uuid.dart';

/// One captured page, before it is uploaded.
class CourierDocumentCapture {
  const CourierDocumentCapture({
    required this.file,
    required this.type,
    required this.side,
  });

  final File file;
  final IdentityDocumentType type;
  final IdentityDocumentSide side;
}

/// A document that cannot be uploaded, with the reason to show the courier.
///
/// Carries a finished sentence because the alternative — a bare exception the
/// screen renders as "we could not accept those documents" — tells a courier
/// nothing they can act on, and tells a bug report nothing either. Every
/// message here names what to do next.
class CourierDocumentFailure implements Exception {
  const CourierDocumentFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What the upload produced, for the caller to report and to reference.
class CourierDocumentsSubmitted {
  const CourierDocumentsSubmitted({
    required this.sessionId,
    required this.documents,
  });

  final String sessionId;
  final List<IdentityDocument> documents;

  /// The registered selfie, if one was captured.
  IdentityDocument? get selfie {
    for (final doc in documents) {
      if (doc.type == IdentityDocumentType.selfiePhoto) return doc;
    }
    return null;
  }
}

/// Puts a courier's identity documents through Identity's KYC pipeline.
///
/// Deliberately not a new document API. Identity already has one — session,
/// blob upload, register, submit, and an admin approve/reject — and it is
/// account-scoped, so it fits a courier exactly as it fits a vendor or a
/// creator. The existing client is named for its first caller
/// ([CreatorDocumentsRemoteDataSource]) but resolves the account from the
/// session and is not creator-specific; its own providers file says a
/// creator-scoped document API "should not be added", which applies here too.
///
/// The courier KYC endpoint itself still takes only the last four digits and a
/// match reference. That is why this runs first: the documents become real
/// records an admin can open, and the reference the courier submits points at
/// the registered selfie instead of being free text someone typed.
class CourierKycDocuments {
  CourierKycDocuments(this._documents);

  final CreatorDocumentsRemoteDataSource _documents;
  static const _uuid = Uuid();

  /// `VerificationDocumentsController.MaxFileSizeBytes`, and the same number
  /// again in the register-document validator and in nginx's
  /// `client_max_body_size` for this host. Checked here so an oversized photo
  /// is named as such before anything is sent, rather than surfacing as a
  /// bare 413 from whichever of the three rejects it first.
  static const _maxBytes = 25 * 1024 * 1024;

  /// Uploads and registers each capture, then submits the session for review.
  ///
  /// Reuses the account's open session when there is one. A courier who got
  /// halfway and came back would otherwise start a second session, and the
  /// reviewer would see their documents split across two.
  Future<CourierDocumentsSubmitted> submit(
    List<CourierDocumentCapture> captures,
  ) async {
    if (captures.isEmpty) {
      throw ArgumentError.value(captures, 'captures', 'No documents to upload');
    }

    await _checkReadable(captures);

    final session =
        await _documents.getActiveSession() ??
        await _documents.startSession(idempotencyKey: _uuid.v4());

    final registered = <IdentityDocument>[];
    for (final capture in captures) {
      final blob = await _documents.uploadBlob(capture.file);
      registered.add(
        await _documents.registerDocument(
          sessionId: session.id,
          type: capture.type,
          side: capture.side,
          blob: blob,
          // A fresh key per page. They are distinct uploads, so sharing one
          // would make the second register return the first page's record.
          idempotencyKey: _uuid.v4(),
        ),
      );
    }

    await _documents.submitSession(session.id, _uuid.v4());

    return CourierDocumentsSubmitted(
      sessionId: session.id,
      documents: registered,
    );
  }

  /// Refuses the batch before any of it is sent, if a page cannot be read.
  ///
  /// Runs first on purpose. `MultipartFile.fromFile` throws a
  /// `FileSystemException` on a file that has gone — which is not a
  /// `DioException`, so it arrived at the screen with no status code and was
  /// reported as a server-side rejection of the documents. The server had in
  /// fact never been asked: the only requests it saw for a failing submission
  /// were the KYC-session reads, with no `upload-blob` after them.
  ///
  /// A picked photo really can disappear. `ImagePicker` writes its scaled copy
  /// into the app's temporary directory, which the OS may reclaim, and a user
  /// who picks, leaves the app and comes back can return to a path with
  /// nothing behind it.
  ///
  /// Checking all of them up front also keeps a failure clean: the session is
  /// not touched and nothing is half-registered, so "nothing has been
  /// submitted" is true when we say it.
  Future<void> _checkReadable(List<CourierDocumentCapture> captures) async {
    for (final capture in captures) {
      final page = capture.side == IdentityDocumentSide.notApplicable
          ? capture.type.label.toLowerCase()
          : '${capture.side.name} of your ${capture.type.label.toLowerCase()}';

      if (!await capture.file.exists()) {
        throw CourierDocumentFailure(
          'The photo of the $page is no longer on this device — take or pick '
          'it again. Nothing has been submitted.',
        );
      }

      final length = await capture.file.length();
      if (length == 0) {
        throw CourierDocumentFailure(
          'The photo of the $page came through empty. Take it again — '
          'nothing has been submitted.',
        );
      }
      if (length > _maxBytes) {
        throw CourierDocumentFailure(
          'The photo of the $page is larger than 25 MB. Take it again — '
          'nothing has been submitted.',
        );
      }
    }
  }
}
