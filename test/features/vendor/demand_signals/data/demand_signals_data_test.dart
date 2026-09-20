import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/data/datasources/demand_signals_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/data/models/demand_signals_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/data/repositories/demand_signals_repository_impl.dart';

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

class _MockDemandSignalsRemoteDataSource extends Mock
    implements DemandSignalsRemoteDataSource {}

class _Network implements NetworkInfoConnectivity {
  _Network({required this.connected});

  final bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

void main() {
  group('DemandSignalsRemoteDataSource.getDemandSignals', () {
    test(
      'calls the api-prefixed Discovery route with days and limit',
      () async {
        final api = _GetApiClient(<String, dynamic>{
          'windowDays': 30,
          'generatedUtc': '2026-09-13T06:00:00Z',
          'topSearches': [
            {'query': 'linen shirt', 'count': 1240},
            {'query': 'running shoes', 'count': 310},
          ],
          'unmetSearches': [
            {'query': 'hemp tote bag', 'count': 42},
          ],
        });

        final dto = await DemandSignalsRemoteDataSource(
          apiClient: api,
        ).getDemandSignals(days: 30, limit: 20);

        expect(api.getUri, '/api/v1/vendor/demand-signals');
        expect(api.query, {'days': 30, 'limit': 20});

        final signals = dto.toDomain();
        expect(signals.windowDays, 30);
        expect(signals.generatedUtc, DateTime.utc(2026, 9, 13, 6));
        expect(signals.topSearches.map((q) => q.query), [
          'linen shirt',
          'running shoes',
        ]);
        expect(signals.topSearches.map((q) => q.count), [1240, 310]);
        expect(signals.unmetSearches.single.query, 'hemp tote bag');
        expect(signals.unmetSearches.single.count, 42);
        expect(signals.isEmpty, isFalse);
      },
    );

    test('missing lists read as empty and blank queries are dropped', () {
      final signals = DemandSignalsDto.fromJson(<String, dynamic>{
        'windowDays': 7,
        'topSearches': [
          {'query': '   ', 'count': 9},
          {'count': 3},
        ],
      }).toDomain();

      expect(signals.generatedUtc, isNull);
      expect(signals.topSearches, isEmpty);
      expect(signals.unmetSearches, isEmpty);
      expect(signals.isEmpty, isTrue);
    });
  });

  group('DemandSignalsRepositoryImpl', () {
    late _MockDemandSignalsRemoteDataSource remote;

    setUp(() => remote = _MockDemandSignalsRemoteDataSource());

    DemandSignalsRepositoryImpl repo({bool connected = true}) =>
        DemandSignalsRepositoryImpl(
          remoteDataSource: remote,
          networkInfo: _Network(connected: connected),
        );

    test('maps the DTO to the domain entity on success', () async {
      when(() => remote.getDemandSignals(days: 7, limit: 20)).thenAnswer(
        (_) async => DemandSignalsDto.fromJson(<String, dynamic>{
          'windowDays': 7,
          'unmetSearches': [
            {'query': 'rain boots', 'count': 5},
          ],
        }),
      );

      final result = await repo().getDemandSignals(days: 7, limit: 20);

      final signals = result.getOrElse(
        (_) => throw StateError('expected right'),
      );
      expect(signals.unmetSearches.single.query, 'rain boots');
    });

    test('maps a DioException to a left failure', () async {
      when(() => remote.getDemandSignals(days: 7, limit: 20)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/vendor/demand-signals'),
        ),
      );

      final result = await repo().getDemandSignals(days: 7, limit: 20);

      expect(result.isLeft(), isTrue);
    });

    test(
      'returns noInternetConnection without calling the API when offline',
      () async {
        final result = await repo(
          connected: false,
        ).getDemandSignals(days: 7, limit: 20);

        expect(
          result.getLeft().toNullable(),
          const NetworkExceptions.noInternetConnection(),
        );
        verifyNever(
          () => remote.getDemandSignals(
            days: any(named: 'days'),
            limit: any(named: 'limit'),
          ),
        );
      },
    );
  });
}
