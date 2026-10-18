import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/booking_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_page.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';

/// The vendor side of the service-bookings contract v1 (§4, "Vendor"):
/// bookings and their lifecycle actions, and the availability quick view
/// (room-type calendars, departures). Every route 404s until the deploy.
class VendorBookingsRemoteDataSource {
  VendorBookingsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static String _id(String id) => Uri.encodeComponent(id);

  Options _write(String idempotencyKey) => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );

  Future<BookingsSummary> getSummary() async => readBookingsSummary(
    readJsonObject(await apiClient.get('/v1/vendor/bookings/summary')),
  );

  /// [from]/[to] filter on the start date (Kathmandu calendar dates).
  Future<ServicePage<ServiceBooking>> listBookings({
    int? state,
    DateTime? from,
    DateTime? to,
    String? query,
    String? cursor,
    int pageSize = 50,
  }) async => readServicePage(
    await apiClient.get(
      '/v1/vendor/bookings',
      queryParameters: <String, dynamic>{
        'state': ?state,
        if (from != null) 'from': wireDate(from),
        if (to != null) 'to': wireDate(to),
        if (query != null && query.isNotEmpty) 'q': query,
        'cursor': ?cursor,
        'pageSize': pageSize,
      },
    ),
    readServiceBooking,
  );

  Future<ServiceBooking> getBooking(String bookingId) async =>
      readServiceBooking(
        readJsonObject(
          await apiClient.get('/v1/vendor/bookings/${_id(bookingId)}'),
        ),
      );

  /// `check-in`, `complete`, `no-show`, `balance-received` or `cancel`.
  Future<ServiceBooking> bookingAction(
    String bookingId,
    String action, {
    required String idempotencyKey,
    Map<String, dynamic>? data,
  }) async => readServiceBooking(
    readJsonObject(
      await apiClient.post(
        '/v1/vendor/bookings/${_id(bookingId)}/$action',
        data: data,
        options: _write(idempotencyKey),
      ),
    ),
  );

  Future<List<VendorListing>> listListings({int? kind}) async =>
      readServiceList(
        await apiClient.get(
          '/v1/vendor/services/listings',
          queryParameters: <String, dynamic>{'kind': ?kind},
        ),
        readVendorListing,
      );

  Future<List<RoomNight>> getCalendar(
    String roomTypeId, {
    required DateTime from,
    required DateTime to,
  }) async => readServiceList(
    await apiClient.get(
      '/v1/vendor/services/room-types/${_id(roomTypeId)}/calendar',
      queryParameters: <String, dynamic>{
        'from': wireDate(from),
        'to': wireDate(to),
      },
    ),
    readRoomNight,
  );

  /// Stop-sell ([closed] true) or reopen one or more nights.
  Future<List<RoomNight>> setNightsClosed(
    String roomTypeId, {
    required DateTime from,
    required DateTime to,
    required bool closed,
    required String idempotencyKey,
  }) async => readServiceList(
    await apiClient.put(
      '/v1/vendor/services/room-types/${_id(roomTypeId)}/calendar',
      data: <String, dynamic>{
        'from': wireDate(from),
        'to': wireDate(to),
        'price': null,
        'clearPrice': false,
        'closed': closed,
      },
      options: _write(idempotencyKey),
    ),
    readRoomNight,
  );

  Future<List<VendorDeparture>> listDepartures(
    String listingId, {
    required DateTime from,
  }) async => readServiceList(
    await apiClient.get(
      '/v1/vendor/services/listings/${_id(listingId)}/departures',
      queryParameters: <String, dynamic>{'from': wireDate(from)},
    ),
    readVendorDeparture,
  );

  /// `close` or `reopen`.
  Future<VendorDeparture> departureAction(
    String departureId,
    String action, {
    required String idempotencyKey,
  }) async => readVendorDeparture(
    readJsonObject(
      await apiClient.post(
        '/v1/vendor/services/departures/${_id(departureId)}/$action',
        options: _write(idempotencyKey),
      ),
    ),
  );
}
