import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_leads_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_leads_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';

final Provider<BankLeadsRepository> bankLeadsRepositoryProvider =
    Provider<BankLeadsRepository>(
      (ref) => BankLeadsRepositoryImpl(
        BankLeadsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
      ),
    );


/// The bank's counts (`v1/vendor/bank/profile`): new leads, upcoming
/// appointments. No automatic retry: a 404 has to read as "being set up" at
/// once, not as loading-with-error while Riverpod retries.
final FutureProvider<BankVendorSummary> bankVendorSummaryProvider =
    FutureProvider.autoDispose<BankVendorSummary>((ref) async {
      final result = await ref.watch(bankLeadsRepositoryProvider).getProfile();
      return result.fold((f) => throw ServiceLoadException(f), (s) => s);
    }, retry: (_, _) => null);

/// One lead, by id.
final FutureProviderFamily<BankLead, String> bankLeadProvider = FutureProvider
    .autoDispose
    .family<BankLead, String>((ref, leadId) async {
      final result = await ref.watch(bankLeadsRepositoryProvider).getLead(leadId);
      return result.fold((f) => throw ServiceLoadException(f), (l) => l);
    }, retry: (_, _) => null);

/// A lead's notes, oldest first.
final FutureProviderFamily<List<BankLeadNote>, String> bankLeadNotesProvider =
    FutureProvider.autoDispose.family<List<BankLeadNote>, String>((
      ref,
      leadId,
    ) async {
      final result = await ref
          .watch(bankLeadsRepositoryProvider)
          .listNotes(leadId);
      return result.fold((f) => throw ServiceLoadException(f), (n) => n);
    }, retry: (_, _) => null);

/// A day's branch appointments (a Kathmandu calendar date), by start time.
final FutureProviderFamily<List<BankAppointment>, DateTime>
bankAppointmentsForDayProvider = FutureProvider.autoDispose
    .family<List<BankAppointment>, DateTime>((ref, day) async {
      final result = await ref
          .watch(bankLeadsRepositoryProvider)
          .listAppointments(from: day, to: day);
      return result.fold((f) => throw ServiceLoadException(f), (a) {
        final sorted = [...a]
          ..sort((x, y) {
            final xs = x.startUtc, ys = y.startUtc;
            if (xs == null || ys == null) {
              return (x.startTime ?? '').compareTo(y.startTime ?? '');
            }
            return xs.compareTo(ys);
          });
        return sorted;
      });
    }, retry: (_, _) => null);

/// One appointment, by id (looked up around today; see the repository).
final FutureProviderFamily<BankAppointment, String> bankAppointmentProvider =
    FutureProvider.autoDispose.family<BankAppointment, String>((
      ref,
      appointmentId,
    ) async {
      final result = await ref
          .watch(bankLeadsRepositoryProvider)
          .findAppointment(
            appointmentId,
            around: ref.watch(serviceTodayProvider),
          );
      return result.fold((f) => throw ServiceLoadException(f), (a) => a);
    }, retry: (_, _) => null);

