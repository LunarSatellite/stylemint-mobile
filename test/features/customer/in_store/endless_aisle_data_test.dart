import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/datasources/in_store_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/models/endless_aisle_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/repositories/in_store_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/endless_aisle.dart';

import '../../codes/support/recording_api_client.dart';

/// The backend's `EndlessAisleVm` for a product tag, as
/// `GET /v1/public/codes/{code}/endless-aisle` sends it.
Map<String, dynamic> _aisleJson() => <String, dynamic>{
  'code': 'SM-ABC-123',
  'kind': 'ProductTag',
  'productId': 'p-1',
  'productName': 'Linen shirt',
  'productImageUrl': 'https://cdn.stylemint.app/p-1.jpg',
  'productPriceAmount': 2499.0,
  'productPriceCurrency': 'NPR',
  'scannedAtLocationId': 's-1',
  'scannedAtLocationName': 'Durbarmarg branch',
  'vendorAccountId': 'v-1',
  'vendorDisplayName': 'Mint Studio',
  'canOrderFromAnywhere': true,
  'reachNote':
      'You can order this now and have it delivered or collected — you '
      'don’t need it to be on the shelf in front of you.',
  'inStoreAvailability': 'Unknown',
  'inStoreAvailabilityNote':
      "We don't know what this location has in stock. This platform records "
      'stock as one pool per item, not per location, so this is not '
      "'none left' and not 'available here' — it is unknown.",
  'pickupOffered': true,
  'pickupNote':
      'Mint Studio offers collection at the location below. We can’t tell '
      'you whether this item is there — see each location’s note.',
  'pickupLocations': <Map<String, dynamic>>[
    <String, dynamic>{
      'locationId': 's-1',
      'kind': 'VendorStore',
      'name': 'Durbarmarg branch',
      'addressLine': 'Durbarmarg 21',
      'city': 'Kathmandu',
      'latitude': 27.71,
      'longitude': 85.32,
      'openingHours': 'Sun–Fri 10:00–19:00',
      'lastConfirmedUtc': '2026-09-01T09:00:00Z',
      'confirmationState': 'Confirmed',
      'confirmationNote': 'The seller confirmed these details 19 days ago.',
      'stockAvailability': 'Unknown',
      'stockAvailabilityNote': "We don't know what this location has in stock.",
    },
  ],
};

void main() {
  group('EndlessAisleDto', () {
    test('maps the product-tag response', () {
      final aisle = EndlessAisleDto.fromJson(_aisleJson()).toDomain();

      expect(aisle.code, 'SM-ABC-123');
      expect(aisle.kind, CodeKind.productTag);
      expect(aisle.productId, 'p-1');
      expect(aisle.productPrice?.amount, 2499.0);
      expect(aisle.productPrice?.currency, 'NPR');
      expect(aisle.vendorAccountId, 'v-1');
      expect(aisle.canOrderFromAnywhere, isTrue);
      expect(aisle.reachNote, contains('order this now'));
      expect(aisle.pickupOffered, isTrue);
      expect(aisle.pickupLocations, hasLength(1));

      final location = aisle.pickupLocations.single;
      expect(location.locationId, 's-1');
      expect(location.addressSummary, 'Durbarmarg 21, Kathmandu');
      expect(location.openingHours, 'Sun–Fri 10:00–19:00');
      expect(location.confirmationState, LocationConfirmationState.confirmed);
      expect(location.lastConfirmedUtc, isNotNull);
    });

    test('stock is Unknown on the aisle and on every location', () {
      final aisle = EndlessAisleDto.fromJson(_aisleJson()).toDomain();

      expect(aisle.inStoreAvailability, PickupStockAvailability.unknown);
      expect(
        aisle.pickupLocations.single.stockAvailability,
        PickupStockAvailability.unknown,
      );
    });

    test('a stock value this build cannot read is still not an answer', () {
      final json = _aisleJson()..['inStoreAvailability'] = 'InStock';

      expect(
        EndlessAisleDto.fromJson(json).toDomain().inStoreAvailability,
        PickupStockAvailability.unrecognised,
      );
    });

    test('half a price is no price', () {
      final json = _aisleJson()..remove('productPriceCurrency');

      expect(EndlessAisleDto.fromJson(json).toDomain().productPrice, isNull);
    });

    test('a store code reaches the catalogue, not one item', () {
      final json = _aisleJson()
        ..['kind'] = 'Store'
        ..['canOrderFromAnywhere'] = false
        ..remove('productId')
        ..['reachNote'] =
            "You can browse and order this seller's whole catalogue from "
            'here; it isn’t limited to what’s on the shelf.';

      final aisle = EndlessAisleDto.fromJson(json).toDomain();

      expect(aisle.kind, CodeKind.store);
      expect(aisle.canOrderFromAnywhere, isFalse);
      expect(aisle.productId, isNull);
      expect(aisle.reachNote, contains('whole catalogue'));
    });

    test('a seller who offers no collection has no locations', () {
      final json = _aisleJson()
        ..['pickupOffered'] = false
        ..['pickupNote'] =
            "Mint Studio doesn't offer collection, so this would be "
            'delivered to you.'
        ..['pickupLocations'] = <Map<String, dynamic>>[];

      final aisle = EndlessAisleDto.fromJson(json).toDomain();

      expect(aisle.pickupOffered, isFalse);
      expect(aisle.pickupLocations, isEmpty);
      expect(aisle.isEmpty, isFalse, reason: 'the reach note still stands');
    });

    test('opening hours and a confirmation date stay absent when absent', () {
      final json = _aisleJson();
      final location =
          (json['pickupLocations']! as List).first as Map<String, dynamic>
            ..remove('openingHours')
            ..remove('lastConfirmedUtc')
            ..['confirmationState'] = 'NeverConfirmed';

      final mapped = EndlessAisleDto.fromJson(json).toDomain();

      expect(location['openingHours'], isNull);
      expect(mapped.pickupLocations.single.openingHours, isNull);
      expect(mapped.pickupLocations.single.lastConfirmedUtc, isNull);
      expect(
        mapped.pickupLocations.single.confirmationState,
        LocationConfirmationState.neverConfirmed,
      );
    });
  });

  group('InStoreRepositoryImpl.getEndlessAisle', () {
    InStoreRepositoryImpl repository(
      RecordingApiClient api, {
      bool connected = true,
    }) => InStoreRepositoryImpl(
      remoteDataSource: InStoreRemoteDataSource(apiClient: api),
      networkInfo: FakeNetworkInfo(connected: connected),
    );

    test('reads the sibling route of resolve, and counts no scan', () async {
      final api = RecordingApiClient((_) => _aisleJson());

      final result = await repository(api).getEndlessAisle('SM-ABC-123');

      expect(result.isRight(), isTrue);
      expect(api.last.method, 'GET');
      expect(api.last.uri, '/v1/public/codes/SM-ABC-123/endless-aisle');
      expect(
        api.calls.where((c) => c.method == 'POST'),
        isEmpty,
        reason: 'resolve already counted this scan',
      );
    });

    test('an unknown code maps to notFound', () async {
      final api = RecordingApiClient((_) => dioError(404));

      final result = await repository(api).getEndlessAisle('SM-NOPE');

      expect(
        result.fold((failure) => failure.isNotFound, (_) => false),
        isTrue,
      );
    });

    test('a profile code maps to the backend business rule', () async {
      final api = RecordingApiClient(
        (_) => dioError(
          400,
          body: <String, dynamic>{
            'errorCode': 'validation.business_rule',
            'title': 'This code points at a profile, not at a seller’s goods.',
          },
        ),
      );

      final result = await repository(api).getEndlessAisle('SM-PROF');

      expect(
        result.fold(
          (failure) => failure.validationCode,
          (_) => null,
        ),
        'validation.business_rule',
      );
    });

    test('offline never reaches the network', () async {
      final api = RecordingApiClient((_) => _aisleJson());

      final result = await repository(
        api,
        connected: false,
      ).getEndlessAisle('SM-ABC-123');

      expect(
        result.fold((failure) => failure.isNoInternet, (_) => false),
        isTrue,
      );
      expect(api.calls, isEmpty);
    });

    test('a malformed body is an unexpected error, not a crash', () async {
      final api = RecordingApiClient((_) => 'not json');

      final result = await repository(api).getEndlessAisle('SM-ABC-123');

      expect(result.isLeft(), isTrue);
    });
  });
}
