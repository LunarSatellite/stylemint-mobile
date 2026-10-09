import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/core/network/upload_filename.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/data/models/customer_kyc_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';

/// Buyer KYC Tier 2 — `v1/customer/kyc`.
class CustomerKycRemoteDataSource {
  CustomerKycRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Options _idempotent(String key) => Options(
    headers: <String, dynamic>{'requiresToken': true, 'Idempotency-Key': key},
  );

  /// `GET /v1/customer/kyc`.
  Future<CustomerKyc> getKyc() async =>
      readCustomerKyc(readJsonObject(await apiClient.get('/v1/customer/kyc')));

  /// `POST /v1/customer/kyc/sessions` — starts a session or returns the open
  /// one.
  Future<CustomerKyc> startSession({required String idempotencyKey}) async =>
      readCustomerKyc(
        readJsonObject(
          await apiClient.post(
            '/v1/customer/kyc/sessions',
            options: _idempotent(idempotencyKey),
          ),
        ),
      );

  /// `POST /v1/customer/kyc/sessions/{id}/documents` — multipart `kind` +
  /// `file`. Re-uploading a kind replaces it.
  Future<CustomerKycDocument> uploadDocument({
    required String sessionId,
    required KycDocumentKind kind,
    required File file,
  }) async {
    final response = await apiClient.postFile(
      '/v1/customer/kyc/sessions/${Uri.encodeComponent(sessionId)}/documents',
      file: file,
      // The part's Content-Type comes from this name, never the bytes — see
      // uploadFilename. The picker re-encodes to JPEG, so this is honest.
      filename: uploadFilename(file.path),
      fields: <String, dynamic>{'kind': kind.wire},
    );
    final document = readCustomerKycDocument(readJsonObject(response));
    if (document == null) {
      throw const FormatException('Unrecognised KYC document kind');
    }
    return document;
  }

  /// `POST /v1/customer/kyc/sessions/{id}/submit`.
  Future<CustomerKyc> submit({
    required String sessionId,
    required KycDetails details,
    required String idempotencyKey,
  }) async => readCustomerKyc(
    readJsonObject(
      await apiClient.post(
        '/v1/customer/kyc/sessions/${Uri.encodeComponent(sessionId)}/submit',
        data: details.toJson(),
        options: _idempotent(idempotencyKey),
      ),
    ),
  );
}
