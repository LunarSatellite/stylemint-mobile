import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/datasources/in_store_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/models/store_product_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/repositories/in_store_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/notifiers/store_products_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../codes/support/recording_api_client.dart';

/// A list-row `ProductDto` as `GET /v1/public/vendors/{id}/products` sends
/// it: the default variant and primary image only.
Map<String, dynamic> _productJson({
  String id = 'p-1',
  Map<String, dynamic>? activeFlashSale,
}) => <String, dynamic>{
  'id': id,
  'vendorAccountId': 'v-1',
  'vendorDisplayName': null,
  'categoryId': 'c-1',
  'name': 'Linen shirt',
  'shortDescription': 'Breathable linen.',
  'state': 2,
  'averageRating': 4.5,
  'reviewCount': 12,
  'createdUtc': '2026-09-01T09:00:00+00:00',
  'variants': [
    <String, dynamic>{
      'id': 'var-1',
      'productId': id,
      'sku': 'LINEN-1',
      'isDefault': true,
      'priceAmount': 2499.0,
      'priceCurrency': 'NPR',
      'quantityOnHand': 7,
    },
  ],
  'images': [
    <String, dynamic>{
      'id': 'img-1',
      'productId': id,
      'cdnUrl': 'https://cdn.stylemint.app/products/cover.jpg',
      'sortOrder': 0,
      'isPrimary': true,
    },
  ],
  'video': null,
  'shippingOptions': <Object>[],
  'activeFlashSale': activeFlashSale,
};

Map<String, dynamic> _page(List<Map<String, dynamic>> items, String? next) =>
    <String, dynamic>{
      'items': items,
      'totalCount': 3,
      'nextCursor': next,
      'previousCursor': null,
      'pageSize': 20,
    };

StoreProduct _product(String id) => StoreProduct(
  id: id,
  name: 'Product $id',
  price: const Money(amount: 1000, currency: 'NPR'),
);

class _MockRemote extends Mock implements InStoreRemoteDataSource {}

/// Answers each page from [pages] by cursor, in order; the last repeats.
class _PagedRepository implements InStoreRepository {
  _PagedRepository(this.pages);

  final Map<String?, List<Either<NetworkExceptions, StoreProductsPage>>> pages;
  final List<String?> cursors = [];

  @override
  Future<Either<NetworkExceptions, StoreProductsPage>> getVendorProducts(
    String vendorAccountId, {
    String? cursor,
  }) async {
    cursors.add(cursor);
    final answers = pages[cursor]!;
    return answers.length > 1 ? answers.removeAt(0) : answers.single;
  }

  @override
  Future<Either<NetworkExceptions, List<ProductReel>>> getProductReels(
    String productId,
  ) async => right(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('StoreProductDto', () {
    test('maps the list ProductDto to a product card', () {
      final product = StoreProductDto.fromJson(_productJson()).toDomain();

      expect(product.id, 'p-1');
      expect(product.name, 'Linen shirt');
      expect(product.price, const Money(amount: 2499, currency: 'NPR'));
      expect(product.imageUrl, 'https://cdn.stylemint.app/products/cover.jpg');
    });

    test('a running flash sale shows its sale price', () {
      final product = StoreProductDto.fromJson(
        _productJson(
          activeFlashSale: <String, dynamic>{
            'flashSaleId': 'fs-1',
            'originalPrice': 2499.0,
            'salePrice': 1999.0,
            'currency': 'NPR',
            'endsUtc': '2026-09-20T00:00:00+00:00',
            'unitsLeft': 4,
          },
        ),
      ).toDomain();

      expect(product.price, const Money(amount: 1999, currency: 'NPR'));
    });

    test('without options or photos it reads as zero and no photo', () {
      final product = StoreProductDto.fromJson(<String, dynamic>{
        'id': 'p-2',
        'name': 'Gift card',
      }).toDomain();

      expect(product.price, const Money(amount: 0, currency: 'NPR'));
      expect(product.imageUrl, isEmpty);
    });

    test('pages drop products without an id', () {
      final products = StoreProductDto.listFromPage(
        _page([
          _productJson(),
          <String, dynamic>{'name': 'no id'},
        ], null),
      );

      expect(products.single.id, 'p-1');
      expect(StoreProductDto.listFromPage(null), isEmpty);
    });
  });

  test('the datasource pages the public vendor endpoint by cursor', () async {
    final api = RecordingApiClient(
      (call) => call.query?['cursor'] == 'c-2'
          ? _page([_productJson(id: 'p-3')], null)
          : _page([_productJson(), _productJson(id: 'p-2')], 'c-2'),
    );
    final dataSource = InStoreRemoteDataSource(apiClient: api);

    final first = await dataSource.getVendorProducts('v-1');

    expect(api.last.method, 'GET');
    expect(api.last.uri, '/v1/public/vendors/v-1/products');
    expect(api.last.query, <String, dynamic>{'pageSize': 20});
    expect(first.products.map((p) => p.id), ['p-1', 'p-2']);
    expect(first.nextCursor, 'c-2');

    final second = await dataSource.getVendorProducts(
      'v-1',
      cursor: first.nextCursor,
    );

    expect(api.last.query, <String, dynamic>{'pageSize': 20, 'cursor': 'c-2'});
    expect(second.products.single.id, 'p-3');
    expect(second.nextCursor, isNull);
  });

  group('InStoreRepositoryImpl.getVendorProducts', () {
    late _MockRemote remote;

    setUp(() => remote = _MockRemote());

    InStoreRepositoryImpl repo({bool connected = true}) =>
        InStoreRepositoryImpl(
          remoteDataSource: remote,
          networkInfo: FakeNetworkInfo(connected: connected),
        );

    test('maps a page to the domain and passes the cursor on', () async {
      when(() => remote.getVendorProducts('v-1', cursor: 'c-2')).thenAnswer(
        (_) async => (
          products: [StoreProductDto.fromJson(_productJson())],
          nextCursor: 'c-3',
        ),
      );

      final page = (await repo().getVendorProducts(
        'v-1',
        cursor: 'c-2',
      )).getRight().toNullable()!;

      expect(page.products.single.name, 'Linen shirt');
      expect(page.nextCursor, 'c-3');
    });

    test('a server error is a failure; offline skips the API', () async {
      when(
        () => remote.getVendorProducts('v-1'),
      ).thenThrow(dioError(503));

      expect(
        (await repo().getVendorProducts('v-1')).isLeft(),
        isTrue,
      );

      final offline = await repo(connected: false).getVendorProducts('v-9');
      expect(
        offline.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
      verifyNever(() => remote.getVendorProducts('v-9'));
    });
  });

  group('StoreProductsNotifier', () {
    test(
      'appends pages, keeps products when one fails, stops at the last',
      () async {
        final repository = _PagedRepository({
          null: [
            right((products: [_product('p-1')], nextCursor: 'c-2')),
          ],
          'c-2': [
            left(const NetworkExceptions.serverUnavailable()),
            right((
              products: [_product('p-1'), _product('p-2')],
              nextCursor: null,
            )),
          ],
        });
        final notifier = StoreProductsNotifier(repository, 'v-1');
        addTearDown(notifier.dispose);
        await pumpEventQueue();

        var state = notifier.state as StoreProductsLoaded;
        expect(state.products.map((p) => p.id), ['p-1']);
        expect(state.hasMore, isTrue);

        await notifier.loadMore();
        state = notifier.state as StoreProductsLoaded;
        expect(state.loadMoreFailed, isTrue);
        expect(state.products.map((p) => p.id), ['p-1']);
        expect(state.nextCursor, 'c-2');

        await notifier.loadMore();
        state = notifier.state as StoreProductsLoaded;
        expect(state.loadMoreFailed, isFalse);
        expect(state.products.map((p) => p.id), ['p-1', 'p-2']);
        expect(state.hasMore, isFalse);

        await notifier.loadMore();
        expect(repository.cursors, [null, 'c-2', 'c-2']);
      },
    );

    test('a failed first page can be loaded again', () async {
      final repository = _PagedRepository({
        null: [
          left(const NetworkExceptions.serverUnavailable()),
          right((products: [_product('p-1')], nextCursor: null)),
        ],
      });
      final notifier = StoreProductsNotifier(repository, 'v-1');
      addTearDown(notifier.dispose);
      await pumpEventQueue();

      expect(notifier.state, isA<StoreProductsFailed>());

      await notifier.load();

      expect(
        (notifier.state as StoreProductsLoaded).products.single.id,
        'p-1',
      );
    });
  });
}
