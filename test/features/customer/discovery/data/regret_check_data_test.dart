import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/regret_check_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/regret_check.dart';

class _GetApiClient extends ApiClient {
  _GetApiClient(this.body) : super(dio: Dio());

  final Object? body;
  String? getUri;
  Map<String, dynamic>? query;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
    query = queryParameters;
    return body;
  }
}

class _MockDiscoveryRemoteDataSource extends Mock
    implements DiscoveryRemoteDataSource {}

class _Network implements NetworkInfoConnectivity {
  _Network({required this.connected});

  final bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

const _payload = <String, dynamic>{
  'productId': 'p-viewed',
  'abstained': false,
  'recommendedProductId': 'p-alt',
  'summary': 'Buyers rarely send the Canvas tote back.',
  'windowDays': 90,
  'options': [
    {
      'rank': 1,
      'productId': 'p-alt',
      'productName': 'Canvas tote',
      'eligible': true,
      'level': 1,
      'regretScore': 0.08,
      'returnRate': 0.02,
      'averageRating': 4.6,
      'reviewCount': 120,
      'reasons': ['2% of orders returned', 'Rated 4.6 from 120 reviews'],
    },
    {
      'rank': 2,
      'productId': 'p-viewed',
      'productName': 'Leather tote',
      'eligible': true,
      'level': 2,
      'regretScore': 0.3,
      'returnRate': 0.12,
      'averageRating': 4,
      'reviewCount': 40,
      'reasons': ['12% of orders returned'],
    },
    {
      'rank': 3,
      'productId': 'p-new',
      'productName': 'Jute tote',
      'eligible': false,
      'level': 4,
      'regretScore': null,
      'returnRate': null,
      'averageRating': null,
      'reviewCount': 0,
      'reasons': ['Out of stock right now'],
    },
  ],
};

DioException _statusError(int status) => DioException(
  requestOptions: RequestOptions(path: '/v1/public/products/p/regret-check'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/v1/public/products/p/regret-check'),
    statusCode: status,
  ),
);

void main() {
  group('DiscoveryRemoteDataSource.getRegretCheck', () {
    test('calls the regret-check route for four alternatives and maps it',
        () async {
      final api = _GetApiClient(_payload);

      final check = (await DiscoveryRemoteDataSource(
        apiClient: api,
      ).getRegretCheck('p-viewed')).toDomain();

      expect(api.getUri, '/v1/public/products/p-viewed/regret-check');
      expect(api.query, {'maxAlternatives': 4});

      expect(check.productId, 'p-viewed');
      expect(check.abstained, isFalse);
      expect(check.recommendedProductId, 'p-alt');
      expect(check.summary, 'Buyers rarely send the Canvas tote back.');
      expect(check.windowDays, 90);
      expect(check.hasAlternatives, isTrue);
      expect(check.options.map((o) => o.productId), [
        'p-alt',
        'p-viewed',
        'p-new',
      ]);

      final best = check.options.first;
      expect(best.rank, 1);
      expect(best.productName, 'Canvas tote');
      expect(best.eligible, isTrue);
      expect(best.level, RegretLevel.low);
      expect(best.regretScore, 0.08);
      expect(best.returnRate, 0.02);
      expect(best.averageRating, 4.6);
      expect(best.reviewCount, 120);
      expect(best.reasons, [
        '2% of orders returned',
        'Rated 4.6 from 120 reviews',
      ]);

      expect(check.options[1].level, RegretLevel.medium);
      expect(check.options[1].averageRating, 4.0);

      final unproven = check.options.last;
      expect(unproven.eligible, isFalse);
      expect(unproven.level, RegretLevel.unknown);
      expect(unproven.regretScore, isNull);
      expect(unproven.returnRate, isNull);
      expect(unproven.averageRating, isNull);
    });

    test('reads levels sent as ints or as enum names', () {
      final cases = <(Object?, RegretLevel)>[
        (1, RegretLevel.low),
        (2, RegretLevel.medium),
        (3, RegretLevel.high),
        (4, RegretLevel.unknown),
        ('Low', RegretLevel.low),
        ('medium', RegretLevel.medium),
        ('HIGH', RegretLevel.high),
        ('Unknown', RegretLevel.unknown),
        ('3', RegretLevel.high),
        (99, RegretLevel.unknown),
        (null, RegretLevel.unknown),
      ];
      for (final (raw, expected) in cases) {
        expect(parseRegretLevel(raw), expected, reason: 'level $raw');
      }
    });

    test('missing fields default safely and id-less options are dropped', () {
      final check = RegretCheckDto.fromJson(<String, dynamic>{
        'recommendedProductId': '  ',
        'options': [
          {'productName': 'No id'},
          {'productId': 'p-1'},
        ],
      }).toDomain();

      expect(check.productId, '');
      expect(check.abstained, isFalse);
      expect(check.recommendedProductId, isNull);
      expect(check.summary, '');
      expect(check.windowDays, 0);
      expect(check.hasAlternatives, isFalse);

      final only = check.options.single;
      expect(only.productId, 'p-1');
      expect(only.rank, 0);
      expect(only.productName, '');
      expect(only.eligible, isTrue);
      expect(only.level, RegretLevel.unknown);
      expect(only.regretScore, isNull);
      expect(only.reviewCount, 0);
      expect(only.reasons, isEmpty);
    });
  });

  group('DiscoveryRepositoryImpl.getRegretCheck', () {
    late _MockDiscoveryRemoteDataSource remote;

    setUp(() => remote = _MockDiscoveryRemoteDataSource());

    DiscoveryRepositoryImpl repo({bool connected = true}) =>
        DiscoveryRepositoryImpl(
          remoteDataSource: remote,
          networkInfo: _Network(connected: connected),
        );

    test('maps the DTO to the domain entity on success', () async {
      when(
        () => remote.getRegretCheck('p-viewed'),
      ).thenAnswer((_) async => RegretCheckDto.fromJson(_payload));

      final result = await repo().getRegretCheck('p-viewed');

      final check = result.getOrElse((_) => throw StateError('expected right'));
      expect(check.recommendedProductId, 'p-alt');
      expect(check.options, hasLength(3));
    });

    test('maps a 404 to notFound', () async {
      when(
        () => remote.getRegretCheck('p-viewed'),
      ).thenThrow(_statusError(404));

      final result = await repo().getRegretCheck('p-viewed');

      expect(result.getLeft().toNullable(), const NetworkExceptions.notFound());
    });

    test('maps a 5xx to serverUnavailable', () async {
      when(
        () => remote.getRegretCheck('p-viewed'),
      ).thenThrow(_statusError(503));

      final result = await repo().getRegretCheck('p-viewed');

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.serverUnavailable(),
      );
    });

    test('maps a malformed payload to unexpectedError', () async {
      when(() => remote.getRegretCheck('p-viewed')).thenThrow(TypeError());

      final result = await repo().getRegretCheck('p-viewed');

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.unexpectedError(),
      );
    });

    test('returns noInternetConnection without calling the API when offline',
        () async {
      final result = await repo(connected: false).getRegretCheck('p-viewed');

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
      verifyNever(() => remote.getRegretCheck(any()));
    });
  });
}
