import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/models/code_dto.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/data/datasources/vendor_codes_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/data/models/code_stats_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/data/repositories/vendor_codes_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/repositories/vendor_codes_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/print/shelf_card_pdf.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/print/store_shelf_cards.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/repositories/vendor_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

import '../../codes/support/recording_api_client.dart';

Map<String, dynamic> _codeJson({
  String code = 'ABCD2345',
  Object? kind = 'ProductTag',
  Object? status = 'Active',
  String? productId = 'p-1',
  String? productName = 'Linen shirt',
}) => <String, dynamic>{
  'code': code,
  'kind': kind,
  'status': status,
  'url': 'https://stylemint.voyageritnepal.com/c/$code',
  'productId': productId,
  'productName': productName,
  'storeId': 's-1',
  'storeName': 'Mint Thamel',
  'scanCount': 3,
  'createdUtc': '2026-09-15T08:00:00Z',
};

StyleMintCodeInfo _code(
  String code, {
  String? productId = 'p-1',
  String? productName,
  CodeStatus status = CodeStatus.active,
}) => StyleMintCodeInfo(
  code: code,
  kind: CodeKind.productTag,
  status: status,
  url: 'https://stylemint.voyageritnepal.com/c/$code',
  productId: productId,
  productName: productName,
  storeId: 's-1',
);

VendorProduct _product(String id, String name, double price) => VendorProduct(
  id: id,
  variantId: 'v-$id',
  name: name,
  imageUrl: '',
  price: Money(amount: price, currency: 'NPR'),
  stockCount: 4,
  status: VendorProductStatus.active,
  rating: 4.2,
  createdAt: DateTime(2026, 9),
);

const _store = VendorStore(
  id: 's-1',
  name: 'Mint Thamel',
  addressLine: 'Thamel Marg 12',
  city: 'Kathmandu',
);

class _MockRemote extends Mock implements VendorCodesRemoteDataSource {}

class _MockCodes extends Mock implements VendorCodesRepository {}

class _MockProducts extends Mock implements VendorProductsRepository {}

void main() {
  setUpAll(() => registerFallbackValue(CodeKind.productTag));

  group('CodeStatsDto', () {
    test('maps every CodeStatsVm field', () {
      final stats = CodeStatsDto.fromJson(<String, dynamic>{
        'code': 'abcd2345',
        'totalScans': 12,
        'scansLast7Days': 5,
        'scansLast30Days': 9,
        'uniqueScanners': 7,
        'lastScannedUtc': '2026-09-14T18:30:00Z',
      }).toDomain();

      expect(stats.code, 'ABCD2345');
      expect(stats.totalScans, 12);
      expect(stats.scansLast7Days, 5);
      expect(stats.scansLast30Days, 9);
      expect(stats.uniqueScanners, 7);
      expect(stats.lastScannedUtc, DateTime.utc(2026, 9, 14, 18, 30));
    });

    test('a never-scanned code reads as zeros', () {
      final stats = CodeStatsDto.fromJson(<String, dynamic>{
        'code': 'ABCD2345',
        'totalScans': '0',
      }).toDomain();

      expect(stats.totalScans, 0);
      expect(stats.uniqueScanners, 0);
      expect(stats.lastScannedUtc, isNull);
    });
  });

  group('VendorCodesRemoteDataSource', () {
    test('creates a product tag with kind, product and store', () async {
      final api = RecordingApiClient((_) => _codeJson());

      final dto = await VendorCodesRemoteDataSource(apiClient: api).createCode(
        kind: CodeKind.productTag,
        productId: 'p-1',
        storeId: 's-1',
        idempotencyKey: 'k-1',
      );

      expect(api.last.method, 'POST');
      expect(api.last.uri, '/v1/vendor/codes');
      expect(api.last.data, <String, dynamic>{
        'kind': 'ProductTag',
        'productId': 'p-1',
        'storeId': 's-1',
      });
      expect(api.last.header('Idempotency-Key'), 'k-1');
      expect(api.last.header('requiresToken'), isTrue);
      expect(dto.productName, 'Linen shirt');
    });

    test('a store code has no product id', () async {
      final api = RecordingApiClient(
        (_) => _codeJson(kind: 'Store', productId: null, productName: null),
      );

      await VendorCodesRemoteDataSource(apiClient: api).createCode(
        kind: CodeKind.store,
        storeId: 's-1',
        idempotencyKey: 'k-2',
      );

      expect(api.last.data, <String, dynamic>{
        'kind': 'Store',
        'storeId': 's-1',
      });
    });

    test('lists by store and kind, then revokes and reads stats', () async {
      final api = RecordingApiClient((call) {
        if (call.uri.endsWith('/stats')) {
          return <String, dynamic>{'code': 'ABCD2345', 'totalScans': 4};
        }
        if (call.uri.endsWith('/revoke')) return _codeJson(status: 'Revoked');
        return <String, dynamic>{
          'items': [_codeJson(), _codeJson(code: '7K9M2PQR')],
          'nextCursor': 'c-2',
        };
      });
      final source = VendorCodesRemoteDataSource(apiClient: api);

      final page = await source.listCodes(
        storeId: 's-1',
        kind: CodeKind.productTag,
      );
      final revoked = await source.revoke(
        code: 'ABCD2345',
        idempotencyKey: 'k-3',
      );
      final stats = await source.getStats('ABCD2345');

      expect(api.calls.first.query, <String, dynamic>{
        'storeId': 's-1',
        'kind': 'ProductTag',
        'pageSize': 50,
      });
      expect(page.codes.map((c) => c.code), ['ABCD2345', '7K9M2PQR']);
      expect(page.nextCursor, 'c-2');
      expect(api.calls[1].uri, '/v1/vendor/codes/ABCD2345/revoke');
      expect(api.calls[1].header('Idempotency-Key'), 'k-3');
      expect(revoked.status, CodeStatus.revoked);
      expect(api.calls[2].method, 'GET');
      expect(api.calls[2].uri, '/v1/vendor/codes/ABCD2345/stats');
      expect(stats.totalScans, 4);
    });
  });

  group('VendorCodesRepositoryImpl', () {
    late _MockRemote remote;

    setUp(() => remote = _MockRemote());

    VendorCodesRepositoryImpl repo({bool connected = true}) =>
        VendorCodesRepositoryImpl(
          remoteDataSource: remote,
          networkInfo: FakeNetworkInfo(connected: connected),
        );

    test('lists every page of a store', () async {
      when(
        () => remote.listCodes(storeId: 's-1', kind: CodeKind.productTag),
      ).thenAnswer(
        (_) async => (
          codes: [CodeDto.fromJson(_codeJson())],
          nextCursor: 'c-2',
        ),
      );
      when(
        () => remote.listCodes(
          storeId: 's-1',
          kind: CodeKind.productTag,
          cursor: 'c-2',
        ),
      ).thenAnswer(
        (_) async => (
          codes: [CodeDto.fromJson(_codeJson(code: '7K9M2PQR'))],
          nextCursor: null,
        ),
      );

      final result = await repo().listStoreCodes(
        's-1',
        kind: CodeKind.productTag,
      );

      expect(result.getRight().toNullable()!.map((c) => c.code), [
        'ABCD2345',
        '7K9M2PQR',
      ]);
    });

    test('product tags and store codes ask for their kind', () async {
      when(
        () => remote.createCode(
          kind: any(named: 'kind'),
          storeId: any(named: 'storeId'),
          productId: any(named: 'productId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => CodeDto.fromJson(_codeJson()));
      final repository = repo();

      await repository.createProductTag(productId: 'p-1', storeId: 's-1');
      await repository.createStoreCode('s-1');

      verify(
        () => remote.createCode(
          kind: CodeKind.productTag,
          storeId: 's-1',
          productId: 'p-1',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
      verify(
        () => remote.createCode(
          kind: CodeKind.store,
          storeId: 's-1',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
    });

    test('a revoked or foreign code is notFound; 5xx and offline', () async {
      when(
        () => remote.revoke(
          code: any(named: 'code'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(dioError(404));
      when(() => remote.getStats(any())).thenThrow(dioError(502));

      expect(
        (await repo().revoke('ABCD2345')).getLeft().toNullable(),
        const NetworkExceptions.notFound(),
      );
      expect(
        (await repo().getStats('ABCD2345')).getLeft().toNullable(),
        const NetworkExceptions.serverUnavailable(),
      );
      expect(
        (await repo(
          connected: false,
        ).getStats('ABCD2345')).getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
    });
  });

  group('loadStoreShelfCards', () {
    late _MockCodes codes;
    late _MockProducts products;

    setUp(() {
      codes = _MockCodes();
      products = _MockProducts();
    });

    test('one card per active product code, priced from products', () async {
      when(
        () => codes.listStoreCodes('s-1', kind: CodeKind.productTag),
      ).thenAnswer(
        (_) async => right([
          _code('ABCD2345', productName: 'Linen shirt'),
          _code('7K9M2PQR', productId: 'p-2', status: CodeStatus.revoked),
          _code('QRST6789', productId: 'p-3'),
        ]),
      );
      when(() => products.getProducts(limit: 50)).thenAnswer(
        (_) async => right(
          PagedResult<VendorProduct>(
            items: [
              _product('p-1', 'Linen shirt', 2499),
              _product('p-3', 'Canvas tote', 1200),
            ],
            totalCount: 2,
            pageSize: 50,
            hasMore: false,
          ),
        ),
      );

      final cards = (await loadStoreShelfCards(
        codes: codes,
        products: products,
        store: _store,
      )).getRight().toNullable()!;

      expect(cards.map((c) => c.code), ['ABCD2345', 'QRST6789']);
      expect(cards.first.title, 'Linen shirt');
      expect(cards.first.price, 'Rs 2,499.00');
      expect(cards.last.title, 'Canvas tote');
      expect(cards.last.price, 'Rs 1,200.00');
      expect(cards.every((c) => c.storeName == 'Mint Thamel'), isTrue);
      expect(cards.first.storeCity, 'Kathmandu');
    });

    test('no active codes means no cards and no product lookup', () async {
      when(
        () => codes.listStoreCodes('s-1', kind: CodeKind.productTag),
      ).thenAnswer((_) async => right(const []));

      final result = await loadStoreShelfCards(
        codes: codes,
        products: products,
        store: _store,
      );

      expect(result.getRight().toNullable(), isEmpty);
      verifyNever(() => products.getProducts(limit: any(named: 'limit')));
    });

    test('a failed product list still prints cards, without prices', () async {
      when(
        () => codes.listStoreCodes('s-1', kind: CodeKind.productTag),
      ).thenAnswer(
        (_) async => right([_code('ABCD2345', productName: 'Linen shirt')]),
      );
      when(
        () => products.getProducts(limit: 50),
      ).thenAnswer(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );

      final cards = (await loadStoreShelfCards(
        codes: codes,
        products: products,
        store: _store,
      )).getRight().toNullable()!;

      expect(cards.single.title, 'Linen shirt');
      expect(cards.single.price, isNull);
    });

    test('a failed code list is passed on', () async {
      when(
        () => codes.listStoreCodes('s-1', kind: CodeKind.productTag),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      final result = await loadStoreShelfCards(
        codes: codes,
        products: products,
        store: _store,
      );

      expect(result.getLeft().toNullable(), const NetworkExceptions.notFound());
    });
  });

  group('ShelfCardPdf', () {
    const card = ShelfCardData(
      title: 'Linen shirt',
      url: 'https://stylemint.voyageritnepal.com/c/ABCD2345',
      code: 'ABCD2345',
      storeName: 'Mint Thamel',
      storeCity: 'Kathmandu',
      price: 'Rs 2,499.00',
    );

    test('a single A6 card and a sheet of cards are PDFs', () async {
      final mark = File('assets/branding/stylemint-mark.png').readAsBytesSync();

      final single = await ShelfCardPdf.single(card, markPng: mark);
      final sheets = await ShelfCardPdf.sheets(
        List.filled(5, card),
        markPng: mark,
      );

      expect(String.fromCharCodes(single.take(5)), '%PDF-');
      expect(String.fromCharCodes(sheets.take(5)), '%PDF-');
      expect(sheets.length, greaterThan(single.length));
    });

    test('text outside Latin-1 cannot break the file', () {
      expect(ShelfCardPdf.latin1Safe('“Kurta” – Café'), '"Kurta" - Café');
      expect(ShelfCardPdf.latin1Safe('नमस्ते'), '??????');
    });
  });
}
