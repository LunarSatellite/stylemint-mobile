import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/datasources/bookings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/service_failure_mapper.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/repositories/bookings_repository.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  BookingsRepositoryImpl({required this.remote, required this.networkInfo});

  final BookingsRemoteDataSource remote;
  final NetworkInfoConnectivity networkInfo;

  Future<Either<ServiceFailure, T>> _call<T>(Future<T> Function() call) =>
      guardedServiceCall(networkInfo, call);

  @override
  Future<Either<ServiceFailure, List<StaySearchItem>>> searchStays(
    StaySearch search,
  ) => _call(() => remote.searchStays(search));

  @override
  Future<Either<ServiceFailure, StayDetail>> getStay(
    String listingId, {
    StaySearch? search,
  }) => _call(() => remote.getStay(listingId, search: search));

  @override
  Future<Either<ServiceFailure, BookingQuote>> quoteStay({
    required String listingId,
    required String roomTypeId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int rooms,
    required int adults,
    int children = 0,
  }) => _call(
    () => remote.quoteStay(
      listingId: listingId,
      roomTypeId: roomTypeId,
      checkIn: checkIn,
      checkOut: checkOut,
      rooms: rooms,
      adults: adults,
      children: children,
    ),
  );

  @override
  Future<Either<ServiceFailure, List<PackageSearchItem>>> searchPackages(
    TravelSearch search,
  ) => _call(() => remote.searchPackages(search));

  @override
  Future<Either<ServiceFailure, PackageDetail>> getPackage(String listingId) =>
      _call(() => remote.getPackage(listingId));

  @override
  Future<Either<ServiceFailure, BookingQuote>> quotePackage({
    required String listingId,
    required String departureId,
    required int adults,
    required int children,
  }) => _call(
    () => remote.quotePackage(
      listingId: listingId,
      departureId: departureId,
      adults: adults,
      children: children,
    ),
  );

  @override
  Future<Either<ServiceFailure, Booking>> createBooking({
    required BookingQuote quote,
    required PaymentMode paymentMode,
    required String guestName,
    required List<Traveller> travellers,
    required String idempotencyKey,
    String? specialRequests,
  }) => _call(
    () => remote.createBooking(
      quote: quote,
      paymentMode: paymentMode,
      guestName: guestName,
      travellers: travellers,
      idempotencyKey: idempotencyKey,
      specialRequests: specialRequests,
    ),
  );

  @override
  Future<Either<ServiceFailure, BookingPaymentStart>> pay({
    required String bookingId,
    required BookingPaymentRail rail,
    required String idempotencyKey,
  }) => _call(
    () => remote.pay(
      bookingId: bookingId,
      rail: rail,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Either<ServiceFailure, List<Booking>>> myBookings() =>
      _call(remote.myBookings);

  @override
  Future<Either<ServiceFailure, Booking>> myBooking(String bookingId) =>
      _call(() => remote.myBooking(bookingId));

  @override
  Future<Either<ServiceFailure, CancellationQuote>> cancellationQuote(
    String bookingId,
  ) => _call(() => remote.cancellationQuote(bookingId));

  @override
  Future<Either<ServiceFailure, Booking>> cancel({
    required String bookingId,
    required String idempotencyKey,
    String? reason,
  }) => _call(
    () => remote.cancel(
      bookingId: bookingId,
      idempotencyKey: idempotencyKey,
      reason: reason,
    ),
  );
}
