import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/identity_document.dart';

/// Identity-document upload for the creator apply flow. The account is taken
/// from the session, so callers never pass an id.
abstract interface class CreatorDocumentsRepository {
  /// Uploads [file] and registers it against the account's KYC session,
  /// starting a session first if there isn't an open one.
  Future<NetworkEither<IdentityDocument>> uploadIdentityDocument({
    required File file,
    required IdentityDocumentType type,
    IdentityDocumentSide side,
  });

  /// Documents already attached to the active session. Empty when no session
  /// has been started.
  Future<NetworkEither<List<IdentityDocument>>> listSubmittedDocuments();

  /// Hands the session to reviewers. Call once the creator has uploaded
  /// every document they intend to.
  Future<NetworkEither<Unit>> submitForReview();
}
