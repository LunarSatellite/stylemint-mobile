import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';

class _PostApiClient extends ApiClient {
  _PostApiClient(this.body) : super(dio: Dio());
  final Object? body;
  String? uri;
  Object? posted;

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.uri = uri;
    posted = data;
    return body;
  }
}

class _CapabilityApiClient extends ApiClient {
  _CapabilityApiClient(this.body) : super(dio: Dio());
  final Object? body;
  String? uri;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.uri = uri;
    return body;
  }
}

void main() {
  test('visual capability is true only for explicit server true', () async {
    final enabled = _CapabilityApiClient({'available': true});
    final disabled = _CapabilityApiClient({'available': false});

    expect(
      await CustomerSearchRemoteDataSource(
        apiClient: enabled,
      ).isVisualSearchAvailable(),
      isTrue,
    );
    expect(enabled.uri, '/api/v1/customer/search/image/capability');
    expect(
      await CustomerSearchRemoteDataSource(
        apiClient: disabled,
      ).isVisualSearchAvailable(),
      isFalse,
    );
  });
  test('visual search posts image data and maps full product DTO', () async {
    final api = _PostApiClient([
      {
        'id': 'product-1',
        'name': 'Navy Oxford Shirt',
        'averageRating': 4.7,
        'images': [
          {'cdnUrl': 'https://cdn.test/secondary.jpg', 'isPrimary': false},
          {'cdnUrl': 'https://cdn.test/hero.jpg', 'isPrimary': true},
        ],
        'variants': [
          {'priceAmount': 2100, 'priceCurrency': 'NPR', 'isDefault': false},
          {'priceAmount': 2400, 'priceCurrency': 'NPR', 'isDefault': true},
        ],
      },
    ]);

    final results = await CustomerSearchRemoteDataSource(
      apiClient: api,
    ).searchByImage('data:image/jpeg;base64,YQ==', limit: 12);

    expect(api.uri, '/api/v1/customer/search/image');
    expect(api.posted, {
      'imageUrl': 'data:image/jpeg;base64,YQ==',
      'limit': 12,
    });
    expect(results.totalHits, 1);
    expect(results.products.single.productId, 'product-1');
    expect(results.products.single.heroImageUrl, 'https://cdn.test/hero.jpg');
    expect(results.products.single.price, 2400);
    expect(results.products.single.currency, 'NPR');
    expect(results.products.single.matchReason, 'Visually similar');
  });

  test('video frame search merges duplicate products across frames', () async {
    final api = _PostApiClient([
      {'id': 'product-video', 'name': 'Recognized jacket'},
    ]);

    final results =
        await CustomerSearchRemoteDataSource(
          apiClient: api,
        ).searchByImages([
          'data:image/jpeg;base64,YQ==',
          'data:image/jpeg;base64,Yg==',
          'data:image/jpeg;base64,Yw==',
        ]);

    expect(api.uri, '/api/v1/customer/search/multimodal');
    expect(api.posted, {
      'imageUrls': [
        'data:image/jpeg;base64,YQ==',
        'data:image/jpeg;base64,Yg==',
        'data:image/jpeg;base64,Yw==',
      ],
      'limit': 20,
    });
    expect(results.products, hasLength(1));
    expect(results.products.single.productId, 'product-video');
    expect(results.queryUnderstanding, 'Products recognized across your video');
  });
  test('visual search safely maps empty variants and images', () async {
    final api = _PostApiClient([
      {'id': 'product-2', 'name': 'Unknown item'},
    ]);

    final results = await CustomerSearchRemoteDataSource(
      apiClient: api,
    ).searchByImage('data:image/png;base64,Yg==');

    expect(results.products.single.price, 0);
    expect(results.products.single.heroImageUrl, isEmpty);
    expect(results.products.single.currency, 'NPR');
  });
}
