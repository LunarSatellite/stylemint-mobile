import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';

import '../../codes/support/recording_api_client.dart';

/// What actually goes over the wire to `POST /v1/checkout/sessions/{id}/pickup`
/// — the call that ends in `SetPickupAsync`. The endpoint has accepted
/// `pickupLocationId` all along; until now no client ever sent one, so every
/// collection order recorded no counter.
void main() {
  const sessionResponse = {'id': 'sess-1'};

  CheckoutRemoteDataSource dataSourceOver(RecordingApiClient client) =>
      CheckoutRemoteDataSource(apiClient: client);

  group('the pickup call', () {
    test('carries the chosen counter id alongside the seller', () async {
      final client = RecordingApiClient((_) => sessionResponse);
      await dataSourceOver(client).selectPickupLocation(
        sellerId: 'seller-1',
        locationId: 'loc-1',
      );

      final pickup = client.calls.last;
      expect(pickup.method, 'POST');
      expect(pickup.uri, '/v1/checkout/sessions/sess-1/pickup');
      expect(pickup.data, {
        'pickupVendorAccountId': 'seller-1',
        'pickupLocationId': 'loc-1',
      });
    });

    test('does not reuse the seller-only idempotency key', () async {
      // The seller-only key is already spent by selectDeliveryChoice for this
      // session and seller. Reusing it would have the server replay that
      // earlier response and silently drop the counter — the tap would look
      // accepted and the order would still record no location.
      final client = RecordingApiClient((_) => sessionResponse);
      final dataSource = dataSourceOver(client);

      await dataSource.selectDeliveryChoice(
        const DeliveryChoice(
          kind: DeliveryChoiceKind.pickupFromSeller,
          title: 'Pick up from the seller',
          detail: '',
          deliveries: 0,
          readyInDays: 1,
          sellerAccountId: 'seller-1',
          selected: false,
        ),
      );
      final sellerOnlyKey = client.calls.last.header('Idempotency-Key');

      await dataSource.selectPickupLocation(
        sellerId: 'seller-1',
        locationId: 'loc-1',
      );
      final withCounterKey = client.calls.last.header('Idempotency-Key');

      expect(withCounterKey, isNot(sellerOnlyKey));
      expect(withCounterKey, contains('loc-1'));
    });

    test('gives two different counters two different keys', () async {
      final client = RecordingApiClient((_) => sessionResponse);
      final dataSource = dataSourceOver(client);

      await dataSource.selectPickupLocation(
        sellerId: 'seller-1',
        locationId: 'loc-1',
      );
      final first = client.calls.last.header('Idempotency-Key');
      await dataSource.selectPickupLocation(
        sellerId: 'seller-1',
        locationId: 'loc-2',
      );

      // Changing your mind must reach the server, not be replayed as the
      // first choice.
      expect(client.calls.last.header('Idempotency-Key'), isNot(first));
    });

    test('the seller-only call is unchanged and sends no counter', () async {
      final client = RecordingApiClient((_) => sessionResponse);
      await dataSourceOver(client).selectDeliveryChoice(
        const DeliveryChoice(
          kind: DeliveryChoiceKind.pickupFromSeller,
          title: 'Pick up from the seller',
          detail: '',
          deliveries: 0,
          readyInDays: 1,
          sellerAccountId: 'seller-1',
          selected: false,
        ),
      );

      // A seller with no registered counter still checks out for collection on
      // exactly the request the app always sent.
      expect(client.calls.last.data, {'pickupVendorAccountId': 'seller-1'});
    });

    test('the delivery call is untouched', () async {
      final client = RecordingApiClient((_) => sessionResponse);
      await dataSourceOver(client).selectDeliveryChoice(
        const DeliveryChoice(
          kind: DeliveryChoiceKind.homeDelivery,
          title: 'Home delivery',
          detail: '',
          deliveries: 1,
          readyInDays: 2,
          selected: false,
        ),
      );

      final call = client.calls.last;
      expect(call.uri, '/v1/checkout/sessions/sess-1/delivery');
      expect(call.data, isNull);
    });
  });

  group('reading the counters back', () {
    Future<DeliveryChoices> choicesFrom(Map<String, dynamic> body) async {
      final client = RecordingApiClient(
        (call) => call.method == 'GET' ? body : sessionResponse,
      );
      return dataSourceOver(client).getDeliveryChoices();
    }

    test('no counters is an empty list, not an error', () async {
      // Every response carried `pickupLocations: null` before counters existed,
      // and still does whenever collection is not on offer.
      final choices = await choicesFrom({
        'choices': <dynamic>[],
        'emissionsNote': '',
      });
      expect(choices.pickupLocations, isEmpty);
      expect(choices.pickupLocationsNote, isNull);
    });

    test('blank fields are read as absent, not as empty strings', () async {
      final choices = await choicesFrom({
        'choices': <dynamic>[],
        'emissionsNote': '',
        'pickupLocations': [
          {
            'locationId': 'loc-1',
            'name': '   ',
            'addressLine': '',
            'city': 'Lalitpur',
            'openingHours': null,
            'confirmation': 'NeverConfirmed',
            'selected': false,
          },
        ],
      });

      final counter = choices.pickupLocations.single;
      expect(counter.name, isNull);
      expect(counter.addressLine, isNull);
      expect(counter.city, 'Lalitpur');
      expect(counter.openingHours, isNull);
      expect(counter.confirmation, PickupLocationConfirmation.neverConfirmed);
    });

    // A counter with no id cannot be chosen, so it is not offered.
    test('a counter with no id is not offered', () async {
      final choices = await choicesFrom({
        'choices': <dynamic>[],
        'emissionsNote': '',
        'pickupLocations': [
          {'locationId': '', 'name': 'Ghost counter'},
          {'locationId': 'loc-2', 'name': 'Thamel pickup desk'},
        ],
      });

      expect(choices.pickupLocations.map((l) => l.id), ['loc-2']);
    });

    test('an unrecognised confirmation state does not read as fresh', () async {
      final choices = await choicesFrom({
        'choices': <dynamic>[],
        'emissionsNote': '',
        'pickupLocations': [
          {'locationId': 'loc-1', 'confirmation': 'SomethingNewer'},
        ],
      });

      expect(
        choices.pickupLocations.single.confirmation,
        PickupLocationConfirmation.neverConfirmed,
      );
    });

    test('reads the confirmed and stale states the server sends', () async {
      final choices = await choicesFrom({
        'choices': <dynamic>[],
        'emissionsNote': '',
        'pickupLocations': [
          {'locationId': 'loc-1', 'confirmation': 'Confirmed'},
          {'locationId': 'loc-2', 'confirmation': 'Stale'},
        ],
      });

      expect(choices.pickupLocations.map((l) => l.confirmation), [
        PickupLocationConfirmation.confirmed,
        PickupLocationConfirmation.stale,
      ]);
    });
  });
}
