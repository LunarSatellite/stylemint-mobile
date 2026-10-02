import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/datasources/mall_catalog_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/catalog_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/repositories/mall_catalog_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';

class _Network implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

/// Serves one fixed listing page and one fixed collection, so the only thing
/// under test is what the repository hands back.
class _Remote implements MallCatalogRemoteDataSource {
  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<CatalogProductPageDto> getProducts(
    Map<String, dynamic> query, {
    required int pageSize,
    String? cursor,
  }) async => CatalogProductPageDto.fromJson({
    'items': [
      _card('p-physical', 'Canvas tote', ProductKinds.physical),
      _card('p-digital', 'Preset pack', ProductKinds.digital),
      _card('p-sub', 'Styling club', ProductKinds.subscription),
      _card('p-service', 'Tailoring visit', ProductKinds.service),
      _card('p-unknown', 'Older payload', null),
    ],
    'nextCursor': 'cursor-2',
    'hasMore': true,
    'totalCount': 5,
  });

  @override
  Future<CollectionDetailDto> getCollection(
    String slug, {
    required int pageSize,
    String? cursor,
  }) async => CollectionDetailDto.fromJson({
    'id': 'c1',
    'slug': slug,
    'title': 'The drop',
    'kind': 1,
    'itemCount': 2,
    'items': {
      'items': [
        {
          'product': _card('p-physical', 'Canvas tote', ProductKinds.physical),
        },
        {'product': _card('p-digital', 'Preset pack', ProductKinds.digital)},
      ],
      'nextCursor': null,
      'totalCount': 2,
    },
  });
}

Map<String, dynamic> _card(String id, String name, int? kind) => {
  'id': id,
  'name': name,
  'state': 1,
  'variants': [
    {
      'isDefault': true,
      'priceAmount': 1200,
      'priceCurrency': 'NPR',
      'quantityOnHand': 9,
      if (kind != null) 'productKind': kind,
    },
  ],
};

MallCatalogRepositoryImpl repositoryWith(DigitalGoodsPolicy policy) =>
    MallCatalogRepositoryImpl(
      remoteDataSource: _Remote(),
      networkInfo: _Network(),
      digitalGoodsPolicy: policy,
    );

void main() {
  const blocked = DigitalGoodsPolicy.blockedBy(StoreBillingRule.googlePlay);
  const allowed = DigitalGoodsPolicy.allowed();

  test('a blocked build drops kinds 2 and 4 from the listing', () async {
    final page = (await repositoryWith(
      blocked,
    ).getProducts(const ProductListingQuery())).getRight().toNullable()!;

    expect(page.items.map((p) => p.id), [
      'p-physical',
      'p-service',
      'p-unknown',
    ]);
  });

  test('the cursor and total count stay the server\'s', () async {
    // The server still holds and counts those rows; paging follows the
    // cursor, not the filtered item count.
    final page = (await repositoryWith(
      blocked,
    ).getProducts(const ProductListingQuery())).getRight().toNullable()!;

    expect(page.nextCursor, 'cursor-2');
    expect(page.totalCount, 5);
    expect(page.hasMore, isTrue);
  });

  test('an allowed build returns every kind', () async {
    final page = (await repositoryWith(
      allowed,
    ).getProducts(const ProductListingQuery())).getRight().toNullable()!;

    expect(page.items.length, 5);
    expect(page.items.map((p) => p.id), contains('p-digital'));
    expect(page.items.map((p) => p.id), contains('p-sub'));
  });

  test('a blocked build drops digital items from a collection', () async {
    final detail = (await repositoryWith(
      blocked,
    ).getCollection('the-drop')).getRight().toNullable()!;

    expect(detail.items.items.map((i) => i.product.id), ['p-physical']);
    expect(detail.title, 'The drop');
  });

  test('an allowed build keeps every collection item', () async {
    final detail = (await repositoryWith(
      allowed,
    ).getCollection('the-drop')).getRight().toNullable()!;

    expect(detail.items.items.length, 2);
  });

  test('the repository allows digital goods unless told otherwise', () async {
    // The default keeps every existing construction site — and every test —
    // behaving as it did; only the provider turns the gate on.
    final repository = MallCatalogRepositoryImpl(
      remoteDataSource: _Remote(),
      networkInfo: _Network(),
    );

    final page = (await repository.getProducts(
      const ProductListingQuery(),
    )).getRight().toNullable()!;

    expect(page.items.length, 5);
  });
}
