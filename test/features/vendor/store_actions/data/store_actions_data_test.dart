import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/data/datasources/store_actions_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/data/models/store_action_queue_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/data/repositories/store_actions_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/entities/store_actions.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

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

class _MockStoreActionsRemoteDataSource extends Mock
    implements StoreActionsRemoteDataSource {}

class _Network implements NetworkInfoConnectivity {
  _Network({required this.connected});

  final bool connected;

  @override
  Future<bool> get isConnected async => connected;
}

Map<String, dynamic> _restockJson({Object? kind = 1, Object? severity = 1}) =>
    <String, dynamic>{
      'kind': kind,
      'severity': severity,
      'productId': '11111111-1111-1111-1111-111111111111',
      'productVariantId': '22222222-2222-2222-2222-222222222222',
      'productName': 'Linen shirt',
      'sku': 'LS-M',
      'recommendation':
          "Restock Linen shirt (LS-M): about 2 days of stock left at this "
          "week's pace.",
      'evidence': ['12 sold in the last 7 days', '4 in stock'],
      'valueAtStake': {'amount': 9600.0, 'currency': 'NPR'},
    };

Map<String, dynamic> _queueJson() => <String, dynamic>{
  'generatedUtc': '2026-09-13T10:00:00+00:00',
  'actions': [
    _restockJson(),
    <String, dynamic>{
      'kind': 4,
      'severity': 2,
      'productId': '33333333-3333-3333-3333-333333333333',
      'productVariantId': null,
      'productName': 'Canvas tote',
      'sku': null,
      'recommendation': 'Add photos to Canvas tote: it is live with no images.',
      'evidence': ['Live product', '0 photos'],
      'valueAtStake': null,
    },
  ],
};

DioException _dioError(int? status, {DioExceptionType? type}) {
  final options = RequestOptions(path: '/v1/vendor/store/actions');
  return DioException(
    requestOptions: options,
    type: type ?? DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

void main() {
  group('StoreActionsRemoteDataSource.getStoreActions', () {
    test('calls the Catalog vendor store route and maps the queue', () async {
      final api = _GetApiClient(_queueJson());

      final dto = await StoreActionsRemoteDataSource(
        apiClient: api,
      ).getStoreActions();

      expect(api.getUri, '/v1/vendor/store/actions');
      final queue = dto.toDomain();
      expect(queue.generatedUtc, DateTime.utc(2026, 9, 13, 10));
      expect(queue.actions, hasLength(2));

      final restock = queue.actions.first;
      expect(restock.kind, StoreActionKind.restockSoon);
      expect(restock.severity, StoreActionSeverity.high);
      expect(restock.productId, '11111111-1111-1111-1111-111111111111');
      expect(restock.productVariantId, '22222222-2222-2222-2222-222222222222');
      expect(restock.productName, 'Linen shirt');
      expect(restock.sku, 'LS-M');
      expect(restock.recommendation, startsWith('Restock Linen shirt (LS-M)'));
      expect(restock.evidence, ['12 sold in the last 7 days', '4 in stock']);
      expect(
        restock.valueAtStake,
        const Money(amount: 9600, currency: 'NPR'),
      );

      final photos = queue.actions.last;
      expect(photos.kind, StoreActionKind.addProductImages);
      expect(photos.severity, StoreActionSeverity.medium);
      expect(photos.productVariantId, isNull);
      expect(photos.sku, isNull);
      expect(photos.valueAtStake, isNull);
    });

    test('string enum names decode the same as their int values', () {
      final fromInt = StoreActionDto.fromJson(_restockJson(kind: 2));
      final fromName = StoreActionDto.fromJson(
        _restockJson(kind: 'SoldOutWhileSelling', severity: 'High'),
      );

      expect(fromInt.kind, StoreActionKind.soldOutWhileSelling);
      expect(fromName.kind, StoreActionKind.soldOutWhileSelling);
      expect(fromInt.severity, StoreActionSeverity.high);
      expect(fromName.severity, StoreActionSeverity.high);
    });

    test('an empty or partial payload degrades safely', () {
      expect(
        StoreActionQueueDto.fromJson(<String, dynamic>{}).toDomain().isEmpty,
        isTrue,
      );

      final queue = StoreActionQueueDto.fromJson(<String, dynamic>{
        'actions': [
          <String, dynamic>{'kind': 1, 'severity': 1, 'recommendation': '  '},
          <String, dynamic>{
            'kind': 3,
            'productName': 'Wool coat',
            'sku': '  ',
            'recommendation': 'Consider a promotion for Wool coat.',
            'evidence': ['', 42, '0 sold in the last 30 days'],
            'valueAtStake': {'amount': 'lots'},
          },
          'not-an-action',
        ],
      }).toDomain();

      expect(queue.generatedUtc, isNull);
      final action = queue.actions.single;
      expect(action.kind, StoreActionKind.slowMovingStock);
      expect(action.severity, StoreActionSeverity.low);
      expect(action.productId, '');
      expect(action.sku, isNull);
      expect(action.evidence, ['0 sold in the last 30 days']);
      expect(action.valueAtStake, isNull);
    });
  });

  group('parseStoreActionKind', () {
    test('maps every backend StoreActionKind int value', () {
      expect(parseStoreActionKind(1), StoreActionKind.restockSoon);
      expect(parseStoreActionKind(2), StoreActionKind.soldOutWhileSelling);
      expect(parseStoreActionKind(3), StoreActionKind.slowMovingStock);
      expect(parseStoreActionKind(4), StoreActionKind.addProductImages);
      expect(parseStoreActionKind(5), StoreActionKind.returnsRising);
    });

    test('maps ReturnsRising (5) by int, name and snake_case', () {
      expect(parseStoreActionKind('5'), StoreActionKind.returnsRising);
      expect(
        parseStoreActionKind('ReturnsRising'),
        StoreActionKind.returnsRising,
      );
      expect(
        parseStoreActionKind('returns_rising'),
        StoreActionKind.returnsRising,
      );
    });

    test('keeps a ReturnsRising action with no variant and no money', () {
      final queue = StoreActionQueueDto.fromJson(<String, dynamic>{
        'actions': [
          <String, dynamic>{
            'kind': 5,
            'severity': 1,
            'productId': '44444444-4444-4444-4444-444444444444',
            'productVariantId': null,
            'productName': 'Wool coat',
            'sku': null,
            'recommendation':
                'Look into returns for Wool coat: read the return reasons '
                'and check the photos and description.',
            'evidence': [
              '6 of 20 sold in the last 30 days came back (30%)',
              'Before that, 2 of 40 came back (5%)',
            ],
            'valueAtStake': null,
          },
        ],
      }).toDomain();

      final action = queue.actions.single;
      expect(action.kind, StoreActionKind.returnsRising);
      expect(action.severity, StoreActionSeverity.high);
      expect(action.productId, '44444444-4444-4444-4444-444444444444');
      expect(action.productVariantId, isNull);
      expect(action.sku, isNull);
      expect(action.valueAtStake, isNull);
      expect(action.recommendation, startsWith('Look into returns'));
      expect(action.evidence, hasLength(2));
    });

    test('accepts names in any casing, snake_case and numeric strings', () {
      expect(parseStoreActionKind('RestockSoon'), StoreActionKind.restockSoon);
      expect(
        parseStoreActionKind('sold_out_while_selling'),
        StoreActionKind.soldOutWhileSelling,
      );
      expect(
        parseStoreActionKind('SLOWMOVINGSTOCK'),
        StoreActionKind.slowMovingStock,
      );
      expect(parseStoreActionKind('4'), StoreActionKind.addProductImages);
      expect(parseStoreActionKind(1.0), StoreActionKind.restockSoon);
    });

    test('unknown values map to unknown', () {
      expect(parseStoreActionKind(0), StoreActionKind.unknown);
      expect(parseStoreActionKind(99), StoreActionKind.unknown);
      expect(parseStoreActionKind('Teleport'), StoreActionKind.unknown);
      expect(parseStoreActionKind(null), StoreActionKind.unknown);
      expect(parseStoreActionKind(true), StoreActionKind.unknown);
    });
  });

  group('parseStoreActionSeverity', () {
    test('maps ints and names', () {
      expect(parseStoreActionSeverity(1), StoreActionSeverity.high);
      expect(parseStoreActionSeverity(2), StoreActionSeverity.medium);
      expect(parseStoreActionSeverity(3), StoreActionSeverity.low);
      expect(parseStoreActionSeverity('medium'), StoreActionSeverity.medium);
      expect(parseStoreActionSeverity('Low'), StoreActionSeverity.low);
      expect(parseStoreActionSeverity('1'), StoreActionSeverity.high);
    });

    test('unknown values read as low, the neutral styling', () {
      expect(parseStoreActionSeverity(7), StoreActionSeverity.low);
      expect(parseStoreActionSeverity('Critical'), StoreActionSeverity.low);
      expect(parseStoreActionSeverity(null), StoreActionSeverity.low);
    });
  });

  group('StoreActionsRepositoryImpl', () {
    late _MockStoreActionsRemoteDataSource remote;

    setUp(() => remote = _MockStoreActionsRemoteDataSource());

    StoreActionsRepositoryImpl repo({bool connected = true}) =>
        StoreActionsRepositoryImpl(
          remoteDataSource: remote,
          networkInfo: _Network(connected: connected),
        );

    test('maps the DTO to the domain queue on success', () async {
      when(
        () => remote.getStoreActions(),
      ).thenAnswer((_) async => StoreActionQueueDto.fromJson(_queueJson()));

      final result = await repo().getStoreActions();

      final queue = result.getOrElse((_) => throw StateError('expected right'));
      expect(queue.actions.map((a) => a.kind), [
        StoreActionKind.restockSoon,
        StoreActionKind.addProductImages,
      ]);
    });

    test('maps a 404 to notFound', () async {
      when(() => remote.getStoreActions()).thenThrow(_dioError(404));

      final result = await repo().getStoreActions();

      expect(result.getLeft().toNullable(), const NetworkExceptions.notFound());
    });

    test('maps a 5xx to serverUnavailable', () async {
      when(() => remote.getStoreActions()).thenThrow(_dioError(503));

      final result = await repo().getStoreActions();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.serverUnavailable(),
      );
    });

    test('maps a connection timeout to noInternetConnection', () async {
      when(() => remote.getStoreActions()).thenThrow(
        _dioError(null, type: DioExceptionType.connectionTimeout),
      );

      final result = await repo().getStoreActions();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
    });

    test('maps a malformed payload to unexpectedError', () async {
      when(
        () => remote.getStoreActions(),
      ).thenThrow(const FormatException('bad json'));

      final result = await repo().getStoreActions();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.unexpectedError(),
      );
    });

    test(
      'returns noInternetConnection without calling the API when offline',
      () async {
        final result = await repo(connected: false).getStoreActions();

        expect(
          result.getLeft().toNullable(),
          const NetworkExceptions.noInternetConnection(),
        );
        verifyNever(() => remote.getStoreActions());
      },
    );
  });
}
