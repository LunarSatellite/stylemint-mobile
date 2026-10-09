import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/datasources/emi_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/repositories/emi_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/repositories/emi_repository.dart';

final emiRemoteDataSourceProvider = Provider<EmiRemoteDataSource>(
  (ref) => EmiRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final emiRepositoryProvider = Provider<EmiRepository>(
  (ref) => EmiRepositoryImpl(
    remoteDataSource: ref.watch(emiRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// Whether a buyer is signed in, for the calculator's button. Its own provider
/// so a widget test can say "signed out" without building the whole session.
final emiSignedInProvider = Provider<bool>(
  (ref) => ref.watch(sessionControllerProvider).isAuthenticated,
);

/// Carries an [EmiFailure] out of a FutureProvider, which must throw an
/// Exception to report failure.
class EmiLoadException implements Exception {
  const EmiLoadException(this.failure);

  final EmiFailure failure;

  @override
  String toString() => 'EmiLoadException($failure)';
}

/// The signed-in buyer's EMI eligibility. Invalidated when a `kyc.decided`
/// push arrives and when the KYC flow submits, so the calculator's button
/// follows the review without a restart.
final FutureProvider<EmiEligibility> emiEligibilityProvider =
    FutureProvider.autoDispose<EmiEligibility>((ref) async {
      final result = await ref.watch(emiRepositoryProvider).getEligibility();
      return result.fold(
        (failure) => throw EmiLoadException(failure),
        (eligibility) => eligibility,
      );
    });
