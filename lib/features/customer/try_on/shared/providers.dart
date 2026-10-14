import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/data/datasources/try_on_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/data/repositories/try_on_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/repositories/try_on_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/fit_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/try_on_access_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/try_on_paywall_notifier.dart';
import 'package:url_launcher/url_launcher.dart';

final tryOnRemoteDataSourceProvider = Provider<TryOnRemoteDataSource>(
  (ref) => TryOnRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final tryOnRepositoryProvider = Provider<TryOnRepository>(
  (ref) => TryOnRepositoryImpl(
    remote: ref.watch(tryOnRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// The signed-in account, or null. Access is per account: watching this
/// throws the cached access away on sign-out / account switch.
final tryOnAccountKeyProvider = Provider<String?>(
  (ref) => ref
      .watch(sessionControllerProvider)
      .maybeWhen(authenticated: (id) => id, orElse: () => null),
);

/// Shared by the product page, the paywall and "My try-on plan".
final tryOnAccessNotifierProvider =
    StateNotifierProvider<TryOnAccessNotifier, TryOnAccessState>((ref) {
      ref.watch(tryOnAccountKeyProvider);
      return TryOnAccessNotifier(ref.watch(tryOnRepositoryProvider));
    });

final tryOnPaywallNotifierProvider =
    StateNotifierProvider.autoDispose<TryOnPaywallNotifier, TryOnPaywallState>(
      (ref) => TryOnPaywallNotifier(
        ref.watch(tryOnRepositoryProvider),
        ref.read(tryOnAccessNotifierProvider.notifier),
      ),
    );

final fitNotifierProvider = StateNotifierProvider.autoDispose
    .family<FitNotifier, FitState, String>(
      (ref, productId) =>
          FitNotifier(ref.watch(tryOnRepositoryProvider), productId),
    );

/// Carries a [TryOnFailure] out of a FutureProvider.
class TryOnLoadException implements Exception {
  const TryOnLoadException(this.failure);

  final TryOnFailure failure;

  @override
  String toString() => 'TryOnLoadException($failure)';
}

Future<T> _orThrow<T>(Future<Either<TryOnFailure, T>> call) async =>
    (await call).fold((f) => throw TryOnLoadException(f), (v) => v);

/// The overlay + chart for one product (needs access).
final FutureProviderFamily<TryOnProduct, String> tryOnProductProvider =
    FutureProvider.autoDispose.family<TryOnProduct, String>(
      (ref, productId) =>
          _orThrow(ref.watch(tryOnRepositoryProvider).getProduct(productId)),
    );

/// Public size chart — decides whether the product is "try-on ready"
/// enough to show the entry point, and costs no premium call. Null when the
/// vendor published none.
final FutureProviderFamily<SizeChart?, String> publicSizeChartProvider =
    FutureProvider.autoDispose.family<SizeChart?, String>(
      (ref, productId) => _orThrow(
        ref.watch(tryOnRepositoryProvider).getPublicSizeChart(productId),
      ),
    );

final FutureProvider<List<MyTryOnSubscription>> myTryOnSubscriptionsProvider =
    FutureProvider.autoDispose<List<MyTryOnSubscription>>(
      (ref) => _orThrow(ref.watch(tryOnRepositoryProvider).mySubscriptions()),
    );

/// Opens the payment provider's page in the in-app browser — the same
/// hand-off checkout and payment plans use. A provider so tests can stand
/// in for the browser.
final Provider<Future<void> Function(Uri)> tryOnPaymentLauncherProvider =
    Provider<Future<void> Function(Uri)>(
      (ref) => (uri) async {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } on Object {
          // No browser / malformed URL: the subscription exists and the
          // confirm button stays available.
        }
      },
    );
