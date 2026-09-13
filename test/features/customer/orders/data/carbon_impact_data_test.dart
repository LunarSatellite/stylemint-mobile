import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/carbon_impact_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/repositories/orders_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/carbon_impact.dart';

class _GetApiClient extends ApiClient {
  _GetApiClient(this.body) : super(dio: Dio());

  final Object? body;
  String? getUri;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
    return body;
  }
}

class _MockOrdersRemoteDataSource extends Mock
    implements OrdersRemoteDataSource {}

class _Network implements NetworkInfoConnectivity {
  _Network({required this.connected});

  final bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

void main() {
  group('OrdersRemoteDataSource.getCarbonImpact', () {
    test('calls the customer carbon-impact route and maps camelCase fields',
        () async {
      final api = _GetApiClient(<String, dynamic>{
        'kgCO2Saved': 3.25,
        'deliveryCount': 4,
        'comparedToTraditionalKg': 8.5,
      });

      final dto =
          await OrdersRemoteDataSource(apiClient: api).getCarbonImpact();

      expect(api.getUri, '/v1/customer/delivery/carbon-impact');
      expect(dto.kgCo2Saved, 3.25);
      expect(dto.deliveryCount, 4);
      expect(dto.comparedToTraditionalKg, 8.5);
    });

    test('integer JSON numbers and missing fields default safely', () async {
      final api = _GetApiClient(<String, dynamic>{'kgCO2Saved': 2});

      final dto =
          await OrdersRemoteDataSource(apiClient: api).getCarbonImpact();

      expect(dto.kgCo2Saved, 2.0);
      expect(dto.deliveryCount, 0);
      expect(dto.comparedToTraditionalKg, 0);
      expect(dto.toDomain().hasSavings, isFalse);
    });
  });

  group('CarbonImpact', () {
    test('hasSavings requires both completed hops and a positive saving', () {
      const none = CarbonImpact(
        kgCo2Saved: 0,
        deliveryCount: 3,
        comparedToTraditionalKg: 5,
      );
      const noHops = CarbonImpact(
        kgCo2Saved: 1,
        deliveryCount: 0,
        comparedToTraditionalKg: 5,
      );
      const some = CarbonImpact(
        kgCo2Saved: 1,
        deliveryCount: 2,
        comparedToTraditionalKg: 5,
      );

      expect(none.hasSavings, isFalse);
      expect(noHops.hasSavings, isFalse);
      expect(some.hasSavings, isTrue);
    });

    test('percentSaved rounds against the traditional baseline', () {
      const impact = CarbonImpact(
        kgCo2Saved: 3.25,
        deliveryCount: 4,
        comparedToTraditionalKg: 8.5,
      );
      expect(impact.percentSaved, 38);
    });

    test('percentSaved is null without a baseline or when it rounds to 0', () {
      const noBaseline = CarbonImpact(
        kgCo2Saved: 1,
        deliveryCount: 1,
        comparedToTraditionalKg: 0,
      );
      const tiny = CarbonImpact(
        kgCo2Saved: 0.001,
        deliveryCount: 1,
        comparedToTraditionalKg: 100,
      );
      expect(noBaseline.percentSaved, isNull);
      expect(tiny.percentSaved, isNull);
    });
  });

  group('OrdersRepositoryImpl.getCarbonImpact', () {
    late _MockOrdersRemoteDataSource remote;

    setUp(() => remote = _MockOrdersRemoteDataSource());

    OrdersRepositoryImpl repo({bool connected = true}) => OrdersRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: _Network(connected: connected),
    );

    test('maps the DTO to the domain entity on success', () async {
      when(() => remote.getCarbonImpact()).thenAnswer(
        (_) async => const CarbonImpactDto(
          kgCo2Saved: 1.5,
          deliveryCount: 2,
          comparedToTraditionalKg: 4,
        ),
      );

      final result = await repo().getCarbonImpact();

      final impact = result.getOrElse((_) => throw StateError('expected right'));
      expect(impact.kgCo2Saved, 1.5);
      expect(impact.deliveryCount, 2);
      expect(impact.comparedToTraditionalKg, 4);
    });

    test('maps a 404 DioException to notFound', () async {
      final options = RequestOptions(
        path: '/v1/customer/delivery/carbon-impact',
      );
      when(() => remote.getCarbonImpact()).thenThrow(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(requestOptions: options, statusCode: 404),
        ),
      );

      final result = await repo().getCarbonImpact();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.notFound(),
      );
    });

    test('returns noInternetConnection without calling the API when offline',
        () async {
      final result = await repo(connected: false).getCarbonImpact();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
      verifyNever(() => remote.getCarbonImpact());
    });
  });
}
