import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/shared/providers.dart'
    show checkoutRemoteDataSourceProvider;
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/datasources/credit_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/datasources/emi_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/repositories/credit_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/repositories/emi_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/repositories/credit_repository.dart';
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

// ── Payment plans (the Credit module) ───────────────────────────────────────

final creditRemoteDataSourceProvider = Provider<CreditRemoteDataSource>(
  (ref) => CreditRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final creditRepositoryProvider = Provider<CreditRepository>(
  (ref) => CreditRepositoryImpl(
    remote: ref.watch(creditRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
    checkout: ref.watch(checkoutRemoteDataSourceProvider),
  ),
);

Future<T> _orThrow<T>(Future<Either<EmiFailure, T>> call) async =>
    (await call).fold((failure) => throw EmiLoadException(failure), (v) => v);

/// The plans a variant can be bought on, for the product page. Not personal.
final FutureProviderFamily<PlanOptions, String> planOptionsProvider =
    FutureProvider.autoDispose.family<PlanOptions, String>(
      (ref, variantId) => _orThrow(
        ref.watch(creditRepositoryProvider).getPlanOptions(variantId),
      ),
    );

/// The signed-in buyer's standing: band, limit, and what moved the score.
final FutureProvider<CreditProfile> creditProfileProvider =
    FutureProvider.autoDispose<CreditProfile>(
      (ref) => _orThrow(ref.watch(creditRepositoryProvider).getProfile()),
    );

/// The signed-in buyer's payment plans.
final FutureProvider<List<CreditAgreement>> myPaymentPlansProvider =
    FutureProvider.autoDispose<List<CreditAgreement>>(
      (ref) => _orThrow(ref.watch(creditRepositoryProvider).listAgreements()),
    );

final FutureProviderFamily<CreditAgreement, String> paymentPlanProvider =
    FutureProvider.autoDispose.family<CreditAgreement, String>(
      (ref, id) =>
          _orThrow(ref.watch(creditRepositoryProvider).getAgreement(id)),
    );

/// A vendor's plans; null status means all of them.
final FutureProviderFamily<List<CreditAgreement>, AgreementStatus?>
vendorPaymentPlansProvider = FutureProvider.autoDispose
    .family<List<CreditAgreement>, AgreementStatus?>(
      (ref, status) => _orThrow(
        ref.watch(creditRepositoryProvider).vendorAgreements(status: status),
      ),
    );

final FutureProviderFamily<CreditAgreement, String> vendorPaymentPlanProvider =
    FutureProvider.autoDispose.family<CreditAgreement, String>(
      (ref, id) =>
          _orThrow(ref.watch(creditRepositoryProvider).vendorAgreement(id)),
    );

final FutureProvider<VendorCreditProgram> vendorCreditProgramProvider =
    FutureProvider.autoDispose<VendorCreditProgram>(
      (ref) => _orThrow(ref.watch(creditRepositoryProvider).vendorProgram()),
    );

/// After any change to a buyer's plans, everything that shows them refreshes.
void refreshPaymentPlans(WidgetRef ref, {String? agreementId}) {
  ref
    ..invalidate(myPaymentPlansProvider)
    ..invalidate(creditProfileProvider);
  if (agreementId != null) ref.invalidate(paymentPlanProvider(agreementId));
}

/// The name of the item a plan is for. Agreements carry ids, not names (the
/// catalogue owns those), so the name is read from the product page's own
/// source. Null when it cannot be read; the plan is shown without it.
final FutureProviderFamily<String?, String> planProductNameProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, productId) async {
      if (productId.isEmpty) return null;
      final result = await ref
          .watch(discoveryRepositoryProvider)
          .getProductDetail(productId);
      return result.fold((_) => null, (product) {
        final name = product.name.trim();
        return name.isEmpty ? null : name;
      });
    });
