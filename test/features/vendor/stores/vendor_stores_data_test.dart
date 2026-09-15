import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/data/datasources/vendor_stores_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/data/models/vendor_store_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/data/repositories/vendor_stores_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store_draft.dart';

import '../../codes/support/recording_api_client.dart';

Map<String, dynamic> _storeJson({String id = 's-1', Object? isActive = true}) =>
    <String, dynamic>{
      'id': id,
      'name': 'Mint Thamel',
      'addressLine': 'Thamel Marg 12',
      'city': 'Kathmandu',
      'latitude': 27.7154,
      'longitude': 85.3123,
      'phone': '+977 1 4412345',
      'isActive': isActive,
      'createdUtc': '2026-09-15T08:00:00Z',
    };

const _draft = VendorStoreDraft(
  name: '  Mint Thamel ',
  addressLine: 'Thamel Marg 12',
  city: 'Kathmandu',
  latitude: 27.7154,
  longitude: 85.3123,
  phone: '  ',
);

class _MockRemote extends Mock implements VendorStoresRemoteDataSource {}

void main() {
  setUpAll(
    () => registerFallbackValue(
      const VendorStoreDraft(name: 'x', addressLine: 'y', city: 'z'),
    ),
  );

  group('VendorStoreDto', () {
    test('maps every VendorStoreVm field', () {
      final store = VendorStoreDto.fromJson(_storeJson()).toDomain();

      expect(store.id, 's-1');
      expect(store.name, 'Mint Thamel');
      expect(store.addressLine, 'Thamel Marg 12');
      expect(store.city, 'Kathmandu');
      expect(store.latitude, 27.7154);
      expect(store.longitude, 85.3123);
      expect(store.phone, '+977 1 4412345');
      expect(store.isActive, isTrue);
      expect(store.createdUtc, DateTime.utc(2026, 9, 15, 8));
      expect(store.addressSummary, 'Thamel Marg 12, Kathmandu');
    });

    test('isActive false is kept; a missing one reads as active', () {
      expect(
        VendorStoreDto.fromJson(_storeJson(isActive: false)).isActive,
        isFalse,
      );
      expect(
        VendorStoreDto.fromJson(<String, dynamic>{'id': 's-2'}).isActive,
        isTrue,
      );
    });

    test('pages drop stores without an id', () {
      final stores = VendorStoreDto.listFromPage(<String, dynamic>{
        'items': [
          _storeJson(),
          <String, dynamic>{'name': 'No id'},
        ],
      });

      expect(stores.single.id, 's-1');
      expect(VendorStoreDto.listFromPage('nope'), isEmpty);
    });

    test('the create/update body is trimmed, blank phone as null', () {
      expect(VendorStoreDto.draftToJson(_draft), <String, dynamic>{
        'name': 'Mint Thamel',
        'addressLine': 'Thamel Marg 12',
        'city': 'Kathmandu',
        'latitude': 27.7154,
        'longitude': 85.3123,
        'phone': null,
      });
    });
  });

  group('VendorStoreDraft.validate', () {
    test('a complete draft, and one at the limits, passes', () {
      expect(_draft.validate().isEmpty, isTrue);
      expect(
        VendorStoreDraft(
          name: 'AB',
          addressLine: 'A',
          city: 'K',
          latitude: -90,
          longitude: 180,
          phone: '1' * 20,
        ).validate().isEmpty,
        isTrue,
      );
    });

    test('flags every rule the contract sets', () {
      final errors = VendorStoreDraft(
        name: ' A ',
        addressLine: '  ',
        city: '',
        latitude: 90.5,
        longitude: -181,
        phone: '1' * 21,
      ).validate();

      expect(errors.name, contains('at least 2'));
      expect(errors.addressLine, isNotNull);
      expect(errors.city, isNotNull);
      expect(errors.latitude, contains('-90 and 90'));
      expect(errors.longitude, contains('-180 and 180'));
      expect(errors.phone, contains('20'));
      expect(errors.general, isNull);

      final long = VendorStoreDraft(
        name: 'n' * 81,
        addressLine: 'a' * 161,
        city: 'c' * 81,
      ).validate();
      expect(long.name, contains('80'));
      expect(long.addressLine, contains('160'));
      expect(long.city, contains('80'));
    });
  });

  group('VendorStoreFormErrors.fromFailure', () {
    test('errors[] go under their fields; unknown fields are general', () {
      const failure = NetworkExceptions.validation(
        code: 'validation.multiple_errors',
        message: 'One or more validation errors occurred.',
        errors: [
          FieldErrorVm(
            field: 'Name',
            code: 'validation.too_short',
            message: 'Name must be at least 2 characters.',
          ),
          FieldErrorVm(
            field: 'Latitude',
            code: 'validation.out_of_range',
            message: 'Latitude must be between -90 and 90.',
          ),
          FieldErrorVm(
            field: 'Country',
            code: 'validation.unknown',
            message: 'Country is not supported.',
          ),
        ],
      );

      final errors = VendorStoreFormErrors.fromFailure(failure);

      expect(errors.name, 'Name must be at least 2 characters.');
      expect(errors.latitude, 'Latitude must be between -90 and 90.');
      expect(errors.general, 'Country is not supported.');
      expect(errors.city, isNull);
    });

    test('a single field, a business rule and a network error', () {
      expect(
        VendorStoreFormErrors.fromFailure(
          const NetworkExceptions.validation(
            code: 'validation.too_long',
            message: 'Phone is too long.',
            field: 'phone',
          ),
        ).phone,
        'Phone is too long.',
      );

      final rule = VendorStoreFormErrors.fromFailure(
        const NetworkExceptions.validation(
          code: 'state.conflict',
          message: 'You already have a store with this name.',
        ),
      );
      expect(rule.general, 'You already have a store with this name.');
      expect(rule.name, isNull);

      expect(
        VendorStoreFormErrors.fromFailure(
          const NetworkExceptions.noInternetConnection(),
        ).general,
        'No internet connection.',
      );
    });
  });

  group('VendorStoresRemoteDataSource', () {
    test('GET sends pageSize and the cursor when there is one', () async {
      final api = RecordingApiClient(
        (_) => <String, dynamic>{
          'items': [_storeJson()],
          'totalCount': 2,
          'nextCursor': 'c-2',
          'previousCursor': null,
          'pageSize': 50,
        },
      );
      final source = VendorStoresRemoteDataSource(apiClient: api);

      final first = await source.getStores();
      expect(api.last.uri, '/v1/vendor/stores');
      expect(api.last.query, <String, dynamic>{'pageSize': 50});

      await source.getStores(cursor: 'c-2');
      expect(api.last.query, <String, dynamic>{
        'pageSize': 50,
        'cursor': 'c-2',
      });
      expect(first.stores.single.name, 'Mint Thamel');
      expect(first.nextCursor, 'c-2');
    });

    test('create, update and archive send an Idempotency-Key', () async {
      final api = RecordingApiClient(
        (call) => call.uri.endsWith('/archive') ? null : _storeJson(),
      );
      final source = VendorStoresRemoteDataSource(apiClient: api);

      await source.createStore(draft: _draft, idempotencyKey: 'k-1');
      await source.updateStore(
        storeId: 's-1',
        draft: _draft,
        idempotencyKey: 'k-2',
      );
      await source.archiveStore(storeId: 's-1', idempotencyKey: 'k-3');

      expect(api.calls.map((c) => '${c.method} ${c.uri}'), [
        'POST /v1/vendor/stores',
        'PUT /v1/vendor/stores/s-1',
        'POST /v1/vendor/stores/s-1/archive',
      ]);
      expect(api.calls.first.data, VendorStoreDto.draftToJson(_draft));
      expect(api.calls[1].data, VendorStoreDto.draftToJson(_draft));
      expect(api.calls.map((c) => c.header('Idempotency-Key')), [
        'k-1',
        'k-2',
        'k-3',
      ]);
      expect(api.calls.every((c) => c.header('requiresToken') == true), isTrue);
    });
  });

  group('VendorStoresRepositoryImpl', () {
    late _MockRemote remote;

    setUp(() => remote = _MockRemote());

    VendorStoresRepositoryImpl repo({bool connected = true}) =>
        VendorStoresRepositoryImpl(
          remoteDataSource: remote,
          networkInfo: FakeNetworkInfo(connected: connected),
        );

    test('walks every page of stores', () async {
      when(() => remote.getStores()).thenAnswer(
        (_) async => (
          stores: [VendorStoreDto.fromJson(_storeJson())],
          nextCursor: 'c-2',
        ),
      );
      when(() => remote.getStores(cursor: 'c-2')).thenAnswer(
        (_) async => (
          stores: [VendorStoreDto.fromJson(_storeJson(id: 's-2'))],
          nextCursor: null,
        ),
      );

      final result = await repo().getStores();

      expect(result.getRight().toNullable()!.map((s) => s.id), ['s-1', 's-2']);
    });

    test('a 400 on create keeps the field errors for the form', () async {
      when(
        () => remote.createStore(
          draft: any(named: 'draft'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(
        dioError(
          400,
          body: <String, dynamic>{
            'title': 'One or more validation errors occurred.',
            'errorCode': 'validation.multiple_errors',
            'errors': [
              <String, dynamic>{
                'field': 'City',
                'code': 'validation.required',
                'message': 'City is required.',
              },
            ],
          },
        ),
      );

      final failure = (await repo().createStore(
        _draft,
      )).getLeft().toNullable()!;

      expect(
        VendorStoreFormErrors.fromFailure(failure).city,
        'City is required.',
      );
    });

    test('update and archive send fresh keys; archive returns unit', () async {
      when(
        () => remote.updateStore(
          storeId: any(named: 'storeId'),
          draft: any(named: 'draft'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => VendorStoreDto.fromJson(_storeJson()));
      when(
        () => remote.archiveStore(
          storeId: any(named: 'storeId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async {});
      final repository = repo();

      final updated = await repository.updateStore('s-1', _draft);
      final archived = await repository.archiveStore('s-1');

      expect(updated.getRight().toNullable()!.name, 'Mint Thamel');
      expect(archived, right<NetworkExceptions, Unit>(unit));
      final keys = [
        ...verify(
          () => remote.updateStore(
            storeId: 's-1',
            draft: any(named: 'draft'),
            idempotencyKey: captureAny(named: 'idempotencyKey'),
          ),
        ).captured,
        ...verify(
          () => remote.archiveStore(
            storeId: 's-1',
            idempotencyKey: captureAny(named: 'idempotencyKey'),
          ),
        ).captured,
      ];
      expect(keys.toSet(), hasLength(2));
    });

    test('a 404 archive is notFound; offline never calls the API', () async {
      when(
        () => remote.archiveStore(
          storeId: any(named: 'storeId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(dioError(404));

      expect(
        (await repo().archiveStore('s-1')).getLeft().toNullable(),
        const NetworkExceptions.notFound(),
      );

      final offline = await repo(connected: false).getStores();
      expect(
        offline.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
      verifyNever(() => remote.getStores(cursor: any(named: 'cursor')));
    });
  });
}
