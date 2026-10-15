import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';

/// The Credit module's buyer and vendor endpoints.
///
/// No request carries an amount: a quote names an item and terms, a payment
/// names a purpose, and the server works out every figure. Mutations take an
/// explicit idempotency key from the caller, so a retry after a timeout is
/// the same request rather than a second one.
class CreditRemoteDataSource {
  CreditRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static Options _idempotent(String key) =>
      Options(headers: {'requiresToken': true, 'Idempotency-Key': key});

  // ── Public ────────────────────────────────────────────────────────────

  /// `GET /v1/credit/offers/{variantId}` — anonymous allowed.
  Future<PlanOptions> getPlanOptions(String variantId) async => readPlanOptions(
    readJsonObject(
      await apiClient.get(
        '/v1/credit/offers/${Uri.encodeComponent(variantId)}',
      ),
    ),
  );

  // ── Buyer ─────────────────────────────────────────────────────────────

  Future<CreditProfile> getProfile() async => readCreditProfile(
    readJsonObject(await apiClient.get('/v1/credit/me/profile')),
  );

  Future<CreditQuote> createQuote({
    required String variantId,
    required PlanKind kind,
    required int? downPaymentPercent,
    required int tenureMonths,
  }) async => readCreditQuote(
    readJsonObject(
      await apiClient.post(
        '/v1/credit/me/quotes',
        data: <String, dynamic>{
          'variantId': variantId,
          'kind': kind.wire,
          'downPaymentPercent': ?downPaymentPercent,
          'tenureMonths': tenureMonths,
        },
      ),
    ),
  );

  Future<CreditAgreement> apply({
    required String quoteToken,
    required String idempotencyKey,
  }) async => readCreditAgreement(
    readJsonObject(
      await apiClient.post(
        '/v1/credit/me/agreements',
        data: <String, dynamic>{'quoteToken': quoteToken},
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  /// Attaches one identity document or proof of income to an application.
  Future<void> uploadDocument({
    required String agreementId,
    required CreditDocumentKind kind,
    required File file,
    String? filename,
  }) async {
    // The part's type is decided from the file's own bytes, never from the
    // picked name: a photo name with no or a wrong extension made Dio send
    // application/octet-stream, which the server refused ("could not
    // upload"). The name sent is a neutral one to match.
    final type = await creditDocumentMediaType(file);
    await apiClient.postFile(
      '/v1/credit/me/agreements/${Uri.encodeComponent(agreementId)}/documents',
      file: file,
      filename: type == null ? filename : 'document.${type.$2}',
      contentType: type == null ? null : DioMediaType.parse(type.$1),
      fields: <String, dynamic>{'kind': kind.wire},
    );
  }

  /// Sends the documents to the seller.
  Future<CreditAgreement> submitDocuments({
    required String agreementId,
    required String idempotencyKey,
  }) async => readCreditAgreement(
    readJsonObject(
      await apiClient.post(
        '/v1/credit/me/agreements/${Uri.encodeComponent(agreementId)}/documents/submit',
        data: const <String, dynamic>{},
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<List<CreditAgreement>> listAgreements() async =>
      readCreditAgreements(await apiClient.get('/v1/credit/me/agreements'));

  Future<CreditAgreement> getAgreement(String id) async => readCreditAgreement(
    readJsonObject(
      await apiClient.get(
        '/v1/credit/me/agreements/${Uri.encodeComponent(id)}',
      ),
    ),
  );

  Future<CreditAgreement> cancel({
    required String agreementId,
    required String idempotencyKey,
  }) async => readCreditAgreement(
    readJsonObject(
      await apiClient.post(
        '/v1/credit/me/agreements/${Uri.encodeComponent(agreementId)}/cancel',
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<PlanPaymentStart> startPayment({
    required String agreementId,
    required PaymentPurpose purpose,
    required PlanPaymentRail rail,
    required String idempotencyKey,
  }) async => readPlanPaymentStart(
    readJsonObject(
      await apiClient.post(
        '/v1/credit/me/agreements/${Uri.encodeComponent(agreementId)}/payments',
        data: <String, dynamic>{'purpose': purpose.wire, 'method': rail.wire},
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  // ── Vendor ────────────────────────────────────────────────────────────

  Future<List<CreditAgreement>> vendorAgreements({
    AgreementStatus? status,
  }) async => readCreditAgreements(
    await apiClient.get(
      '/v1/credit/vendor/agreements',
      queryParameters: <String, dynamic>{'state': ?status?.wire},
    ),
  );

  Future<CreditAgreement> vendorAgreement(String id) async =>
      readCreditAgreement(
        readJsonObject(
          await apiClient.get(
            '/v1/credit/vendor/agreements/${Uri.encodeComponent(id)}',
          ),
        ),
      );

  Future<CreditAgreement> vendorReview({
    required String agreementId,
    required bool approve,
    required List<String> reasons,
    required String idempotencyKey,
    String? note,
  }) async => readCreditAgreement(
    readJsonObject(
      await apiClient.post(
        '/v1/credit/vendor/agreements/${Uri.encodeComponent(agreementId)}/review',
        data: <String, dynamic>{
          'approve': approve,
          if (reasons.isNotEmpty) 'reasons': reasons,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<VendorCreditApplication> vendorApplication(
    String agreementId,
  ) async => readVendorCreditApplication(
    readJsonObject(
      await apiClient.get(
        '/v1/credit/vendor/applications/${Uri.encodeComponent(agreementId)}',
      ),
    ),
  );

  Future<String> vendorDocumentLink({
    required String agreementId,
    required String documentId,
  }) async => readString(
    readJsonObject(
      await apiClient.get(
        '/v1/credit/vendor/agreements/${Uri.encodeComponent(agreementId)}'
        '/documents/${Uri.encodeComponent(documentId)}/link',
      ),
    )['url'],
  );

  Future<VendorCreditProgram> vendorProgram() async => readVendorCreditProgram(
    readJsonObject(await apiClient.get('/v1/credit/vendor/program')),
  );

  Future<VendorCreditProgram> putVendorProgram(
    VendorCreditProgram program, {
    required String idempotencyKey,
  }) async => readVendorCreditProgram(
    readJsonObject(
      await apiClient.put(
        '/v1/credit/vendor/program',
        data: <String, dynamic>{
          'payLaterEnabled': program.payLaterEnabled,
          'payLaterTenures': program.payLaterTenures,
          'payLaterDownPaymentPercent': program.payLaterDownPaymentPercent,
          'acceptedRiskFeePercent': program.payLaterAcceptedRiskFeePercent,
          'prepayEnabled': program.prepayEnabled,
          'prepayTenures': program.prepayTenures,
          'prepayDepositPercent': program.prepayDepositPercent,
        },
        options: _idempotent(idempotencyKey),
      ),
    ),
  );
}

/// The accepted document type the file's leading bytes show — (media type,
/// extension) — or null when they show none (the server then refuses it
/// with its own reason).
Future<(String, String)?> creditDocumentMediaType(File file) async {
  final head = <int>[];
  await for (final chunk in file.openRead(0, 16)) {
    head.addAll(chunk);
  }
  return sniffCreditDocument(head);
}

(String, String)? sniffCreditDocument(List<int> h) {
  bool at(int i, List<int> bytes) {
    if (h.length < i + bytes.length) return false;
    for (var j = 0; j < bytes.length; j++) {
      if (h[i + j] != bytes[j]) return false;
    }
    return true;
  }

  if (at(0, const [0x25, 0x50, 0x44, 0x46])) return ('application/pdf', 'pdf');
  if (at(0, const [0xFF, 0xD8, 0xFF])) return ('image/jpeg', 'jpg');
  if (at(0, const [0x89, 0x50, 0x4E, 0x47])) return ('image/png', 'png');
  if (at(4, 'ftyp'.codeUnits) && h.length >= 12) {
    final brand = String.fromCharCodes(h.sublist(8, 12));
    if (const ['heic', 'heix', 'hevc', 'heim', 'heis'].contains(brand)) {
      return ('image/heic', 'heic');
    }
    if (const ['mif1', 'msf1'].contains(brand)) return ('image/heif', 'heif');
  }
  return null;
}
