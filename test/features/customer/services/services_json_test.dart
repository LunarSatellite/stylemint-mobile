import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/banks_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/bookings_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/service_failure_mapper.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';

/// Payloads exactly as the bookings and banks contracts (v1) show them.
void main() {
  group('bookings contract v1', () {
    test('a stay detail with room types and nightly prices', () {
      final stay = readStayDetail({
        'listingId': 'L1',
        'kind': 1,
        'status': 2,
        'title': 'Hotel Yak & Yeti',
        'vendor': {'vendorAccountId': 'V1', 'name': 'Yak & Yeti', 'logoUrl': null},
        'city': 'Kathmandu',
        'area': 'Durbar Marg',
        'latitude': 27.711,
        'longitude': 85.318,
        'photoUrls': ['https://img/1.jpg'],
        'amenities': ['wifi'],
        'starRating': 5,
        'checkInTime': '14:00',
        'checkOutTime': '12:00',
        'minNights': 1,
        'maxNights': 30,
        'cancellationPolicy': {
          'freeCancellationDays': 3,
          'lateCancellationFeePercent': 50,
          'summary': 'Free cancellation until 3 days before.',
        },
        'paymentModes': [1, 2, 3],
        'depositPercent': 30,
        'currency': 'NPR',
        'fromPricePerNight': 4500,
        'roomTypes': [
          {
            'roomTypeId': 'R1',
            'name': 'Deluxe Double',
            'maxAdults': 2,
            'maxGuests': 3,
            'beds': '1 King',
            'baseRate': 4500,
            'availableUnits': 3,
            'totalPrice': 9000,
            'nightly': [
              {'date': '2026-10-21', 'price': 4500, 'available': 3},
            ],
          },
          {'name': 'No id — skipped'},
        ],
      });
      expect(stay.paymentModes, PaymentMode.values);
      expect(stay.place, 'Durbar Marg, Kathmandu');
      expect(stay.roomTypes, hasLength(1));
      final room = stay.roomTypes.single;
      expect(room.totalPrice!.amount, 9000);
      expect(room.nightly.single.date, DateTime(2026, 10, 21));
      expect(room.fits(guests: 4, rooms: 1), isFalse);
      expect(room.fits(guests: 4, rooms: 2), isTrue);
      expect(stay.cancellationPolicy.describe(), contains('3 days'));
    });

    test('a quote with payment options', () {
      final q = readBookingQuote({
        'listingId': 'L1',
        'kind': 1,
        'roomTypeId': 'R1',
        'startDate': '2026-10-21',
        'endDate': '2026-10-23',
        'nights': 2,
        'rooms': 1,
        'adults': 2,
        'children': 0,
        'currency': 'NPR',
        'lines': [
          {
            'label': 'Deluxe Double · 21 Oct',
            'date': '2026-10-21',
            'quantity': 1,
            'unitPrice': 4500,
            'amount': 4500,
          },
        ],
        'totalPrice': 9000,
        'available': true,
        'unavailableReason': null,
        'paymentOptions': [
          {'mode': 2, 'payNow': 2700, 'payAtVenue': 6300},
          {'mode': 9, 'payNow': 1, 'payAtVenue': 1},
        ],
        'cancellationPolicy': {
          'freeCancellationDays': 3,
          'lateCancellationFeePercent': 50,
          'freeUntilDate': '2026-10-18',
        },
        'holdMinutes': 15,
      });
      expect(q.kind, ListingKind.stay);
      expect(q.startDate, DateTime(2026, 10, 21));
      expect(q.paymentOptions, hasLength(1), reason: 'unknown mode dropped');
      expect(q.optionFor(PaymentMode.deposit)!.payAtVenue.amount, 6300);
      expect(q.cancellationPolicy.freeUntilDate, DateTime(2026, 10, 18));
    });

    test('a quote without a kind is refused, not guessed', () {
      expect(
        () => readBookingQuote({'startDate': '2026-10-21'}),
        throwsFormatException,
      );
    });

    test('a buyer booking', () {
      final b = readBooking({
        'id': 'B1',
        'number': 'BK-7F3A9C21',
        'kind': 1,
        'state': 2,
        'listingId': 'L1',
        'listingTitle': 'Hotel Yak & Yeti',
        'roomTypeName': 'Deluxe Double',
        'startDate': '2026-10-21',
        'endDate': '2026-10-23',
        'nights': 2,
        'rooms': 1,
        'adults': 2,
        'children': 1,
        'guestName': 'Sita Sharma',
        'travellers': [
          {'fullName': 'Sita Sharma', 'type': 1, 'age': null},
        ],
        'currency': 'NPR',
        'totalPrice': 9000,
        'paymentMode': 2,
        'depositPercent': 30,
        'payNowAmount': 2700,
        'paidOnline': 2700,
        'balanceDue': 6300,
        'cancellationPolicy': {
          'freeCancellationDays': 3,
          'lateCancellationFeePercent': 50,
        },
        'cancelledBy': null,
        'refundState': 0,
        'commissionPercent': 10,
        'canPay': false,
        'canCancel': true,
      });
      expect(b.state, BookingState.confirmed);
      expect(b.paymentMode, PaymentMode.deposit);
      expect(b.balanceDue.amount, 6300);
      expect(b.guests, 3);
      expect(b.canCancel, isTrue);
      expect(b.isUpcoming(DateTime(2026, 10, 23)), isTrue);
      expect(b.isUpcoming(DateTime(2026, 10, 24)), isFalse);
    });

    test('a package with departures in date order', () {
      final p = readPackageDetail({
        'listingId': 'P1',
        'kind': 2,
        'title': 'ABC 7D',
        'durationDays': 7,
        'durationNights': 6,
        'itinerary': [
          {'day': 2, 'title': 'Two'},
          {'day': 1, 'title': 'One'},
        ],
        'inclusions': ['Guide'],
        'exclusions': ['Flights'],
        'cancellationPolicy': {
          'freeCancellationDays': 0,
          'lateCancellationFeePercent': 0,
        },
        'paymentModes': [1],
        'departures': [
          {
            'departureId': 'D2',
            'date': '2026-11-16',
            'seatsAvailable': 0,
            'adultPrice': 45000,
            'status': 2,
          },
          {
            'departureId': 'D1',
            'date': '2026-11-02',
            'endDate': '2026-11-08',
            'seatsTotal': 12,
            'seatsAvailable': 5,
            'adultPrice': 45000,
            'childPrice': null,
            'status': 1,
          },
        ],
      });
      expect([for (final d in p.itinerary) d.day], [1, 2]);
      expect([for (final d in p.departures) d.id], ['D1', 'D2']);
      expect(p.departures.first.bookable, isTrue);
      expect(p.departures.first.childPrice, isNull);
      expect(p.departures.last.bookable, isFalse);
      expect(p.durationLabel, '7 days · 6 nights');
    });

    test('payment initiation and cancellation quote', () {
      final pay = readBookingPaymentStart({
        'bookingId': 'B1',
        'paymentId': 'X',
        'amount': 2700,
        'currency': 'NPR',
        'payment': {
          'intentId': 'I',
          'method': 3,
          'handoffKind': 2,
          'redirectUrl': 'https://esewa/pay',
        },
      });
      expect(pay.redirectUrl, 'https://esewa/pay');
      final c = readCancellationQuote({
        'bookingId': 'B1',
        'cancellable': true,
        'reason': null,
        'fee': 0,
        'refundAmount': 2700,
        'freeUntilDate': '2026-10-18',
        'currency': 'NPR',
      });
      expect(c.refundAmount.amount, 2700);
      expect(c.freeUntilDate, DateTime(2026, 10, 18));
    });
  });

  group('banks contract v1', () {
    test('a bank product and its rate label', () {
      final p = readBankProduct({
        'id': 'P1',
        'bankId': 'B1',
        'bankName': 'Himalayan Bank',
        'type': 4,
        'name': 'Home Loan',
        'interestRateMinPercent': 9.5,
        'interestRateMaxPercent': 11.25,
        'documentsRequired': ['Citizenship', ' ', 'Salary certificate'],
        'minAmount': 500000,
        'currency': 'NPR',
      });
      expect(p.type, BankProductType.loan);
      expect(p.rateLabel, '9.5% – 11.25% p.a.');
      expect(p.documentsRequired, ['Citizenship', 'Salary certificate']);
      expect(p.minAmount!.amount, 500000);
    });

    test('availability keeps closed days, slots with their status', () {
      final a = readBranchAvailability({
        'branchId': 'BR',
        'from': '2026-10-20',
        'days': [
          {
            'date': '2026-10-20',
            'closed': false,
            'slots': [
              {
                'slotId': 'S1',
                'startTime': '10:00',
                'endTime': '10:30',
                'startUtc': '2026-10-20T04:15:00+00:00',
                'capacity': 4,
                'remaining': 0,
                'status': 2,
              },
            ],
          },
          {
            'date': '2026-10-24',
            'closed': true,
            'closedReason': 'Holiday: Dashain',
            'slots': [],
          },
        ],
      });
      expect(a.days, hasLength(2));
      expect(a.days.first.slots.single.status, SlotAvailability.full);
      expect(a.days.first.hasBookable, isFalse);
      expect(a.days.last.closedReason, 'Holiday: Dashain');
    });

    test('an enquiry form without consent wording is refused', () {
      expect(
        () => readEnquiryForm({'bankId': 'B1', 'fields': <Object>[]}),
        throwsFormatException,
      );
      final form = readEnquiryForm({
        'bankId': 'B1',
        'bankName': 'Himalayan Bank',
        'productType': 4,
        'fields': [
          {
            'key': 'loanAmount',
            'label': 'Loan amount (NPR)',
            'type': 3,
            'required': true,
            'options': null,
            'min': 10000,
          },
          {
            'key': 'loanPurpose',
            'label': 'Purpose',
            'type': 4,
            'options': ['Home', 'Vehicle'],
          },
        ],
        'consent': {'version': 'bank-contact-v1', 'text': 'I agree …'},
      });
      expect(form.fields.first.type, FormFieldType.amount);
      expect(form.fields.last.options, ['Home', 'Vehicle']);
      expect(form.consent.version, 'bank-contact-v1');
    });

    test('a withdrawn lead has no contact', () {
      final l = readBankLead({
        'id': 'L1',
        'reference': 'ENQ-7F3A2C',
        'kind': 1,
        'status': 5,
        'bankId': 'B1',
        'bankName': 'Himalayan Bank',
        'productType': 4,
        'contact': null,
        'withdrawnUtc': '2026-10-18T06:00:00Z',
      });
      expect(l.isWithdrawn, isTrue);
      expect(l.contact, isNull);
      expect(l.canWithdraw, isFalse);
    });

    test('an appointment cancellable until it starts', () {
      final a = readBankAppointment({
        'id': 'A1',
        'reference': 'APT-91B0C4',
        'bankId': 'B1',
        'bankName': 'Himalayan Bank',
        'branchName': 'New Road Branch',
        'date': '2026-10-21',
        'startTime': '10:00',
        'endTime': '10:30',
        'startUtc': '2026-10-21T04:15:00+00:00',
        'status': 1,
        'cancelledBy': null,
      });
      expect(a.canCancel(DateTime.utc(2026, 10, 21, 4)), isTrue);
      expect(a.canCancel(DateTime.utc(2026, 10, 21, 5)), isFalse);
    });

    test('contact JSON leaves out an empty email', () {
      expect(
        contactJson(
          const ContactDetails(name: ' Sita ', phone: '+9779841000000', email: ''),
        ),
        {'name': 'Sita', 'phone': '+9779841000000', 'preferredMethod': 1},
      );
    });
  });

  group('failures', () {
    DioException http(int status, [Map<String, dynamic>? body]) => DioException(
      requestOptions: RequestOptions(path: '/v1/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/v1/x'),
        statusCode: status,
        data: body,
      ),
    );

    test('a bare 404 is "coming soon", a coded one is "not found"', () {
      final bare = mapServiceFailure(http(404));
      expect(bare.isComingSoon, isTrue);
      final coded = mapServiceFailure(
        http(404, {'errorCode': 'booking.not_found', 'title': 'Not found'}),
      );
      expect(coded.isNotFound, isTrue);
      expect(coded.isComingSoon, isFalse);
      expect(serviceFailureMessage(coded), 'We could not find this booking.');
    });

    test('a 409 keeps its code', () {
      final f = mapServiceFailure(
        http(409, {'errorCode': 'service_appointment.slot_full'}),
      );
      expect(f.kind, ServiceFailureKind.conflict);
      expect(serviceFailureMessage(f), contains('filled up'));
    });
  });
}
