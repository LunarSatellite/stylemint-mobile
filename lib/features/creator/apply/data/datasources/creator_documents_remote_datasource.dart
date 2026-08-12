import 'dart:io';

import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/identity_document.dart';

/// Identity-document upload for the creator apply flow.
///
/// These endpoints live in the Identity module under the **account** scope,
/// not under `/v1/creator/*` — the same KYC pipeline serves creators and
/// vendors, so there is no creator-specific document API to call and one
/// should not be added.
///
/// Registering a document is a four-step flow:
///   1. `GET  /v1/accounts/{id}/kyc-sessions/active` — reuse the open session
///   2. `POST /v1/accounts/{id}/kyc-sessions` — or start one if there is none
///   3. `POST /v1/accounts/{id}/verification-documents/upload-blob` — bytes
///   4. `POST /v1/accounts/{id}/verification-documents` — register the blob
/// then `POST /v1/accounts/{id}/kyc-sessions/{sessionId}/submit` once the
/// creator has supplied every document they intend to.
class CreatorDocumentsRemoteDataSource {
  CreatorDocumentsRemoteDataSource({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  /// Account-scoped endpoints resolve the id from the session rather than
  /// taking it as a parameter, matching the other account-scoped datasources.
  Future<String> _base() async {
    final id = await tokenStorage.accountId;
    if (id == null || id.isEmpty) throw const NetworkExceptions.auth();
    return '/v1/accounts/$id';
  }

  /// The account's open KYC session, or null when it has none yet.
  Future<KycSession?> getActiveSession() async {
    final response = await apiClient.get('${await _base()}/kyc-sessions/active');
    if (response is! Map<String, dynamic>) return null;
    final session = _sessionFrom(response);
    return session.id.isEmpty ? null : session;
  }

  Future<KycSession> startSession({
    required String idempotencyKey,
    String provider = 'manual',
  }) async {
    final response = await apiClient.post(
      '${await _base()}/kyc-sessions',
      data: <String, dynamic>{'provider': provider},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return _sessionFrom(response as Map<String, dynamic>);
  }

  /// Pushes the bytes to blob storage. Returns the descriptor that
  /// [registerDocument] needs — the file is not attached to anything yet.
  Future<UploadedDocumentBlob> uploadBlob(File file) async {
    final response = await apiClient.postFile(
      '${await _base()}/verification-documents/upload-blob',
      file: file,
    );
    final m = response as Map<String, dynamic>;
    return UploadedDocumentBlob(
      blobReference: (m['blobReference'] as String?) ?? '',
      contentHash: (m['contentHash'] as String?) ?? '',
      contentSizeBytes: (m['contentSizeBytes'] as num?)?.toInt() ?? 0,
      contentType: (m['contentType'] as String?) ?? '',
      originalFilename: m['originalFilename'] as String?,
    );
  }

  Future<IdentityDocument> registerDocument({
    required String sessionId,
    required IdentityDocumentType type,
    required IdentityDocumentSide side,
    required UploadedDocumentBlob blob,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '${await _base()}/verification-documents',
      data: <String, dynamic>{
        'sessionId': sessionId,
        'documentType': type.wireValue,
        'side': side.wireValue,
        'blobReference': blob.blobReference,
        'contentHash': blob.contentHash,
        'contentSizeBytes': blob.contentSizeBytes,
        'contentType': blob.contentType,
        'originalFilename': blob.originalFilename,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return _documentFrom(response as Map<String, dynamic>);
  }

  Future<List<IdentityDocument>> listBySession(String sessionId) async {
    final response = await apiClient.get(
      '${await _base()}/verification-documents/by-session/$sessionId',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_documentFrom)
        .toList(growable: false);
  }

  Future<void> submitSession(String sessionId, String idempotencyKey) async {
    await apiClient.post(
      '${await _base()}/kyc-sessions/$sessionId/submit',
      data: <String, dynamic>{},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  KycSession _sessionFrom(Map<String, dynamic> m) => KycSession(
        id: (m['id'] as String?) ?? (m['sessionId'] as String?) ?? '',
        status: (m['status'] as String?) ?? '',
      );

  IdentityDocument _documentFrom(Map<String, dynamic> m) {
    final typeCode = (m['documentType'] as num?)?.toInt() ?? 0;
    final sideCode = (m['side'] as num?)?.toInt() ?? 0;
    return IdentityDocument(
      id: (m['id'] as String?) ?? '',
      sessionId: (m['sessionId'] as String?) ?? '',
      type: IdentityDocumentType.values.firstWhere(
        (t) => t.wireValue == typeCode,
        orElse: () => IdentityDocumentType.nationalIdCard,
      ),
      side: IdentityDocumentSide.values.firstWhere(
        (s) => s.wireValue == sideCode,
        orElse: () => IdentityDocumentSide.notApplicable,
      ),
      status: (m['status'] as String?) ?? '',
      originalFilename: m['originalFilename'] as String?,
      rejectionReason: (m['rejectionReason'] ?? m['reviewNotes']) as String?,
    );
  }
}
