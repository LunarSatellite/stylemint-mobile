import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/bookings_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';

/// The buyer side of the bookings contract v1.
///
/// No request carries an amount: a quote names a room or a departure and
/// who is coming, a payment names the booking and a rail, and the server
/// works out every figure. Writes take an explicit idempotency key from the
/// caller, so a retry after a timeout is the same request.
class BookingsRemoteDataSource {
  BookingsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static Options _idempotent(String key) =>
      Options(headers: {'requiresToken': true, 'Idempotency-Key': key});

  static String _e(String s) => Uri.encodeComponent(s);

  // ── Stays (public) ────────────────────────────────────────────────────

  Future<List<StaySearchItem>> searchStays(StaySearch search) async =>
      readStaySearchItems(
        await apiClient.get(
          '/v1/services/stays/search',
          queryParameters: <String, dynamic>{
            'q': search.location.trim(),
            'checkIn': searchWireDate(search.checkIn),
            'checkOut': searchWireDate(search.checkOut),
            'adults': search.guests,
            'children': 0,
            'rooms': search.rooms,
            'pageSize': 50,
          },
        ),
      );

  Future<StayDetail> getStay(String listingId, {StaySearch? search}) async =>
      readStayDetail(
        readJsonObject(
          await apiClient.get(
            '/v1/services/stays/${_e(listingId)}',
            queryParameters: search == null
                ? null
                : <String, dynamic>{
                    'checkIn': searchWireDate(search.checkIn),
                    'checkOut': searchWireDate(search.checkOut),
                    'adults': search.guests,
                    'children': 0,
                    'rooms': search.rooms,
                  },
          ),
        ),
      );

  Future<BookingQuote> quoteStay({
    required String listingId,
    required String roomTypeId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int rooms,
    required int adults,
    int children = 0,
  }) async => readBookingQuote(
    readJsonObject(
      await apiClient.post(
        '/v1/services/stays/${_e(listingId)}/quote',
        data: <String, dynamic>{
          'roomTypeId': roomTypeId,
          'checkIn': searchWireDate(checkIn),
          'checkOut': searchWireDate(checkOut),
          'rooms': rooms,
          'adults': adults,
          'children': children,
        },
      ),
    ),
  );

  // ── Packages (public) ─────────────────────────────────────────────────

  Future<List<PackageSearchItem>> searchPackages(TravelSearch search) async =>
      readPackageSearchItems(
        await apiClient.get(
          '/v1/services/packages/search',
          queryParameters: <String, dynamic>{
            if (search.destination.trim().isNotEmpty)
              'q': search.destination.trim(),
            'month': ?search.monthWire,
            'travellers': search.travellers,
            'pageSize': 50,
          },
        ),
      );

  Future<PackageDetail> getPackage(String listingId) async => readPackageDetail(
    readJsonObject(
      await apiClient.get('/v1/services/packages/${_e(listingId)}'),
    ),
  );

  Future<BookingQuote> quotePackage({
    required String listingId,
    required String departureId,
    required int adults,
    required int children,
  }) async => readBookingQuote(
    readJsonObject(
      await apiClient.post(
        '/v1/services/packages/${_e(listingId)}/quote',
        data: <String, dynamic>{
          'departureId': departureId,
          'adults': adults,
          'children': children,
        },
      ),
    ),
  );

  // ── Buyer bookings ────────────────────────────────────────────────────

  Future<Booking> createBooking({
    required BookingQuote quote,
    required PaymentMode paymentMode,
    required String guestName,
    required List<Traveller> travellers,
    required String idempotencyKey,
    String? specialRequests,
  }) async => readBooking(
    readJsonObject(
      await apiClient.post(
        '/v1/bookings/me',
        data: <String, dynamic>{
          'listingId': quote.listingId,
          if (quote.kind == ListingKind.stay) ...<String, dynamic>{
            'roomTypeId': quote.roomTypeId,
            'checkIn': searchWireDate(quote.startDate),
            'checkOut': searchWireDate(quote.endDate ?? quote.startDate),
            'rooms': quote.rooms ?? 1,
          } else
            'departureId': quote.departureId,
          'adults': quote.adults,
          'children': quote.children,
          'paymentMode': paymentMode.wire,
          'guestName': guestName.trim(),
          if (quote.kind == ListingKind.package)
            'travellers': [
              for (final t in travellers)
                <String, dynamic>{
                  'fullName': t.fullName.trim(),
                  'type': t.type.wire,
                  'age': t.age,
                },
            ],
          if (specialRequests != null && specialRequests.trim().isNotEmpty)
            'specialRequests': specialRequests.trim(),
        },
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<BookingPaymentStart> pay({
    required String bookingId,
    required BookingPaymentRail rail,
    required String idempotencyKey,
  }) async => readBookingPaymentStart(
    readJsonObject(
      await apiClient.post(
        '/v1/bookings/me/${_e(bookingId)}/pay',
        data: <String, dynamic>{'method': rail.wire},
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<List<Booking>> myBookings() async => readBookings(
    await apiClient.get(
      '/v1/bookings/me',
      queryParameters: const <String, dynamic>{'pageSize': 50},
    ),
  );

  Future<Booking> myBooking(String bookingId) async => readBooking(
    readJsonObject(await apiClient.get('/v1/bookings/me/${_e(bookingId)}')),
  );

  Future<CancellationQuote> cancellationQuote(String bookingId) async =>
      readCancellationQuote(
        readJsonObject(
          await apiClient.get(
            '/v1/bookings/me/${_e(bookingId)}/cancellation-quote',
          ),
        ),
      );

  Future<Booking> cancel({
    required String bookingId,
    required String idempotencyKey,
    String? reason,
  }) async => readBooking(
    readJsonObject(
      await apiClient.post(
        '/v1/bookings/me/${_e(bookingId)}/cancel',
        data: <String, dynamic>{
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
        options: _idempotent(idempotencyKey),
      ),
    ),
  );
}
