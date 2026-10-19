import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/models/checkout_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/models/reel_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/datasources/service_cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/service_item_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/service_line_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/checkout/checkout_service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/item/service_choice.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_line_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import 'services_fakes.dart';

/// Service items contract v1 and service cart contract v1.1 — the shapes the
/// app reads, and the choice it sends — without any screen.
void main() {
  group('item detail (service items contract §4)', () {
    test('a stay item reads its type, price label and rooms', () {
      final json = {
        'serviceType': 1,
        'displayPrice': {
          'amount': 4500,
          'currency': 'NPR',
          'unit': 'night',
          'isFrom': true,
          'label': 'from Rs 4,500/night',
        },
        'service': {
          'type': 1,
          'listingId': stayId,
          'addableToCart': true,
          'priceUnit': 'night',
          'stay': {
            'listingId': stayId,
            'title': 'Hotel Barahi',
            'currency': 'NPR',
            'minNights': 2,
            'paymentModes': [1, 2],
            'depositPercent': 30,
            'cancellationPolicy': {
              'freeCancellationDays': 3,
              'lateCancellationFeePercent': 50,
            },
            'roomTypes': [
              {
                'id': roomId,
                'name': 'Deluxe Double',
                'baseRate': 4500,
                'maxAdults': 2,
                'maxGuests': 3,
              },
            ],
          },
        },
      };
      expect(readServiceItemType(json), ServiceItemType.stay);
      final price = readDisplayPrice(json['displayPrice'])!;
      expect(price.describe(serviceMoney), 'from Rs 4,500/night');
      final item = readServiceItem(json['service'])!;
      expect(item.type, ServiceItemType.stay);
      expect(item.addableToCart, isTrue);
      expect(item.stay!.minNights, 2);
      expect(item.stay!.roomTypes.single.name, 'Deluxe Double');
      expect(item.package, isNull);
    });

    test('a product carries no service fields', () {
      final json = <String, dynamic>{'id': 'p1', 'name': 'Scarf'};
      expect(readServiceItemType(json), isNull);
      expect(readDisplayPrice(json['displayPrice']), isNull);
      expect(readServiceItem(json['service']), isNull);
    });

    test('a bank item has its forms, branches and no cart', () {
      final item = readServiceItem({
        'type': 3,
        'listingId': loanId,
        'addableToCart': false,
        'bank': {
          'bankId': bankId,
          'bankName': 'Himalayan Bank',
          'product': {
            'id': loanId,
            'bankId': bankId,
            'bankName': 'Himalayan Bank',
            'type': 4,
            'name': 'Home Loan',
          },
          'branches': [
            {
              'id': branchId,
              'bankId': bankId,
              'name': 'New Road',
              'appointmentsEnabled': true,
            },
          ],
          'enquiryForm': {
            'bankId': bankId,
            'fields': <Object>[],
            'consent': {'version': 'v1', 'text': 'I agree.'},
          },
          // No consent wording: left out, never shown without it.
          'appointmentForm': {
            'bankId': bankId,
            'fields': <Object>[],
          },
        },
      })!;
      expect(item.addableToCart, isFalse);
      expect(item.bank!.product!.name, 'Home Loan');
      expect(item.bank!.takesAppointments, isTrue);
      expect(item.bank!.enquiryForm, isNotNull);
      expect(item.bank!.appointmentForm, isNull);
    });

    test('a service block the module could not answer is null', () {
      expect(readServiceItem(null), isNull);
      expect(readServiceItem({'type': 9}), isNull);
    });

    test('price labels fall back to the figures', () {
      const perPerson = DisplayPrice(
        amount: Money(amount: 45000, currency: 'NPR'),
        unit: 'person',
      );
      expect(perPerson.describe(serviceMoney), 'Rs 45,000 per person');
      const bank = DisplayPrice();
      expect(bank.describe(serviceMoney), isNull);
    });
  });

  group('reel tags (§5.1)', () {
    test('a service tag reads its label and whether it goes in a cart', () {
      final stay = TaggedProductDto.fromJson({
        'id': stayId,
        'name': 'Hotel Barahi',
        'imageUrl': '',
        'amount': 4500,
        'serviceType': 1,
        'displayPrice': {'label': 'from Rs 4,500/night'},
        'addableToCart': true,
      }).toDomain();
      expect(stay.isService, isTrue);
      expect(stay.serviceLabel, 'from Rs 4,500/night');

      final bank = TaggedProductDto.fromJson({
        'id': loanId,
        'name': 'Home Loan',
        'imageUrl': '',
        'amount': 0,
        'serviceType': 3,
        'displayPrice': {'amount': null, 'label': null},
        'addableToCart': false,
      }).toDomain();
      expect(bank.serviceLabel, 'Enquire');
      expect(bank.addableToCart, isFalse);
    });

    test('a product tag is unchanged', () {
      final tag = TaggedProductDto.fromJson({
        'id': 'p1',
        'name': 'Scarf',
        'imageUrl': '',
        'amount': 1200,
      }).toDomain();
      expect(tag.isService, isFalse);
      expect(tag.serviceLabel, isNull);
      expect(tag.addableToCart, isTrue);
    });
  });

  group('cart (service cart contract §2)', () {
    Map<String, dynamic> cartJson({bool withService = true}) => {
      'accountId': 'acc-1',
      'lines': [
        {
          'lineId': 'line-stay',
          'productId': stayId,
          'productTitleSnapshot': 'Hotel Barahi',
          'variantLabelSnapshot': 'DEFAULT',
          'optionLabel': 'Deluxe Double · 2 Nov – 4 Nov',
          'quantity': 1,
          'unitPriceAmount': 9000,
          if (withService) ...{
            'lineKind': 2,
            'service': {
              'kind': 1,
              'listingId': stayId,
              'listingTitle': 'Hotel Barahi',
              'itemName': 'Deluxe Double',
              'roomTypeId': roomId,
              'startDate': '2026-11-02',
              'endDate': '2026-11-04',
              'nights': 2,
              'rooms': 1,
              'adults': 2,
              'children': 0,
              'paymentMode': 2,
              'depositPercent': 30,
              'currency': 'NPR',
              'totalPrice': 9000,
              'payNowAmount': 2700,
              'payAtVenueAmount': 6300,
              'paymentModes': [1, 2, 3],
            },
          },
        },
      ],
      'subtotalAmount': 9000,
      'shippingAmount': 0,
      'taxAmount': 0,
      'grandTotalAmount': 9000,
      if (withService) ...{
        'payNowTotalAmount': 2700,
        'payAtVenueTotalAmount': 6300,
        'hasServiceLines': true,
        'requiresShippingAddress': false,
      },
    };

    test('a service line carries its options and its two amounts', () {
      final cart = CartDto.fromJson(cartJson()).toDomain();
      final line = cart.items.single;
      expect(line.isService, isTrue);
      final s = line.service!;
      expect(s.lineId, 'line-stay');
      expect(s.isStay, isTrue);
      expect(s.startDate, DateTime(2026, 11, 2));
      expect(s.endDate, DateTime(2026, 11, 4));
      expect(s.paymentMode, PaymentMode.deposit);
      expect(s.payNow.amount, 2700);
      expect(s.payAtVenue.amount, 6300);
      expect(s.paymentModes, hasLength(3));
      expect(cart.hasServiceLines, isTrue);
      expect(cart.requiresShippingAddress, isFalse);
      expect(cart.payNowTotal!.amount, 2700);
      expect(cart.payAtVenueTotal!.amount, 6300);
      expect(cart.serviceItems, hasLength(1));
    });

    test('an older server: a product line, the total is what is paid', () {
      final cart = CartDto.fromJson(cartJson(withService: false)).toDomain();
      expect(cart.items.single.isService, isFalse);
      expect(cart.hasServiceLines, isFalse);
      expect(cart.requiresShippingAddress, isTrue);
      expect(cart.payNowTotal, isNull);
    });

    test('serviceOptions: a stay names its room and dates, a trip its '
        'departure; nothing names an amount', () {
      final stay = ServiceCartRemoteDataSource.optionsJson(
        ServiceOptions.stay(
          listingId: stayId,
          roomTypeId: roomId,
          checkIn: DateTime(2026, 11, 2),
          checkOut: DateTime(2026, 11, 4),
          rooms: 1,
          adults: 2,
          paymentMode: PaymentMode.deposit,
        ),
      );
      expect(stay, {
        'listingId': stayId,
        'roomTypeId': roomId,
        'checkIn': '2026-11-02',
        'checkOut': '2026-11-04',
        'rooms': 1,
        'adults': 2,
        'children': 0,
        'paymentMode': 2,
      });
      final trip = ServiceCartRemoteDataSource.optionsJson(
        const ServiceOptions.package(
          listingId: packageId,
          departureId: departureId,
          adults: 2,
          children: 1,
        ),
      );
      expect(trip, {
        'listingId': packageId,
        'departureId': departureId,
        'adults': 2,
        'children': 1,
      });
    });
  });

  group('checkout (§3)', () {
    test('the session reads its service lines and the two amounts', () {
      final summary = CheckoutSummaryDto.fromJson({
        'id': 'session-1',
        'requiresShippingAddress': false,
        'payNowAmount': 2700,
        'payAtVenueAmount': 6300,
        'serviceLines': [
          {
            'lineId': 'line-stay',
            'bookingId': bookingId,
            'bookingNumber': 'BK-7F3A9C21',
            'holdExpiresUtc': '2026-10-18T06:30:00Z',
            'kind': 1,
            'listingTitle': 'Hotel Barahi',
            'startDate': '2026-11-02',
            'endDate': '2026-11-04',
            'adults': 2,
            'paymentMode': 2,
            'totalPrice': 9000,
            'payNowAmount': 2700,
            'payAtVenueAmount': 6300,
            'guestName': null,
            'travellers': <Object>[],
            'guestsComplete': false,
          },
        ],
      }).toDomain(fallback: serviceCart());
      expect(summary.sessionId, 'session-1');
      expect(summary.requiresShippingAddress, isFalse);
      expect(summary.payNow!.amount, 2700);
      expect(summary.hasServiceLines, isTrue);
      expect(summary.requiresOnlinePayment, isTrue);
      expect(summary.serviceGuestsComplete, isFalse);
      final line = summary.serviceLines.single;
      expect(line.bookingNumber, 'BK-7F3A9C21');
      expect(line.holdExpiresAt, DateTime.utc(2026, 10, 18, 6, 30));
    });

    test('per-line errors from checkout.service_unavailable', () {
      const failure = NetworkExceptions.validation(
        code: 'checkout.service_unavailable',
        errors: [
          FieldErrorVm(field: 'line-stay', code: 'sold_out', message: ''),
        ],
      );
      final errors = checkoutServiceLineErrors(failure);
      expect(errors.keys, ['line-stay']);
      expect(errors['line-stay'], contains('Sold out'));
      expect(checkoutServiceMessage(failure), contains('just taken'));
      expect(
        checkoutServiceLineErrors(
          const NetworkExceptions.validation(code: 'checkout.invalid'),
        ),
        isEmpty,
      );
    });
  });

  group('orders (§4)', () {
    test('booking lines are read apart from the products', () {
      final order = OrderDetailDto.fromJson({
        'id': 'o1',
        'orderNumber': 'NK2026-00042',
        'state': 2,
        'placedUtc': '2026-10-18T05:00:00Z',
        'payAtVenueTotalAmount': 6300,
        'subOrders': [
          {
            'id': 's-product',
            'state': 3,
            'fulfillmentChannel': 'Delivery',
            'lines': [
              {
                'id': 'l1',
                'productVariantId': 'v1',
                'productTitleSnapshot': 'Scarf',
                'quantity': 1,
                'unitPriceAmount': 1200,
              },
            ],
          },
          {
            'id': 's-service',
            'state': 3,
            'fulfillmentChannel': 'Service',
            'lines': [
              {
                'id': 'l2',
                'productVariantId': 'v2',
                'productTitleSnapshot': 'Hotel Barahi',
                'quantity': 1,
                'unitPriceAmount': 2700,
                'lineKind': 2,
                'booking': {
                  'bookingId': bookingId,
                  'bookingNumber': 'BK-7F3A9C21',
                  'state': 2,
                  'kind': 1,
                  'listingId': stayId,
                  'listingTitle': 'Hotel Barahi',
                  'startDate': '2026-11-02',
                  'endDate': '2026-11-04',
                  'adults': 2,
                  'guestName': 'Sita Sharma',
                  'totalPrice': 9000,
                  'paidNowAmount': 2700,
                  'payAtVenueAmount': 6300,
                  'paymentMode': 2,
                  'canCancel': true,
                },
              },
            ],
          },
        ],
      }).toDomain();
      expect(order.items.map((i) => i.productName), ['Scarf']);
      final b = order.bookingLines.single;
      expect(b.bookingNumber, 'BK-7F3A9C21');
      expect(b.bookingState, BookingState.confirmed);
      expect(b.payNow.amount, 2700);
      expect(b.canCancel, isTrue);
      expect(order.payAtVenue!.amount, 6300);
      // The product part still cancels as an order.
      expect(order.canCancel, isTrue);
    });

    test('an order of bookings only has no address and no order cancel', () {
      final order = OrderDetailDto.fromJson({
        'id': 'o2',
        'orderNumber': 'NK2026-00043',
        'state': 2,
        'placedUtc': '2026-10-18T05:00:00Z',
        'subOrders': [
          {
            'id': 's-service',
            'fulfillmentChannel': 'Service',
            'lines': [
              {
                'id': 'l2',
                'productVariantId': 'v2',
                'lineKind': 2,
                'booking': {
                  'kind': 2,
                  'listingId': packageId,
                  'listingTitle': 'Annapurna',
                  'startDate': '2026-11-02',
                  'paidNowAmount': 120000,
                },
              },
            ],
          },
        ],
      }).toDomain();
      expect(order.items, isEmpty);
      expect(order.bookingLines, hasLength(1));
      expect(order.shippingAddress, isEmpty);
      expect(order.canCancel, isFalse);
      expect(order.canReturn, isFalse);
    });
  });

  group('service lines in words', () {
    test('a stay, a trip', () {
      expect(serviceLineGuests(stayLine()), '1 room · 2 adults');
      expect(serviceLineGuests(packageLine()), '2 adults, 1 child');
      expect(serviceLineDates(stayLine()), contains('2 nights'));
      expect(serviceLineDates(packageLine()), startsWith('Departs'));
      expect(serviceLinePaymentLabel(stayLine()), contains('30% deposit'));
    });

    test('isServiceLineKind', () {
      expect(isServiceLineKind(2), isTrue);
      expect(isServiceLineKind(1), isFalse);
      expect(isServiceLineKind(null), isFalse);
    });

    test('readServiceLine refuses a block without kind or start date', () {
      expect(readServiceLine({'kind': 1}), isNull);
      expect(readServiceLine({'startDate': '2026-11-02'}), isNull);
    });
  });

  group('ServiceChoice', () {
    test('a stay is complete with a room, and the options follow it', () {
      final choice = ServiceChoice(item: stayItemBlock(), today: testNow);
      expect(choice.isComplete, isFalse);
      expect(choice.toOptions(), isNull);
      choice
        ..setDates(DateTime(2026, 10, 21), DateTime(2026, 10, 23))
        ..selectRoom(roomId);
      expect(choice.isComplete, isTrue);
      final options = choice.toOptions()!;
      expect(options.kind, ListingKind.stay);
      expect(options.roomTypeId, roomId);
      expect(options.nights, 2);
    });

    test('a quote is dropped when the choice changes', () async {
      final choice = ServiceChoice(item: stayItemBlock(), today: testNow)
        ..selectRoom(roomId);
      await choice.price((_) async => (quote: stayQuote(), error: null));
      expect(choice.canAdd, isTrue);
      expect(choice.paymentMode, PaymentMode.fullPrepay);
      choice.selectPaymentMode(PaymentMode.deposit);
      expect(choice.paymentOption!.payNow.amount, 2700);
      choice.setAdults(3);
      expect(choice.quote, isNull);
      expect(choice.canAdd, isFalse);
    });

    test('a reply to an older choice is ignored', () async {
      final choice = ServiceChoice(item: stayItemBlock(), today: testNow)
        ..selectRoom(roomId);
      final pending = choice.price((_) async {
        choice.setRooms(2);
        return (quote: stayQuote(), error: null);
      });
      await pending;
      expect(choice.quote, isNull);
    });

    test('opened from a cart line, it starts from that line', () {
      final choice = ServiceChoice(
        item: stayItemBlock(),
        today: testNow,
        from: stayLine(),
      );
      expect(choice.roomTypeId, roomId);
      expect(choice.checkIn, DateTime(2026, 10, 21));
      expect(choice.checkOut, DateTime(2026, 10, 23));
      expect(choice.adults, 2);
    });

    test('a trip is complete with a departure', () {
      final choice = ServiceChoice(item: packageItemBlock(), today: testNow)
        ..selectDeparture(departureId)
        ..setChildren(1);
      final options = choice.toOptions()!;
      expect(options.kind, ListingKind.package);
      expect(options.departureId, departureId);
      expect(options.children, 1);
    });
  });

  test('Cart keeps its service fields through copyWith', () {
    final cart = serviceCart().copyWith(items: const <CartItem>[]);
    expect(cart.hasServiceLines, isTrue);
    expect(cart.payNowTotal!.amount, 2700);
    expect(cart.requiresShippingAddress, isFalse);
  });

  test('ServiceLine guests', () {
    final line = packageLine();
    expect(line.guests, 3);
    expect(line, isA<ServiceLine>());
  });
}
