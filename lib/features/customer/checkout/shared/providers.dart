import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/notifiers/checkout_notifier.dart';
import 'package:url_launcher/url_launcher.dart';

final checkoutRemoteDataSourceProvider = Provider<CheckoutRemoteDataSource>(
  (ref) => CheckoutRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (ref) => CheckoutRepositoryImpl(
    remoteDataSource: ref.watch(checkoutRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
    cartRepository: ref.watch(cartRepositoryProvider),
  ),
);

final checkoutNotifierProvider =
    StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>(
      (ref) => CheckoutNotifier(ref.watch(checkoutRepositoryProvider)),
    );

/// Opens an online payment's provider page (eSewa, card, PayPal) in the
/// in-app browser. A provider so a test can stand in for the browser and see
/// which page was opened. Never throws: with no browser, or a malformed
/// address, checkout carries on to the screen that follows the payment.
final Provider<Future<void> Function(Uri)> checkoutPaymentLauncherProvider =
    Provider<Future<void> Function(Uri)>(
      (ref) => (uri) async {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } on Object {
          // See above: the screen after this keeps the real state.
        }
      },
    );
