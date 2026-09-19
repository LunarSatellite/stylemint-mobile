import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/data/datasources/clienteling_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/data/repositories/clienteling_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';

/// Answers every call with [body], or throws [error] when one is set.
class _ApiClient extends ApiClient {
  _ApiClient({this.body, this.error}) : super(dio: Dio());

  final Object? body;
  final DioException? error;

  String? lastUri;
  Object? lastData;
  Options? lastOptions;
  Map<String, dynamic>? lastQuery;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastUri = uri;
    lastQuery = queryParameters;
    lastOptions = options;
    final failure = error;
    if (failure != null) throw failure;
    return body;
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastUri = uri;
    lastData = data;
    lastOptions = options;
    final failure = error;
    if (failure != null) throw failure;
    return body;
  }
}

class _Network implements NetworkInfoConnectivity {
  _Network({this.online = true});

  final bool online;

  @override
  Future<bool> get isConnected async => online;
}

DioException _status(int code, {Map<String, dynamic>? body}) {
  final request = RequestOptions(path: '/v1/clienteling/associate/clients');
  return DioException(
    requestOptions: request,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: code,
      data: body,
    ),
    type: DioExceptionType.badResponse,
  );
}

AssociateClientelingRepositoryImpl _associate(
  _ApiClient api, {
  bool online = true,
}) => AssociateClientelingRepositoryImpl(
  remoteDataSource: ClientelingRemoteDataSource(apiClient: api),
  networkInfo: _Network(online: online),
);

CustomerClientelingRepositoryImpl _customer(
  _ApiClient api, {
  bool online = true,
}) => CustomerClientelingRepositoryImpl(
  remoteDataSource: ClientelingRemoteDataSource(apiClient: api),
  networkInfo: _Network(online: online),
);

void main() {
  group('failure mapping', () {
    test('offline never reaches the API', () async {
      final api = _ApiClient(body: <String, dynamic>{'items': <dynamic>[]});
      final result = await _associate(api, online: false).listMyClients();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, const NetworkExceptions.noInternetConnection()),
        (_) => fail('expected a failure'),
      );
      expect(api.lastUri, isNull);
    });

    test('403 — no assignment for this customer — maps to a failure', () async {
      final api = _ApiClient(error: _status(403));
      final result = await _associate(api).getBrief('c1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(NetworkExceptions.getMessage(f), isNotEmpty),
        (_) => fail('expected a failure'),
      );
    });

    test('404 maps to notFound', () async {
      final api = _ApiClient(error: _status(404));
      final result = await _associate(api).getBrief('c1');

      result.fold(
        (f) => expect(f, const NetworkExceptions.notFound()),
        (_) => fail('expected a failure'),
      );
    });

    test('409 keeps the backend conflict message', () async {
      final api = _ApiClient(
        error: _status(
          409,
          body: {
            'errorCode': 'clienteling.session.conflict',
            'detail': 'A session is already open for this customer.',
          },
        ),
      );
      final result = await _associate(api).openSession(
        customerAccountId: 'c1',
        purpose: 'Fitting help',
        idempotencyKey: 'key-1',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(
          NetworkExceptions.getMessage(f),
          contains('already open'),
        ),
        (_) => fail('expected a failure'),
      );
    });

    test('5xx maps to serverUnavailable', () async {
      final api = _ApiClient(error: _status(503));
      final result = await _customer(api).listClaims();

      result.fold(
        (f) => expect(f, const NetworkExceptions.serverUnavailable()),
        (_) => fail('expected a failure'),
      );
    });

    test('a malformed body is an unexpected error, not a crash', () async {
      final api = _ApiClient(body: 'not json');
      final result = await _associate(api).listMyClients();

      result.fold(
        (f) => expect(f, const NetworkExceptions.unexpectedError()),
        (_) => fail('expected a failure'),
      );
    });
  });

  group('request shape', () {
    test('mutations carry the caller-supplied Idempotency-Key', () async {
      final api = _ApiClient(body: <String, dynamic>{'outcomeId': 'x1'});
      await _customer(api).confirmOutcome(
        outcomeId: 'x1',
        idempotencyKey: 'key-42',
      );

      expect(
        api.lastUri,
        '/v1/clienteling/me/assisted-outcomes/x1/confirm',
      );
      expect(api.lastOptions?.headers?['Idempotency-Key'], 'key-42');
    });

    test('outreach sends the channel as the API integer', () async {
      final api = _ApiClient(body: <String, dynamic>{'outreachId': 'r1'});
      await _associate(api).sendOutreach(
        customerAccountId: 'c1',
        channel: ClientelingOutreachChannel.sms,
        subject: 'Your coat is in',
        body: 'It arrived this morning.',
        idempotencyKey: 'key-7',
        sessionId: 's1',
      );

      final data = api.lastData! as Map<String, dynamic>;
      expect(data['channel'], 2);
      expect(data['sessionId'], 's1');
      expect(data['customerAccountId'], 'c1');
    });

    test('outreach omits sessionId entirely when there is none', () async {
      final api = _ApiClient(body: <String, dynamic>{'outreachId': 'r1'});
      await _associate(api).sendOutreach(
        customerAccountId: 'c1',
        channel: ClientelingOutreachChannel.email,
        subject: 'Hello',
        body: 'A message.',
        idempotencyKey: 'key-8',
      );

      final data = api.lastData! as Map<String, dynamic>;
      expect(data.containsKey('sessionId'), isFalse);
    });

    test('the client book asks for a page and forwards the cursor', () async {
      final api = _ApiClient(body: <String, dynamic>{'items': <dynamic>[]});
      await _associate(api).listMyClients(cursor: 'c2', pageSize: 5);

      expect(api.lastUri, '/v1/clienteling/associate/clients');
      expect(api.lastQuery, {'pageSize': 5, 'cursor': 'c2'});
    });
  });

  group('success mapping', () {
    test('an empty page is an empty list, not a failure', () async {
      final api = _ApiClient(
        body: <String, dynamic>{
          'items': <dynamic>[],
          'totalCount': 0,
          'nextCursor': null,
        },
      );
      final result = await _associate(api).listMyClients();

      result.fold((_) => fail('expected success'), (page) {
        expect(page.items, isEmpty);
        expect(page.nextCursor, isNull);
      });
    });

    test('a blocked outreach is a success carrying the decision', () async {
      final api = _ApiClient(
        body: <String, dynamic>{
          'outreachId': 'r1',
          'customerAccountId': 'c1',
          'channel': 1,
          'decision': 2,
          'sent': false,
          'subject': 'Hello',
          'decisionReason': 'No consent to be contacted.',
        },
      );
      final result = await _associate(api).sendOutreach(
        customerAccountId: 'c1',
        channel: ClientelingOutreachChannel.email,
        subject: 'Hello',
        body: 'A message.',
        idempotencyKey: 'key-9',
      );

      result.fold((_) => fail('a block is not a failure'), (attempt) {
        expect(attempt.sent, isFalse);
        expect(
          attempt.decision,
          ClientelingOutreachDecision.blockedNoConsent,
        );
        expect(attempt.decisionReason, 'No consent to be contacted.');
      });
    });
  });
}
