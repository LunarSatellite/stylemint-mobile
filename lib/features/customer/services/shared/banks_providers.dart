import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/datasources/banks_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/repositories/banks_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/repositories/banks_repository.dart';

final banksRemoteDataSourceProvider = Provider<BanksRemoteDataSource>(
  (ref) => BanksRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final banksRepositoryProvider = Provider<BanksRepository>(
  (ref) => BanksRepositoryImpl(
    remote: ref.watch(banksRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// No automatic retry: Riverpod 3 would keep a failed load "loading" while it
/// retries, and a 404 has to read as "Services are coming soon" at once.
Duration? _noRetry(int retryCount, Object error) => null;

Future<T> _orThrow<T>(Future<Either<ServiceFailure, T>> call) async =>
    (await call).fold((f) => throw ServiceLoadException(f), (v) => v);

/// Approved banks.
final FutureProvider<List<BankSummary>> banksListProvider =
    FutureProvider.autoDispose<List<BankSummary>>(
      (ref) => _orThrow(ref.watch(banksRepositoryProvider).listBanks()),
      retry: _noRetry,
    );

/// Published products across banks, for comparing; null type for all.
final FutureProviderFamily<List<BankProduct>, BankProductType?>
bankProductsProvider = FutureProvider.autoDispose
    .family<List<BankProduct>, BankProductType?>(
      (ref, type) =>
          _orThrow(ref.watch(banksRepositoryProvider).listProducts(type: type)),
      retry: _noRetry,
    );

final FutureProviderFamily<BankDetail, String> bankDetailProvider =
    FutureProvider.autoDispose.family<BankDetail, String>(
      (ref, id) => _orThrow(ref.watch(banksRepositoryProvider).getBank(id)),
      retry: _noRetry,
    );

final FutureProviderFamily<BankProduct, String> bankProductProvider =
    FutureProvider.autoDispose.family<BankProduct, String>(
      (ref, id) => _orThrow(ref.watch(banksRepositoryProvider).getProduct(id)),
      retry: _noRetry,
    );

final FutureProviderFamily<List<BankBranch>, String> bankBranchesProvider =
    FutureProvider.autoDispose.family<List<BankBranch>, String>(
      (ref, bankId) =>
          _orThrow(ref.watch(banksRepositoryProvider).listBranches(bankId)),
      retry: _noRetry,
    );

final FutureProviderFamily<BranchAvailability, String>
branchAvailabilityProvider = FutureProvider.autoDispose
    .family<BranchAvailability, String>(
      (ref, branchId) => _orThrow(
        ref.watch(banksRepositoryProvider).getAvailability(branchId: branchId),
      ),
      retry: _noRetry,
    );

typedef EnquiryFormKey = ({
  String bankId,
  BankProductType productType,
  LeadKind kind,
});

final FutureProviderFamily<EnquiryForm, EnquiryFormKey> enquiryFormProvider =
    FutureProvider.autoDispose.family<EnquiryForm, EnquiryFormKey>(
      (ref, key) => _orThrow(
        ref
            .watch(banksRepositoryProvider)
            .getEnquiryForm(
              bankId: key.bankId,
              productType: key.productType,
              kind: key.kind,
            ),
      ),
      retry: _noRetry,
    );

/// The buyer's enquiries (appointment leads included), newest first.
final FutureProvider<List<BankLead>> myEnquiriesProvider =
    FutureProvider.autoDispose<List<BankLead>>(
      (ref) => _orThrow(ref.watch(banksRepositoryProvider).myEnquiries()),
      retry: _noRetry,
    );

final FutureProviderFamily<BankLead, String> myEnquiryProvider =
    FutureProvider.autoDispose.family<BankLead, String>(
      (ref, id) => _orThrow(ref.watch(banksRepositoryProvider).myEnquiry(id)),
      retry: _noRetry,
    );

/// The buyer's appointments, newest first.
final FutureProvider<List<BankAppointment>> myAppointmentsProvider =
    FutureProvider.autoDispose<List<BankAppointment>>(
      (ref) => _orThrow(ref.watch(banksRepositoryProvider).myAppointments()),
      retry: _noRetry,
    );

final FutureProviderFamily<BankAppointment, String> myAppointmentProvider =
    FutureProvider.autoDispose.family<BankAppointment, String>(
      (ref, id) =>
          _orThrow(ref.watch(banksRepositoryProvider).myAppointment(id)),
      retry: _noRetry,
    );
