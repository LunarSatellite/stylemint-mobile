import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';

/// Stays, travel packages and the buyer's bookings (bookings contract v1).
abstract interface class BookingsRepository {
  Future<Either<ServiceFailure, List<StaySearchItem>>> searchStays(
    StaySearch search,
  );

  Future<Either<ServiceFailure, StayDetail>> getStay(
    String listingId, {
    StaySearch? search,
  });

  Future<Either<ServiceFailure, BookingQuote>> quoteStay({
    required String listingId,
    required String roomTypeId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int rooms,
    required int adults,
    int children = 0,
  });

  Future<Either<ServiceFailure, List<PackageSearchItem>>> searchPackages(
    TravelSearch search,
  );

  Future<Either<ServiceFailure, PackageDetail>> getPackage(String listingId);

  Future<Either<ServiceFailure, BookingQuote>> quotePackage({
    required String listingId,
    required String departureId,
    required int adults,
    required int children,
  });

  Future<Either<ServiceFailure, Booking>> createBooking({
    required BookingQuote quote,
    required PaymentMode paymentMode,
    required String guestName,
    required List<Traveller> travellers,
    required String idempotencyKey,
    String? specialRequests,
  });

  Future<Either<ServiceFailure, BookingPaymentStart>> pay({
    required String bookingId,
    required BookingPaymentRail rail,
    required String idempotencyKey,
  });

  Future<Either<ServiceFailure, List<Booking>>> myBookings();

  Future<Either<ServiceFailure, Booking>> myBooking(String bookingId);

  Future<Either<ServiceFailure, CancellationQuote>> cancellationQuote(
    String bookingId,
  );

  Future<Either<ServiceFailure, Booking>> cancel({
    required String bookingId,
    required String idempotencyKey,
    String? reason,
  });
}
