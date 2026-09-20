import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/datasources/vendor_orders_remote_datasource.dart';

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(dio: Dio());

  String? postUri;
  Object? postData;
  Options? postOptions;

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
    return <String, dynamic>{
      'id': 'return-42',
      'orderId': 'order-1',
      'subOrderId': 'sub-1',
      'subOrderLineId': 'line-1',
      'state': 4,
      'submittedUtc': '2026-09-17T10:00:00Z',
    };
  }
}

void main() {
  test('completeReturn posts the guarded idempotent vendor endpoint', () async {
    final api = _RecordingApiClient();
    final source = VendorOrdersRemoteDataSource(apiClient: api);

    final result = await source.completeReturn('return-42', 'idem-return-42');

    expect(api.postUri, '/v1/vendor/returns/return-42/complete');
    expect(api.postData, isNull);
    expect(api.postOptions?.headers?['requiresToken'], isTrue);
    expect(api.postOptions?.headers?['Idempotency-Key'], 'idem-return-42');
    expect(result['state'], 4);
  });
}
