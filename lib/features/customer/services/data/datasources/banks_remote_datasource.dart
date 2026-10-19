import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/banks_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';

/// The buyer side of the banks contract v1. Browsing is anonymous; enquiries
/// and appointments need the buyer's token. Writes carry an explicit
/// `Idempotency-Key` from the caller, so a retry is the same request.
class BanksRemoteDataSource {
  BanksRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static Options _idempotent(String key) =>
      Options(headers: {'requiresToken': true, 'Idempotency-Key': key});

  static String _e(String s) => Uri.encodeComponent(s);

  // ── Public ────────────────────────────────────────────────────────────

  Future<List<BankSummary>> listBanks({String? search}) async =>
      readBankSummaries(
        await apiClient.get(
          '/v1/services/banks',
          queryParameters: <String, dynamic>{
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
            'pageSize': 50,
          },
        ),
      );

  Future<BankDetail> getBank(String bankId) async => readBankDetail(
    readJsonObject(await apiClient.get('/v1/services/banks/${_e(bankId)}')),
  );

  /// Products across banks, to compare; [type] null for every type.
  Future<List<BankProduct>> listProducts({
    BankProductType? type,
    String? search,
  }) async => readBankProducts(
    await apiClient.get(
      '/v1/services/banks/products',
      queryParameters: <String, dynamic>{
        'type': ?type?.wire,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'pageSize': 50,
      },
    ),
  );

  Future<BankProduct> getProduct(String productId) async => readBankProduct(
    readJsonObject(
      await apiClient.get('/v1/services/banks/products/${_e(productId)}'),
    ),
  );

  Future<List<BankBranch>> listBranches(String bankId) async =>
      readBankBranches(
        await apiClient.get('/v1/services/banks/${_e(bankId)}/branches'),
      );

  Future<BranchAvailability> getAvailability({
    required String branchId,
    DateTime? from,
    int days = 14,
  }) async => readBranchAvailability(
    readJsonObject(
      await apiClient.get(
        '/v1/services/banks/branches/${_e(branchId)}/availability',
        queryParameters: <String, dynamic>{
          if (from != null) 'from': searchWireDate(from),
          'days': days,
        },
      ),
    ),
  );

  Future<EnquiryForm> getEnquiryForm({
    required String bankId,
    required BankProductType productType,
    LeadKind kind = LeadKind.enquiry,
  }) async => readEnquiryForm(
    readJsonObject(
      await apiClient.get(
        '/v1/services/banks/${_e(bankId)}/enquiry-form',
        queryParameters: <String, dynamic>{
          'productType': productType.wire,
          'kind': kind.wire,
        },
      ),
    ),
  );

  // ── Buyer ─────────────────────────────────────────────────────────────

  Future<BankLead> submitEnquiry({
    required String bankId,
    required BankProductType productType,
    required Map<String, String> answers,
    required ContactDetails contact,
    required String consentVersion,
    required String idempotencyKey,
    String? productId,
    String? branchId,
    String? message,
  }) async => readBankLead(
    readJsonObject(
      await apiClient.post(
        '/v1/service-enquiries',
        data: <String, dynamic>{
          'bankId': bankId,
          'productId': ?productId,
          'productType': productType.wire,
          'branchId': ?branchId,
          'answers': answers,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
          'contact': contactJson(contact),
          'consent': <String, dynamic>{
            'accepted': true,
            'version': consentVersion,
          },
        },
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<List<BankLead>> myEnquiries() async => readBankLeads(
    await apiClient.get(
      '/v1/service-enquiries/me',
      queryParameters: const <String, dynamic>{'pageSize': 50},
    ),
  );

  Future<BankLead> myEnquiry(String leadId) async => readBankLead(
    readJsonObject(
      await apiClient.get('/v1/service-enquiries/me/${_e(leadId)}'),
    ),
  );

  Future<BankLead> withdrawEnquiry({
    required String leadId,
    required String idempotencyKey,
  }) async => readBankLead(
    readJsonObject(
      await apiClient.post(
        '/v1/service-enquiries/me/${_e(leadId)}/withdraw',
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<BankAppointment> bookAppointment({
    required String branchId,
    required String slotId,
    required DateTime date,
    required ContactDetails contact,
    required String consentVersion,
    required String idempotencyKey,
    String? productId,
    BankProductType? productType,
    String? purpose,
  }) async => readBankAppointment(
    readJsonObject(
      await apiClient.post(
        '/v1/service-appointments',
        data: <String, dynamic>{
          'branchId': branchId,
          'slotId': slotId,
          'date': searchWireDate(date),
          'productId': ?productId,
          'productType': ?productType?.wire,
          if (purpose != null && purpose.trim().isNotEmpty)
            'purpose': purpose.trim(),
          'contact': contactJson(contact),
          'consent': <String, dynamic>{
            'accepted': true,
            'version': consentVersion,
          },
        },
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  /// Every appointment, newest first (`upcoming=false`).
  Future<List<BankAppointment>> myAppointments() async => readBankAppointments(
    await apiClient.get(
      '/v1/service-appointments/me',
      queryParameters: const <String, dynamic>{
        'upcoming': false,
        'pageSize': 50,
      },
    ),
  );

  Future<BankAppointment> myAppointment(String appointmentId) async =>
      readBankAppointment(
        readJsonObject(
          await apiClient.get(
            '/v1/service-appointments/me/${_e(appointmentId)}',
          ),
        ),
      );

  Future<BankAppointment> cancelAppointment({
    required String appointmentId,
    required String idempotencyKey,
    String? reason,
  }) async => readBankAppointment(
    readJsonObject(
      await apiClient.post(
        '/v1/service-appointments/me/${_e(appointmentId)}/cancel',
        data: <String, dynamic>{
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
        options: _idempotent(idempotencyKey),
      ),
    ),
  );
}
