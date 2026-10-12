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
  }) async => readCreditAgreement(
    readJsonObject(
      await apiClient.post(
        '/v1/credit/vendor/agreements/${Uri.encodeComponent(agreementId)}/review',
        data: <String, dynamic>{
          'approve': approve,
          if (reasons.isNotEmpty) 'reasons': reasons,
        },
        options: _idempotent(idempotencyKey),
      ),
    ),
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
