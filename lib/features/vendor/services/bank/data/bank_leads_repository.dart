import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_leads_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_page.dart';
import 'package:uuid/uuid.dart';

/// A bank's leads, notes and branch appointments.
abstract class BankLeadsRepository {
  Future<Either<ServiceFailure, BankVendorSummary>> getProfile();

  Future<Either<ServiceFailure, ServicePage<BankLead>>> listLeads({
    BankLeadStatus? status,
    BankLeadKind? kind,
    String? search,
    String? cursor,
  });

  Future<Either<ServiceFailure, BankLead>> getLead(String leadId);

  /// [reason] is required for [BankLeadStatus.closed].
  Future<Either<ServiceFailure, BankLead>> setLeadStatus(
    String leadId,
    BankLeadStatus status, {
    String? reason,
  });

  Future<Either<ServiceFailure, List<BankLeadNote>>> listNotes(String leadId);

  Future<Either<ServiceFailure, BankLeadNote>> addNote(
    String leadId,
    String text,
  );

  /// Appointments starting on the Kathmandu dates [from]..[to], by start
  /// time, every page.
  Future<Either<ServiceFailure, List<BankAppointment>>> listAppointments({
    required DateTime from,
    required DateTime to,
  });

  /// One appointment. The contract has no single-appointment route for the
  /// bank, so this looks it up among the appointments around [around].
  Future<Either<ServiceFailure, BankAppointment>> findAppointment(
    String appointmentId, {
    required DateTime around,
  });

  Future<Either<ServiceFailure, BankAppointment>> cancelAppointment(
    String appointmentId,
    String reason,
  );

  Future<Either<ServiceFailure, BankAppointment>> completeAppointment(
    String appointmentId,
  );

  Future<Either<ServiceFailure, BankAppointment>> markAppointmentNoShow(
    String appointmentId,
  );
}

class BankLeadsRepositoryImpl implements BankLeadsRepository {
  BankLeadsRepositoryImpl(this._remote);

  final BankLeadsRemoteDataSource _remote;

  static const _uuid = Uuid();

  /// Enough for a branch network's appointments over a few months.
  static const _maxPages = 8;

  @override
  Future<Either<ServiceFailure, BankVendorSummary>> getProfile() =>
      guardedServiceCall(_remote.getProfile);

  @override
  Future<Either<ServiceFailure, ServicePage<BankLead>>> listLeads({
    BankLeadStatus? status,
    BankLeadKind? kind,
    String? search,
    String? cursor,
  }) => guardedServiceCall(
    () => _remote.listLeads(
      status: status?.wire,
      kind: kind?.wire,
      search: search?.trim(),
      cursor: cursor,
    ),
  );

  @override
  Future<Either<ServiceFailure, BankLead>> getLead(String leadId) =>
      guardedServiceCall(() => _remote.getLead(leadId));

  @override
  Future<Either<ServiceFailure, BankLead>> setLeadStatus(
    String leadId,
    BankLeadStatus status, {
    String? reason,
  }) => guardedServiceCall(
    () => _remote.setLeadStatus(
      leadId,
      status: status.wire,
      reason: reason,
      idempotencyKey: _uuid.v4(),
    ),
  );

  @override
  Future<Either<ServiceFailure, List<BankLeadNote>>> listNotes(
    String leadId,
  ) => guardedServiceCall(() => _remote.listNotes(leadId));

  @override
  Future<Either<ServiceFailure, BankLeadNote>> addNote(
    String leadId,
    String text,
  ) => guardedServiceCall(
    () => _remote.addNote(leadId, text: text, idempotencyKey: _uuid.v4()),
  );

  @override
  Future<Either<ServiceFailure, List<BankAppointment>>> listAppointments({
    required DateTime from,
    required DateTime to,
  }) => guardedServiceCall(() async {
    final all = <BankAppointment>[];
    String? cursor;
    for (var page = 0; page < _maxPages; page++) {
      final result = await _remote.listAppointments(
        from: from,
        to: to,
        cursor: cursor,
      );
      all.addAll(result.items);
      cursor = result.nextCursor;
      if (cursor == null) break;
    }
    return List<BankAppointment>.unmodifiable(all);
  });

  @override
  Future<Either<ServiceFailure, BankAppointment>> findAppointment(
    String appointmentId, {
    required DateTime around,
  }) async {
    final result = await listAppointments(
      from: around.subtract(const Duration(days: 30)),
      to: around.add(const Duration(days: 60)),
    );
    return result.flatMap((items) {
      for (final a in items) {
        if (a.id == appointmentId) return right(a);
      }
      return left(
        const ServiceFailure(
          ServiceFailureKind.notFound,
          code: 'service_appointment.not_found',
        ),
      );
    });
  }

  @override
  Future<Either<ServiceFailure, BankAppointment>> cancelAppointment(
    String appointmentId,
    String reason,
  ) => guardedServiceCall(
    () => _remote.cancelAppointment(
      appointmentId,
      reason: reason,
      idempotencyKey: _uuid.v4(),
    ),
  );

  @override
  Future<Either<ServiceFailure, BankAppointment>> completeAppointment(
    String appointmentId,
  ) => guardedServiceCall(
    () => _remote.completeAppointment(
      appointmentId,
      idempotencyKey: _uuid.v4(),
    ),
  );

  @override
  Future<Either<ServiceFailure, BankAppointment>> markAppointmentNoShow(
    String appointmentId,
  ) => guardedServiceCall(
    () => _remote.markAppointmentNoShow(
      appointmentId,
      idempotencyKey: _uuid.v4(),
    ),
  );
}

/// Sentences for the bank's own error codes (contract §6).
String? bankErrorMessage(String code) => switch (code) {
  'service_lead.invalid_transition' =>
    'That status change is not allowed any more. Pull to refresh.',
  'service_lead.not_found' => 'This lead is no longer available.',
  'service_appointment.not_found' => 'This appointment is no longer available.',
  'service_appointment.not_cancellable' =>
    'This appointment can no longer be cancelled.',
  'service_vendor.not_a_bank' =>
    'Leads and appointments are for approved banks only.',
  _ => null,
};
