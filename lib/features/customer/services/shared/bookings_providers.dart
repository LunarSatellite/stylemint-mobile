import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/datasources/bookings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/repositories/bookings_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/repositories/bookings_repository.dart';
import 'package:url_launcher/url_launcher.dart';

final bookingsRemoteDataSourceProvider = Provider<BookingsRemoteDataSource>(
  (ref) => BookingsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final bookingsRepositoryProvider = Provider<BookingsRepository>(
  (ref) => BookingsRepositoryImpl(
    remote: ref.watch(bookingsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// No automatic retry: Riverpod 3 would keep a failed load "loading" while it
/// retries, and a 404 has to read as "Services are coming soon" at once.
Duration? _noRetry(int retryCount, Object error) => null;

Future<T> _orThrow<T>(Future<Either<ServiceFailure, T>> call) async =>
    (await call).fold((f) => throw ServiceLoadException(f), (v) => v);

/// A stay, priced for the buyer's dates when [StayKey.search] is set.
typedef StayKey = ({String listingId, StaySearch? search});

final FutureProviderFamily<StayDetail, StayKey> stayDetailProvider =
    FutureProvider.autoDispose.family<StayDetail, StayKey>(
      (ref, key) => _orThrow(
        ref
            .watch(bookingsRepositoryProvider)
            .getStay(key.listingId, search: key.search),
      ),
      retry: _noRetry,
    );

final FutureProviderFamily<PackageDetail, String> packageDetailProvider =
    FutureProvider.autoDispose.family<PackageDetail, String>(
      (ref, id) =>
          _orThrow(ref.watch(bookingsRepositoryProvider).getPackage(id)),
      retry: _noRetry,
    );

/// The buyer's bookings, newest first.
final FutureProvider<List<Booking>> myBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>(
      (ref) => _orThrow(ref.watch(bookingsRepositoryProvider).myBookings()),
      retry: _noRetry,
    );

final FutureProviderFamily<Booking, String> myBookingProvider =
    FutureProvider.autoDispose.family<Booking, String>(
      (ref, id) => _orThrow(ref.watch(bookingsRepositoryProvider).myBooking(id)),
      retry: _noRetry,
    );

/// After any change to a booking, everything that shows it refreshes.
void refreshBookings(WidgetRef ref, {String? bookingId}) {
  ref.invalidate(myBookingsProvider);
  if (bookingId != null) ref.invalidate(myBookingProvider(bookingId));
}

/// Opens the payment provider's page in the in-app browser — the way
/// checkout and EMI hand off to eSewa, card and PayPal. A provider so a test
/// can stand in for the browser and see which page was opened.
final Provider<Future<void> Function(Uri)> servicePaymentLauncherProvider =
    Provider<Future<void> Function(Uri)>(
      (ref) => (uri) async {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } on Object {
          // No browser, or a malformed address: the booking exists and shows
          // its real state, so carry on rather than fail.
        }
      },
    );
