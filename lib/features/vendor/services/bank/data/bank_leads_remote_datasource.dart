import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_page.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';

/// The bank side of the service-banks contract v1 (§4, "Bank"): leads,
/// notes, branch appointments. Every route 404s until the deploy.
class BankLeadsRemoteDataSource {
  BankLeadsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _base = '/v1/vendor/bank';

  static String _id(String id) => Uri.encodeComponent(id);

  Options _write(String idempotencyKey) => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );

  Future<BankVendorSummary> getProfile() async => readBankVendorSummary(
    readJsonObject(await apiClient.get('$_base/profile')),
  );

  Future<ServicePage<BankLead>> listLeads({
    int? status,
    int? kind,
    String? search,
    String? cursor,
    int pageSize = 20,
  }) async => readServicePage(
    await apiClient.get(
      '$_base/leads',
      queryParameters: <String, dynamic>{
        'status': ?status,
        'kind': ?kind,
        if (search != null && search.isNotEmpty) 'search': search,
        'cursor': ?cursor,
        'pageSize': pageSize,
      },
    ),
    readBankLead,
  );

  Future<BankLead> getLead(String leadId) async =>
      readBankLead(readJsonObject(await apiClient.get('$_base/leads/${_id(leadId)}')));

  Future<BankLead> setLeadStatus(
    String leadId, {
    required int status,
    String? reason,
    required String idempotencyKey,
  }) async => readBankLead(
    readJsonObject(
      await apiClient.post(
        '$_base/leads/${_id(leadId)}/status',
        data: <String, dynamic>{
          'status': status,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
        options: _write(idempotencyKey),
      ),
    ),
  );

  Future<List<BankLeadNote>> listNotes(String leadId) async => readServiceList(
    await apiClient.get('$_base/leads/${_id(leadId)}/notes'),
    readBankLeadNote,
  );

  Future<BankLeadNote> addNote(
    String leadId, {
    required String text,
    required String idempotencyKey,
  }) async => readBankLeadNote(
    readJsonObject(
      await apiClient.post(
        '$_base/leads/${_id(leadId)}/notes',
        data: <String, dynamic>{'text': text},
        options: _write(idempotencyKey),
      ),
    ),
  );

  /// Appointments by start time. [from]/[to] are Kathmandu calendar dates.
  Future<ServicePage<BankAppointment>> listAppointments({
    DateTime? from,
    DateTime? to,
    String? branchId,
    int? status,
    String? cursor,
    int pageSize = 50,
  }) async => readServicePage(
    await apiClient.get(
      '$_base/appointments',
      queryParameters: <String, dynamic>{
        if (from != null) 'from': wireDate(from),
        if (to != null) 'to': wireDate(to),
        'branchId': ?branchId,
        'status': ?status,
        'cursor': ?cursor,
        'pageSize': pageSize,
      },
    ),
    readBankAppointment,
  );

  Future<BankAppointment> cancelAppointment(
    String appointmentId, {
    required String reason,
    required String idempotencyKey,
  }) => _appointmentAction(
    appointmentId,
    'cancel',
    idempotencyKey,
    data: <String, dynamic>{'reason': reason},
  );

  Future<BankAppointment> completeAppointment(
    String appointmentId, {
    required String idempotencyKey,
  }) => _appointmentAction(appointmentId, 'complete', idempotencyKey);

  Future<BankAppointment> markAppointmentNoShow(
    String appointmentId, {
    required String idempotencyKey,
  }) => _appointmentAction(appointmentId, 'no-show', idempotencyKey);

  Future<BankAppointment> _appointmentAction(
    String appointmentId,
    String action,
    String idempotencyKey, {
    Map<String, dynamic>? data,
  }) async => readBankAppointment(
    readJsonObject(
      await apiClient.post(
        '$_base/appointments/${_id(appointmentId)}/$action',
        data: data,
        options: _write(idempotencyKey),
      ),
    ),
  );
}
