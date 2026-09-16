import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/models/checkout_dto.dart'
    as checkout;
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart'
    as checkout_entity;
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/models/shipping_address_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';

/// A location-captured address exactly as the backend now sends it: the
/// postal fields are present but explicitly null.
const Map<String, dynamic> _locationJson = {
  'id': 'addr-1',
  'label': 'Home',
  'receiverName': 'Sita Rai',
  'receiverPhone': '+9779800000000',
  'country': 'NP',
  'locationNote': 'Blue gate opposite the pharmacy, second floor, ring twice',
  'mapsLink': 'https://maps.app.goo.gl/AbCdEf123',
  'latitude': 27.7172,
  'longitude': 85.324,
  'locationAccuracyMetres': 8,
  'locationCapturedFrom': 1,
  'addressLine1': null,
  'landmark': null,
  'state': null,
  'city': null,
  'zipCode': null,
  'isDefault': true,
};

void main() {
  group('ShippingAddressDto', () {
    test('parses an address whose postal fields are explicitly null', () {
      // Regression guard: with non-nullable fields plus @Default(''), an
      // explicit "city": null throws and every address vanishes from the app.
      final dto = ShippingAddressDto.fromJson(Map.of(_locationJson));

      expect(dto.city, isNull);
      expect(dto.addressLine1, isNull);
      expect(dto.zipCode, isNull);
      expect(dto.latitude, 27.7172);
      expect(dto.locationAccuracyMetres, 8);
      expect(dto.locationCapturedFrom, 1);
    });

    test('maps locationCapturedFrom onto the enum', () {
      final address = ShippingAddressDto.fromJson(
        Map.of(_locationJson),
      ).toDomain();

      expect(address.locationCapturedFrom, LocationSource.deviceGps);
      expect(address.hasPoint, isTrue);
      expect(address.hasMapsLink, isTrue);
      expect(address.isLegacy, isFalse);
      expect(address.summaryLine, startsWith('Blue gate'));
    });

    test('still parses a legacy postal-only address', () {
      final dto = ShippingAddressDto.fromJson({
        'id': 'legacy-1',
        'label': 'Home',
        'receiverName': 'Ram Thapa',
        'receiverPhone': '+9779811111111',
        'country': 'NP',
        'addressLine1': 'Jhamsikhel Road 12',
        'city': 'Lalitpur',
        'state': 'Bagmati',
        'zipCode': '44700',
      });
      final address = dto.toDomain();

      expect(address.isLegacy, isTrue);
      expect(address.locationNote, isEmpty);
      expect(
        address.summaryLine,
        'Jhamsikhel Road 12, Lalitpur, Bagmati, 44700',
      );
    });

    test('an unknown locationCapturedFrom value degrades to null', () {
      final dto = ShippingAddressDto.fromJson({
        ...Map.of(_locationJson),
        'locationCapturedFrom': 99,
      });
      expect(dto.toDomain().locationCapturedFrom, isNull);
    });
  });

  group('writeBody', () {
    const gpsAddress = ShippingAddress(
      id: 'addr-1',
      label: 'Home',
      receiverName: 'Sita Rai',
      receiverPhone: '+9779800000000',
      country: 'NP',
      locationNote: 'Blue gate',
      latitude: 27.7172,
      longitude: 85.324,
      locationAccuracyMetres: 8,
      locationCapturedFrom: LocationSource.deviceGps,
      isDefault: true,
    );

    test('sends the point with its source, and nulls every postal field', () {
      final body = ShippingAddressDto.writeBody(gpsAddress);

      expect(body['latitude'], 27.7172);
      expect(body['longitude'], 85.324);
      expect(body['locationCapturedFrom'], 1);
      expect(body['locationAccuracyMetres'], 8);
      expect(body['locationNote'], 'Blue gate');
      expect(body['addressLine1'], isNull);
      expect(body['city'], isNull);
      expect(body['state'], isNull);
      expect(body['zipCode'], isNull);
      expect(body['makeDefault'], isTrue);
    });

    test('a manual pin is sent as source 2', () {
      final body = ShippingAddressDto.writeBody(
        gpsAddress.copyWith(locationCapturedFrom: LocationSource.manualPin),
      );
      expect(body['locationCapturedFrom'], 2);
    });

    test('rounds decimal GPS accuracy to the API integer contract', () {
      final body = ShippingAddressDto.writeBody(
        gpsAddress.copyWith(locationAccuracyMetres: 8.42),
      );

      expect(body['locationAccuracyMetres'], 8);
      expect(body['locationAccuracyMetres'], isA<int>());
    });

    test('never sends SharedMapsLink (4) — the server stamps that', () {
      const linkOnly = ShippingAddress(
        id: 'addr-2',
        label: 'Home',
        receiverName: 'Sita Rai',
        receiverPhone: '+9779800000000',
        country: 'NP',
        mapsLink: 'https://maps.app.goo.gl/AbCdEf123',
      );
      final body = ShippingAddressDto.writeBody(linkOnly);

      expect(body.containsKey('locationCapturedFrom'), isFalse);
      expect(body['mapsLink'], 'https://maps.app.goo.gl/AbCdEf123');
      expect(body.containsKey('latitude'), isFalse);
    });

    test('a note-only update omits the point so the server keeps it', () {
      const noteOnly = ShippingAddress(
        id: 'addr-3',
        label: 'Home',
        receiverName: 'Sita Rai',
        receiverPhone: '+9779800000000',
        country: 'NP',
        locationNote: 'Second floor now',
        mapsLink: 'https://maps.app.goo.gl/AbCdEf123',
      );
      final body = ShippingAddressDto.writeBody(
        noteOnly,
        includeMakeDefault: false,
      );

      expect(body.containsKey('latitude'), isFalse);
      expect(body.containsKey('longitude'), isFalse);
      expect(body.containsKey('makeDefault'), isFalse);
      expect(body['locationNote'], 'Second floor now');
    });

    test('a blank maps link is sent as null, not an empty string', () {
      final body = ShippingAddressDto.writeBody(
        gpsAddress.copyWith(mapsLink: '   '),
      );
      expect(body['mapsLink'], isNull);
    });
  });

  group('checkout ShippingAddressDto', () {
    test('parses null postal fields and renders from the note', () {
      final address = checkout.ShippingAddressDto.fromJson(
        Map.of(_locationJson),
      ).toDomain();

      expect(address.city, isNull);
      expect(address.summaryLine, startsWith('Blue gate'));
      expect(address.summaryLine, isNot(contains('null')));
      expect(address.isEmpty, isFalse);
      expect(address.hasLocation, isTrue);
    });

    test('the empty sentinel is recognised by id, not by a blank line1', () {
      const sentinel = checkout_entity.ShippingAddress.empty();
      expect(sentinel.isEmpty, isTrue);

      // A real location-captured address also has a null line1 — it must not
      // be mistaken for the sentinel.
      final real = checkout.ShippingAddressDto.fromJson(
        Map.of(_locationJson),
      ).toDomain();
      expect(real.line1, isNull);
      expect(real.isEmpty, isFalse);
    });
  });

  group('order ship-to snapshot', () {
    test('renders the note for a location-captured order', () {
      final dto = ShippingAddressSnapshotDto.fromJson({
        'receiverName': 'Sita Rai',
        'receiverPhone': '+9779800000000',
        'locationNote': 'Blue gate opposite the pharmacy',
        'addressLine1': null,
        'city': null,
        'state': null,
        'zipCode': null,
        'country': null,
      });

      expect(dto.toDisplayString(), 'Blue gate opposite the pharmacy');
    });

    test('never renders "null" or a dangling comma for a partial address', () {
      final dto = ShippingAddressSnapshotDto.fromJson({
        'receiverName': 'Ram Thapa',
        'addressLine1': 'Jhamsikhel Road 12',
        'city': null,
        'state': null,
        'zipCode': null,
      });

      expect(dto.toDisplayString(), 'Jhamsikhel Road 12');
      expect(dto.toDisplayString(), isNot(contains('null')));
    });

    test('falls back to the point when there is nothing else', () {
      final dto = ShippingAddressSnapshotDto.fromJson({
        'latitude': 27.7172,
        'longitude': 85.324,
      });

      expect(dto.toDisplayString(), '27.71720, 85.32400');
    });

    test('is never blank', () {
      final dto = ShippingAddressSnapshotDto.fromJson(
        const <String, dynamic>{},
      );
      expect(dto.toDisplayString(), isNotEmpty);
    });
  });
}
