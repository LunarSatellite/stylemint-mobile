import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/delivery_confirmation_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_delivery_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/repositories/delivery_confirmation_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/delivery_confirm_link.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/scan/domain/style_mint_code.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

const _qr = 'https://stylemint.voyageritnepal.com/dc/tok_9f8e7d6c5b4a';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.postBody, this.error}) : super(dio: Dio());

  final Object? postBody;
  final DioException? error;
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
    if (error != null) throw error!;
    return postBody;
  }
}

class _Network implements NetworkInfoConnectivity {
  _Network({required this.connected});

  final bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

DioException _dioError(int status, {Object? body}) {
  final options = RequestOptions(path: '/v1/customer/deliveries/confirm');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

Map<String, dynamic> _problem(String code) => {
  'title': 'Unprocessable',
  'detail': 'Server words',
  'errorCode': code,
};

const _confirmedBody = {
  'orderId': 'order-1',
  'subOrderId': 'sub-1',
  'packageNumber': 'SM-D-00000013',
  'status': 'Delivered',
  'deliveredUtc': '2026-10-09T08:40:00Z',
};

DeliveryConfirmationRepositoryImpl _repository(
  _FakeApiClient api, {
  bool connected = true,
}) => DeliveryConfirmationRepositoryImpl(
  remoteDataSource: DeliveryConfirmationRemoteDataSource(apiClient: api),
  networkInfo: _Network(connected: connected),
);

void main() {
  group('OrderDeliveryJson', () {
    test('reads the delivery block', () {
      final delivery = OrderDeliveryJson.parse({
        'packageNumber': 'SM-D-00000013',
        'status': 'AwaitingConfirmation',
        'riderName': 'Ram',
        'awaitingConfirmation': true,
      })!;
      expect(delivery.packageNumber, 'SM-D-00000013');
      expect(delivery.riderName, 'Ram');
      expect(delivery.awaitingConfirmation, isTrue);
      expect(delivery.isOutForDelivery, isTrue);
      expect(delivery.isDelivered, isFalse);
    });

    test('absent or not an object is no delivery', () {
      expect(OrderDeliveryJson.fromOrder({'id': 'o'}), isNull);
      expect(OrderDeliveryJson.parse('Delivered'), isNull);
    });

    test('a sub-order waiting on the buyer wins over the order level', () {
      final delivery = OrderDeliveryJson.fromOrder({
        'delivery': {'packageNumber': 'SM-D-1', 'status': 'PickedUp'},
        'subOrders': [
          {
            'id': 'sub-a',
            'delivery': {
              'packageNumber': 'SM-D-2',
              'status': 'InTransit',
              'awaitingConfirmation': false,
            },
          },
          {
            'id': 'sub-b',
            'delivery': {
              'packageNumber': 'SM-D-3',
              'status': 'AwaitingConfirmation',
              'awaitingConfirmation': true,
            },
          },
        ],
      })!;
      expect(delivery.packageNumber, 'SM-D-3');
      expect(delivery.subOrderId, 'sub-b');
      expect(delivery.awaitingConfirmation, isTrue);
    });

    test('order detail carries it through to the domain', () {
      final dto = OrderDetailDto.fromJson({
        'id': 'order-1',
        'orderNumber': 'NK2026-00015',
        'state': 3,
        'placedUtc': '2026-10-01T00:00:00Z',
        'subOrders': [
          {'id': 'sub-1', 'state': 11, 'lines': <Object>[]},
        ],
      });
      final delivery = OrderDeliveryJson.parse({
        'packageNumber': 'SM-D-1',
        'status': 'AwaitingConfirmation',
        'awaitingConfirmation': true,
      });
      final order = dto.toDomain(delivery: delivery);
      expect(order.delivery?.awaitingConfirmation, isTrue);
      expect(order.status, OrderTrackStatus.inTransit);
      expect(order.copyWith(canReturn: true).delivery, same(order.delivery));
    });

    test('every sub-order delivered reads as a delivered order', () {
      final dto = OrderDetailDto.fromJson({
        'id': 'order-1',
        'orderNumber': 'NK2026-00015',
        'state': 3,
        'placedUtc': '2026-10-01T00:00:00Z',
        'subOrders': [
          {'id': 'sub-1', 'state': 7, 'lines': <Object>[]},
        ],
      });
      final order = dto.toDomain();
      expect(order.status, OrderTrackStatus.delivered);
      expect(order.canReturn, isTrue);
    });
  });

  group('DeliveryConfirmLink', () {
    test('reads the token from the rider QR, on any StyleMint host', () {
      expect(DeliveryConfirmLink.token(_qr), 'tok_9f8e7d6c5b4a');
      expect(
        DeliveryConfirmLink.token('stylemint://dc/tok_9f8e7d6c5b4a'),
        'tok_9f8e7d6c5b4a',
      );
    });

    test('anything else is not a delivery QR', () {
      expect(DeliveryConfirmLink.token('https://evil.example/dc/tok_123456'),
          isNull);
      expect(
        DeliveryConfirmLink.token(
          'https://stylemint.voyageritnepal.com/c/ABCD2345',
        ),
        isNull,
      );
      expect(DeliveryConfirmLink.token('SM-D-00000013'), isNull);
      expect(DeliveryConfirmLink.token(null), isNull);
    });

    test('rebuilds the canonical payload from a token', () {
      expect(DeliveryConfirmLink.payloadFor('tok_9f8e7d6c5b4a'), _qr);
    });

    test("the Scan tab opens it as 'Confirm delivery'", () {
      final code = StyleMintCode.parse(_qr);
      expect(code, isA<StyleMintLinkCode>());
      expect(
        (code! as StyleMintLinkCode).route,
        RouteNames.deliveryConfirmPath('tok_9f8e7d6c5b4a'),
      );
    });
  });

  group('DeliveryConfirmationRepositoryImpl', () {
    test('posts the QR payload with an Idempotency-Key', () async {
      final api = _FakeApiClient(postBody: _confirmedBody);
      final result = await _repository(api).confirmByQr(_qr);

      expect(api.postUri, '/v1/customer/deliveries/confirm');
      expect(api.postData, {'qrPayload': _qr});
      expect(api.postOptions?.headers?['Idempotency-Key'], isNotEmpty);
      expect(api.postOptions?.headers?['requiresToken'], isTrue);
      final confirmation = result.getOrElse((_) => throw StateError('left'));
      expect(confirmation.orderId, 'order-1');
      expect(confirmation.subOrderId, 'sub-1');
      expect(confirmation.packageNumber, 'SM-D-00000013');
      expect(confirmation.status, 'Delivered');
      expect(confirmation.deliveredUtc, DateTime.utc(2026, 10, 9, 8, 40));
    });

    test('posts the package number and code', () async {
      final api = _FakeApiClient(postBody: _confirmedBody);
      await _repository(
        api,
      ).confirmByCode(packageNumber: 'SM-D-00000013', code: '482913');
      expect(api.postData, {'packageNumber': 'SM-D-00000013', 'code': '482913'});
    });

    test('each contract error code is its own failure', () async {
      Future<DeliveryConfirmFailure?> failureFor(int status, String code) async {
        final api = _FakeApiClient(error: _dioError(status, body: _problem(code)));
        final result = await _repository(api).confirmByQr(_qr);
        return result.fold((f) => f, (_) => null);
      }

      expect(
        await failureFor(403, 'delivery_proof.not_recipient'),
        isA<DeliveryConfirmNotRecipient>(),
      );
      expect(
        await failureFor(422, 'delivery_proof.expired'),
        isA<DeliveryConfirmExpired>(),
      );
      expect(
        await failureFor(422, 'delivery_proof.invalid'),
        isA<DeliveryConfirmInvalid>(),
      );
      expect(
        await failureFor(429, 'delivery_proof.too_many_attempts'),
        isA<DeliveryConfirmTooManyAttempts>(),
      );
      expect(
        await failureFor(409, 'delivery_proof.already_confirmed'),
        isA<DeliveryConfirmAlreadyConfirmed>(),
      );
    });

    test('a 403 without a code is still "not your parcel"', () {
      expect(
        DeliveryConfirmationRepositoryImpl.failureFromDio(_dioError(403)),
        isA<DeliveryConfirmNotRecipient>(),
      );
    });

    test('a 5xx never shows the server body', () {
      final failure = DeliveryConfirmationRepositoryImpl.failureFromDio(
        _dioError(502, body: {'detail': '<html>Bad gateway</html>'}),
      );
      expect(failure, isA<DeliveryConfirmOtherFailure>());
      expect((failure as DeliveryConfirmOtherFailure).message, isNull);
    });

    test('offline sends nothing', () async {
      final api = _FakeApiClient(postBody: _confirmedBody);
      final result = await _repository(api, connected: false).confirmByQr(_qr);
      expect(api.postUri, isNull);
      expect(
        result.fold((f) => f, (_) => null),
        isA<DeliveryConfirmOtherFailure>().having(
          (f) => f.offline,
          'offline',
          isTrue,
        ),
      );
    });
  });
}
