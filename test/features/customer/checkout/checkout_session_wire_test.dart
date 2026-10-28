import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';

// Order only after payment, at the wire: what Place Order and
// `GET /v1/checkout/sessions/{id}` say, read the way the app reads them.

const _sessionId = '7d1c0f2e-5b9a-4c33-9e61-0a4f8b2d9c17';

/// Answers checkout's calls from canned bodies and records what was asked.
class _CheckoutApi implements ApiClient {
  _CheckoutApi({this.placeReply = const {}, this.sessionReply = const {}});

  /// The body of `POST /v1/checkout/sessions/{id}/place`.
  final Map<String, dynamic> placeReply;

  /// The body of `GET /v1/checkout/sessions/{id}`.
  final Map<String, dynamic> sessionReply;

  final List<String> posts = [];
  final List<String> gets = [];

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    gets.add(uri);
    return sessionReply;
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    posts.add(uri);
    if (uri == '/v1/checkout/sessions') return {'id': _sessionId};
    if (uri.endsWith('/place')) return placeReply;
    return <String, dynamic>{};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('not used: ${invocation.memberName}');
}

Future<PlaceOrderResult> _place(Map<String, dynamic> reply) =>
    CheckoutRemoteDataSource(
      apiClient: _CheckoutApi(placeReply: reply),
    ).placeOrder(
      addressId: 'addr-1',
      paymentMethod: PaymentMethodType.eSewa,
      idempotencyKey: 'key-1',
    );

void main() {
  group('Place Order reply', () {
    test('an online method: the session, waiting, with no order', () async {
      final placed = await _place({
        'id': _sessionId,
        'status': 6,
        'paymentRequiresAction': true,
        'paymentRedirectUrl': 'https://pay.example.test/esewa',
        'orderId': null,
        'orderNumber': null,
      });
      expect(placed.orderNumber, isNull);
      expect(placed.checkoutSessionId, _sessionId);
      expect(placed.requiresPaymentAction, isTrue);
      expect(placed.paymentRedirectUrl, 'https://pay.example.test/esewa');
      expect(placed.awaitsPaymentBeforeOrder, isTrue);
    });

    test('a reply without its id still names the placed session', () async {
      final placed = await _place({
        'status': 6,
        'paymentRequiresAction': true,
        'orderNumber': '',
      });
      expect(placed.orderNumber, isNull);
      expect(placed.checkoutSessionId, _sessionId);
      expect(placed.awaitsPaymentBeforeOrder, isTrue);
    });

    test('a server from before the change: the order, as always', () async {
      final placed = await _place({
        'id': _sessionId,
        'status': 3,
        'paymentRequiresAction': true,
        'paymentRedirectUrl': 'https://pay.example.test/esewa',
        'orderNumber': 'NK2026-00071',
      });
      expect(placed.orderNumber, 'NK2026-00071');
      expect(placed.awaitsPaymentBeforeOrder, isFalse);
    });

    test('cash on delivery: the order, nothing to pay', () async {
      final placed = await _place({
        'id': _sessionId,
        'status': 3,
        'paymentRequiresAction': false,
        'orderNumber': 'NK2026-00072',
      });
      expect(placed.orderNumber, 'NK2026-00072');
      expect(placed.requiresPaymentAction, isFalse);
      expect(placed.awaitsPaymentBeforeOrder, isFalse);
    });
  });

  group('GET checkout session', () {
    Future<(CheckoutSessionProgress, _CheckoutApi)> read(
      Map<String, dynamic> reply,
    ) async {
      final api = _CheckoutApi(sessionReply: reply);
      final progress = await CheckoutRemoteDataSource(
        apiClient: api,
      ).getCheckoutSession(_sessionId);
      return (progress, api);
    }

    test('reads the session it was asked for', () async {
      final (_, api) = await read({'id': _sessionId, 'status': 6});
      expect(api.gets, ['/v1/checkout/sessions/$_sessionId']);
    });

    test('awaiting payment: no order yet', () async {
      final (progress, _) = await read({
        'id': _sessionId,
        'status': 6,
        'orderNumber': null,
      });
      expect(progress.status, CheckoutSessionStatus.awaitingPayment);
      expect(progress.isPlaced, isFalse);
      expect(progress.isFailed, isFalse);
    });

    test('placed with its number: the order exists', () async {
      final (progress, _) = await read({
        'id': _sessionId,
        'status': 3,
        'orderId': 'b9f0c3d1-7a2e-4f55-8c11-3e6d9a0b4f22',
        'orderNumber': 'NK2026-00073',
      });
      expect(progress.isPlaced, isTrue);
      expect(progress.orderNumber, 'NK2026-00073');
    });

    test('placed without a number is not yet an order', () async {
      final (progress, _) = await read({'id': _sessionId, 'status': 3});
      expect(progress.status, CheckoutSessionStatus.placed);
      expect(progress.isPlaced, isFalse);
    });

    test('failed and expired: no order was created', () async {
      for (final status in [4, 5]) {
        final (progress, _) = await read({'id': _sessionId, 'status': status});
        expect(progress.isFailed, isTrue, reason: 'status $status');
        expect(progress.isPlaced, isFalse, reason: 'status $status');
      }
    });
  });

  test('every session status, by number or by name', () {
    const expected = {
      1: CheckoutSessionStatus.draft,
      2: CheckoutSessionStatus.placing,
      3: CheckoutSessionStatus.placed,
      4: CheckoutSessionStatus.failed,
      5: CheckoutSessionStatus.expired,
      6: CheckoutSessionStatus.awaitingPayment,
    };
    for (final entry in expected.entries) {
      expect(
        CheckoutRemoteDataSource.parseCheckoutSessionStatus(entry.key),
        entry.value,
      );
    }
    expect(
      CheckoutRemoteDataSource.parseCheckoutSessionStatus('AwaitingPayment'),
      CheckoutSessionStatus.awaitingPayment,
    );
    expect(
      CheckoutRemoteDataSource.parseCheckoutSessionStatus('Placed'),
      CheckoutSessionStatus.placed,
    );
    // Not evidence of anything: neither placed nor failed.
    for (final unreadable in [null, 0, 7, 'Refunded', '']) {
      expect(
        CheckoutRemoteDataSource.parseCheckoutSessionStatus(unreadable),
        CheckoutSessionStatus.unknown,
        reason: '$unreadable',
      );
    }
  });
}
