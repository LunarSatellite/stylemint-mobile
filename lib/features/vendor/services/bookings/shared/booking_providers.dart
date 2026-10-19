import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/vendor_bookings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/vendor_bookings_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';

final Provider<VendorBookingsRepository> vendorBookingsRepositoryProvider =
    Provider<VendorBookingsRepository>(
      (ref) => VendorBookingsRepositoryImpl(
        VendorBookingsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
      ),
    );

// No automatic retry anywhere below: a 404 has to read as "being set up" at
// once, not as loading-with-error while Riverpod retries.

/// Counts for the dashboard card (`v1/vendor/bookings/summary`).
final FutureProvider<BookingsSummary> vendorBookingsSummaryProvider =
    FutureProvider.autoDispose<BookingsSummary>((ref) async {
      final result = await ref
          .watch(vendorBookingsRepositoryProvider)
          .getSummary();
      return result.fold((f) => throw ServiceLoadException(f), (s) => s);
    }, retry: (_, _) => null);

/// Today's arrivals, departures (check-outs) and guests in house.
final FutureProvider<BookingsTodayBoard> vendorBookingsTodayProvider =
    FutureProvider.autoDispose<BookingsTodayBoard>((ref) async {
      final result = await ref
          .watch(vendorBookingsRepositoryProvider)
          .getToday(ref.watch(serviceTodayProvider));
      return result.fold((f) => throw ServiceLoadException(f), (b) => b);
    }, retry: (_, _) => null);

/// Live bookings starting in the next 30 days.
final FutureProvider<List<ServiceBooking>> vendorBookingsUpcomingProvider =
    FutureProvider.autoDispose<List<ServiceBooking>>((ref) async {
      final result = await ref
          .watch(vendorBookingsRepositoryProvider)
          .getUpcoming(ref.watch(serviceTodayProvider));
      return result.fold((f) => throw ServiceLoadException(f), (b) => b);
    }, retry: (_, _) => null);

/// One booking, by id.
final FutureProviderFamily<ServiceBooking, String> vendorBookingProvider =
    FutureProvider.autoDispose.family<ServiceBooking, String>((
      ref,
      bookingId,
    ) async {
      final result = await ref
          .watch(vendorBookingsRepositoryProvider)
          .getBooking(bookingId);
      return result.fold((f) => throw ServiceLoadException(f), (b) => b);
    }, retry: (_, _) => null);

/// The vendor's listings of one kind (not archived).
final FutureProviderFamily<List<VendorListing>, ServiceListingKind>
vendorListingsProvider = FutureProvider.autoDispose
    .family<List<VendorListing>, ServiceListingKind>((ref, kind) async {
      final result = await ref
          .watch(vendorBookingsRepositoryProvider)
          .listListings(kind);
      return result.fold((f) => throw ServiceLoadException(f), (l) => l);
    }, retry: (_, _) => null);

/// The next 14 nights of one room type, from today.
final FutureProviderFamily<List<RoomNight>, String> roomTypeNightsProvider =
    FutureProvider.autoDispose.family<List<RoomNight>, String>((
      ref,
      roomTypeId,
    ) async {
      final today = ref.watch(serviceTodayProvider);
      final result = await ref
          .watch(vendorBookingsRepositoryProvider)
          .getCalendar(
            roomTypeId,
            from: today,
            // Calendar arithmetic, not Duration: `today` is a local midnight,
            // and adding 13 x 24h across a DST change lands an hour short —
            // 2026-10-21 + Duration(days: 13) is 2026-11-02 23:00 in a zone
            // whose clocks go back on 1 November, so the window loses its last
            // night. DateTime normalises an overflowing day, so this is a
            // calendar day either way.
            to: DateTime(today.year, today.month, today.day + 13),
          );
      return result.fold((f) => throw ServiceLoadException(f), (n) => n);
    }, retry: (_, _) => null);

/// A package's departures from today, ascending.
final FutureProviderFamily<List<VendorDeparture>, String>
listingDeparturesProvider = FutureProvider.autoDispose
    .family<List<VendorDeparture>, String>((ref, listingId) async {
      final result = await ref
          .watch(vendorBookingsRepositoryProvider)
          .listDepartures(listingId, from: ref.watch(serviceTodayProvider));
      return result.fold((f) => throw ServiceLoadException(f), (d) => d);
    }, retry: (_, _) => null);
