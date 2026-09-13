import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_care_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/repositories/orders_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';

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

Map<String, dynamic> _planJson({Object? stage = 2}) => <String, dynamic>{
  'orderNumber': 'NK2026-00015',
  'generatedUtc': '2026-09-13T10:00:00Z',
  'nextReturnDeadlineUtc': '2026-09-18T10:00:00Z',
  'items': [
    <String, dynamic>{
      'subOrderId': '11111111-1111-1111-1111-111111111111',
      'subOrderLineId': '22222222-2222-2222-2222-222222222222',
      'productVariantId': '33333333-3333-3333-3333-333333333333',
      'title': 'Linen shirt',
      'variantLabel': 'M / White',
      'thumbnailUrl': 'https://cdn.example.com/shirt.jpg',
      'stage': stage,
      'deliveredUtc': '2026-09-11T08:30:00Z',
      'returnWindowClosesUtc': '2026-09-18T10:00:00Z',
      'daysLeftToReturn': 5,
      'trackingNumber': 'SM-D-00000001',
      'actions': ['return', 'review', 'get_help'],
      'guidance': 'You have 5 days to start a return if it does not fit.',
    },
  ],
};

void main() {
  group('OrdersRemoteDataSource.getOrderCarePlan', () {
    test('calls the order care route and maps the camelCase plan', () async {
      final api = _GetApiClient(_planJson());

      final dto = await OrdersRemoteDataSource(
        apiClient: api,
      ).getOrderCarePlan('NK2026-00015');

      expect(api.getUri, '/v1/orders/NK2026-00015/care');
      final plan = dto.toDomain();
      expect(plan.orderNumber, 'NK2026-00015');
      expect(plan.generatedUtc, DateTime.utc(2026, 9, 13, 10));
      expect(plan.nextReturnDeadlineUtc, DateTime.utc(2026, 9, 18, 10));
      expect(plan.items, hasLength(1));

      final item = plan.items.single;
      expect(item.subOrderId, '11111111-1111-1111-1111-111111111111');
      expect(item.subOrderLineId, '22222222-2222-2222-2222-222222222222');
      expect(item.productVariantId, '33333333-3333-3333-3333-333333333333');
      expect(item.title, 'Linen shirt');
      expect(item.variantLabel, 'M / White');
      expect(item.thumbnailUrl, 'https://cdn.example.com/shirt.jpg');
      expect(item.stage, CareStage.returnWindowOpen);
      expect(item.isReturnWindowOpen, isTrue);
      expect(item.deliveredUtc, DateTime.utc(2026, 9, 11, 8, 30));
      expect(item.returnWindowClosesUtc, DateTime.utc(2026, 9, 18, 10));
      expect(item.daysLeftToReturn, 5);
      expect(item.trackingNumber, 'SM-D-00000001');
      expect(item.actions, [
        CareAction.returnItem,
        CareAction.review,
        CareAction.getHelp,
      ]);
      expect(
        item.guidance,
        'You have 5 days to start a return if it does not fit.',
      );
    });

    test('missing and null fields degrade to safe defaults', () async {
      final api = _GetApiClient(<String, dynamic>{
        'orderNumber': 'NK2026-00016',
        'items': [
          <String, dynamic>{'title': 'Mug', 'variantLabel': '', 'stage': null},
        ],
      });

      final plan = (await OrdersRemoteDataSource(
        apiClient: api,
      ).getOrderCarePlan('NK2026-00016')).toDomain();

      expect(plan.generatedUtc, isNull);
      expect(plan.nextReturnDeadlineUtc, isNull);
      final item = plan.items.single;
      expect(item.subOrderLineId, '');
      expect(item.variantLabel, isNull);
      expect(item.thumbnailUrl, isNull);
      expect(item.stage, CareStage.unknown);
      expect(item.daysLeftToReturn, isNull);
      expect(item.actions, isEmpty);
      expect(item.guidance, '');
    });

    test('a plan without items maps to an empty list', () {
      final plan = OrderCarePlanDto.fromJson(<String, dynamic>{
        'orderNumber': 'NK2026-00017',
      }).toDomain();

      expect(plan.items, isEmpty);
    });
  });

  group('parseCareStage', () {
    test('maps every backend CareStage int value', () {
      expect(parseCareStage(1), CareStage.inProgress);
      expect(parseCareStage(2), CareStage.returnWindowOpen);
      expect(parseCareStage(3), CareStage.returnWindowClosed);
      expect(parseCareStage(4), CareStage.returnInProgress);
      expect(parseCareStage(5), CareStage.returned);
      expect(parseCareStage(6), CareStage.cancelled);
    });

    test('accepts string names in any casing and numeric strings', () {
      expect(parseCareStage('ReturnWindowOpen'), CareStage.returnWindowOpen);
      expect(parseCareStage('returnWindowClosed'), CareStage.returnWindowClosed);
      expect(parseCareStage('return_in_progress'), CareStage.returnInProgress);
      expect(parseCareStage('IN_PROGRESS'), CareStage.inProgress);
      expect(parseCareStage('Returned'), CareStage.returned);
      expect(parseCareStage('Cancelled'), CareStage.cancelled);
      expect(parseCareStage('2'), CareStage.returnWindowOpen);
    });

    test('unknown ints, names and types map to unknown', () {
      expect(parseCareStage(0), CareStage.unknown);
      expect(parseCareStage(99), CareStage.unknown);
      expect(parseCareStage('Teleported'), CareStage.unknown);
      expect(parseCareStage(null), CareStage.unknown);
      expect(parseCareStage(true), CareStage.unknown);
    });

    test('int and string stages decode identically through the DTO', () {
      final fromInt = CareItemDto.fromJson(
        _planJson(stage: 3)['items'][0] as Map<String, dynamic>,
      );
      final fromString = CareItemDto.fromJson(
        _planJson(stage: 'ReturnWindowClosed')['items'][0]
            as Map<String, dynamic>,
      );

      expect(fromInt.stage, CareStage.returnWindowClosed);
      expect(fromString.stage, CareStage.returnWindowClosed);
    });
  });

  group('parseCareActions', () {
    test('keeps known actions in order, de-duplicated, dropping unknowns', () {
      expect(
        parseCareActions([
          'track',
          'return',
          'teleport',
          'Review',
          'reorder',
          'get_help',
          'return',
          42,
        ]),
        [
          CareAction.track,
          CareAction.returnItem,
          CareAction.review,
          CareAction.reorder,
          CareAction.getHelp,
        ],
      );
    });

    test('a non-list value yields no actions', () {
      expect(parseCareActions(null), isEmpty);
      expect(parseCareActions('track'), isEmpty);
    });
  });

  group('OrdersRepositoryImpl.getOrderCarePlan', () {
    late _MockOrdersRemoteDataSource remote;

    setUp(() => remote = _MockOrdersRemoteDataSource());

    OrdersRepositoryImpl repo({bool connected = true}) => OrdersRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: _Network(connected: connected),
    );

    test('maps the DTO to the domain plan on success', () async {
      when(
        () => remote.getOrderCarePlan('NK2026-00015'),
      ).thenAnswer((_) async => OrderCarePlanDto.fromJson(_planJson()));

      final result = await repo().getOrderCarePlan('NK2026-00015');

      final plan = result.getOrElse((_) => throw StateError('expected right'));
      expect(plan.items.single.stage, CareStage.returnWindowOpen);
    });

    test('maps a 404 DioException to notFound', () async {
      final options = RequestOptions(path: '/v1/orders/NK2026-00015/care');
      when(() => remote.getOrderCarePlan('NK2026-00015')).thenThrow(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(requestOptions: options, statusCode: 404),
        ),
      );

      final result = await repo().getOrderCarePlan('NK2026-00015');

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.notFound(),
      );
    });

    test('maps a malformed payload to unexpectedError', () async {
      when(
        () => remote.getOrderCarePlan('NK2026-00015'),
      ).thenThrow(const FormatException('bad json'));

      final result = await repo().getOrderCarePlan('NK2026-00015');

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.unexpectedError(),
      );
    });

    test('returns noInternetConnection without calling the API when offline',
        () async {
      final result = await repo(connected: false).getOrderCarePlan('NK1');

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
      verifyNever(() => remote.getOrderCarePlan(any()));
    });
  });
}
