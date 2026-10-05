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
}
