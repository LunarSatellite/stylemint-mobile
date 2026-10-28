import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/datasources/vendor_orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_return_request_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/repositories/vendor_orders_repository_impl.dart';

Map<String, dynamic> _completedReturn({bool? restocked}) => {
  'id': 'return-42',
  'orderId': 'order-1',
  'subOrderId': 'sub-1',
  'subOrderLineId': 'line-1',
  'state': 4,
  'submittedUtc': '2026-09-17T10:00:00Z',
  'restocked': ?restocked,
};

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({this.restocked}) : super(dio: Dio());

  final bool? restocked;
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
    return _completedReturn(restocked: restocked);
  }
}

class _Online implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

void main() {
  group('completeReturn datasource', () {
    test('posts the idempotent endpoint with restock true', () async {
      final api = _RecordingApiClient();
      final source = VendorOrdersRemoteDataSource(apiClient: api);

      final result = await source.completeReturn('return-42', 'idem-return-42');

      expect(api.postUri, '/v1/vendor/returns/return-42/complete');
      expect(api.postData, {'restock': true});
      expect(api.postOptions?.headers?['requiresToken'], isTrue);
      expect(api.postOptions?.headers?['Idempotency-Key'], 'idem-return-42');
      expect(result['state'], 4);
    });

    test('sends restock false when the item cannot be sold again', () async {
      final api = _RecordingApiClient();
      final source = VendorOrdersRemoteDataSource(apiClient: api);

      await source.completeReturn('return-42', 'idem', restock: false);

      expect(api.postData, {'restock': false});
    });
  });

  group('completeReturn repository', () {
    VendorOrdersRepositoryImpl repositoryOver(_RecordingApiClient api) =>
        VendorOrdersRepositoryImpl(
          remoteDataSource: VendorOrdersRemoteDataSource(apiClient: api),
          networkInfo: _Online(),
        );

    test('passes the restock choice through and reads it back', () async {
      final api = _RecordingApiClient(restocked: false);

      final result = await repositoryOver(
        api,
      ).completeReturn('return-42', restock: false);

      expect(api.postData, {'restock': false});
      expect(api.postOptions?.headers?['Idempotency-Key'], isNotEmpty);
      final request = result.getOrElse((_) => throw StateError('left'));
      expect(request.restocked, isFalse);
    });

    test('restocks when no choice is given', () async {
      final api = _RecordingApiClient(restocked: true);

      final result = await repositoryOver(api).completeReturn('return-42');

      expect(api.postData, {'restock': true});
      expect(
        result.getOrElse((_) => throw StateError('left')).restocked,
        isTrue,
      );
    });
  });

  group('VendorReturnRequestDto.restocked', () {
    test('is parsed when present', () {
      expect(
        VendorReturnRequestDto.fromJson(
          _completedReturn(restocked: true),
        ).toDomain().restocked,
        isTrue,
      );
    });

    test('is null when the server does not send it', () {
      final request = VendorReturnRequestDto.fromJson(
        _completedReturn(),
      ).toDomain();

      expect(request.restocked, isNull);
    });
  });
}
