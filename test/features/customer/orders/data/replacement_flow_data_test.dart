import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';

class _Api extends ApiClient {
  _Api() : super(dio: Dio());

  String? getUri;
  String? postUri;
  Object? postData;
  Options? postOptions;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
    return <dynamic>[
      <String, dynamic>{
        'variantId': 'variant-blue-m',
        'label': 'BLUE-M',
        'priceAmount': 1150,
        'priceCurrency': 'NPR',
      },
    ];
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    postOptions = options;
    return <String, dynamic>{'id': 'return-1'};
  }
}

void main() {
  test('loads server-owned sibling replacement options', () async {
    final api = _Api();
    final source = OrdersRemoteDataSource(apiClient: api);

    final options = await source.getReplacementOptions('variant-original');

    expect(api.getUri, '/v1/orders/replacement-options/variant-original');
    expect(options.single.variantId, 'variant-blue-m');
    expect(options.single.price.amount, 1150);
  });

  test(
    'replacement submission sends resolution, variant and idempotency',
    () async {
      final api = _Api();
      final source = OrdersRemoteDataSource(apiClient: api);

      final id = await source.requestReturn(
        'NK2026-1',
        'sub-1',
        'line-1',
        1,
        'Need a different size',
        <String>['https://cdn.example/evidence.jpg'],
        2,
        'variant-blue-m',
        'idem-1',
      );

      expect(id, 'return-1');
      expect(api.postUri, '/v1/orders/NK2026-1/returns');
      expect(api.postData, containsPair('resolution', 2));
      expect(
        api.postData,
        containsPair('replacementVariantId', 'variant-blue-m'),
      );
      expect(api.postOptions?.headers?['Idempotency-Key'], 'idem-1');
    },
  );
}
