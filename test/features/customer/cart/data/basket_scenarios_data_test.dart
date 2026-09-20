import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/datasources/cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/basket_scenarios_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/repositories/cart_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_scenarios.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _GetApiClient extends ApiClient {
  _GetApiClient(this.body) : super(dio: Dio());

  final Object? body;
  String? getUri;
  Map<String, dynamic>? query;
  Options? sentOptions;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
    query = queryParameters;
    sentOptions = options;
    return body;
  }
}

class _MockCartRemoteDataSource extends Mock implements CartRemoteDataSource {}

const _payload = <String, dynamic>{
  'currency': 'NPR',
  'budget': 5000,
  'scenarios': [
    {
      'kind': 1,
      'title': 'Your cart as it is',
      'feasible': true,
      'summary': 'Everything you picked.',
      'changes': <String>[],
      'lines': [
        {
          'cartLineId': 'line-1',
          'productId': 'prod-1',
          'productVariantId': 'var-1',
          'title': 'Linen shirt',
          'quantity': 2,
          'unitPriceAmount': 2500,
          'kept': true,
          'change': 1,
        },
      ],
      'subtotalAmount': 5000,
      'taxAmount': 650,
      'grandTotalAmount': 5650,
      'differenceAmount': 0,
      'sellerCount': 2,
      'dispatchDays': 3,
      'itemsAtStockRisk': 0,
    },
    {
      'kind': 3,
      'title': 'Lower cost',
      'feasible': true,
      'summary': 'Swaps the shirt for a similar cheaper one.',
      'changes': ['Linen shirt swapped for Cotton shirt'],
      'lines': [
        {
          'cartLineId': null,
          'productId': 'prod-9',
          'productVariantId': 'var-9',
          'title': 'Cotton shirt',
          'quantity': 2,
          'unitPriceAmount': 2000.5,
          'kept': false,
          'change': 4,
        },
      ],
      'subtotalAmount': 4001,
      'taxAmount': 520.13,
      'grandTotalAmount': 4521.13,
      'differenceAmount': -1128.87,
      'sellerCount': 1,
      'dispatchDays': 1,
      'itemsAtStockRisk': 1,
    },
  ],
};

DioException _dioError({
  int? status,
  Object? body,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final request = RequestOptions(path: '/v1/cart/scenarios');
  return DioException(
    requestOptions: request,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: request,
            statusCode: status,
            data: body,
          ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(<String>[]));

  group('CartRemoteDataSource.getScenarios', () {
    test(
      'sends the budget and repeated keep/exclude values, then maps',
      () async {
        final api = _GetApiClient(_payload);

        final result = (await CartRemoteDataSource(apiClient: api).getScenarios(
          budget: 5000,
          keepLineIds: ['line-1', 'line-2'],
          excludeProductIds: ['prod-7'],
        )).toDomain();

        expect(api.getUri, '/v1/cart/scenarios');
        expect(api.query, {
          'budget': 5000.0,
          'keep': ['line-1', 'line-2'],
          'exclude': ['prod-7'],
        });
        expect(api.sentOptions?.listFormat, ListFormat.multi);
        expect(api.sentOptions?.headers?['requiresToken'], isTrue);

        expect(result.currency, 'NPR');
        expect(result.budget, 5000);
        expect(result.scenarios.map((s) => s.kind), [
          BasketScenarioKind.asItIs,
          BasketScenarioKind.lowerCost,
        ]);

        final asItIs = result.scenarios.first;
        expect(asItIs.title, 'Your cart as it is');
        expect(asItIs.feasible, isTrue);
        expect(asItIs.summary, 'Everything you picked.');
        expect(asItIs.changes, isEmpty);
        expect(asItIs.subtotal, const Money(amount: 5000, currency: 'NPR'));
        expect(asItIs.tax.amount, 650);
        expect(asItIs.grandTotal.amount, 5650);
        expect(asItIs.difference.amount, 0);
        expect(asItIs.sellerCount, 2);
        expect(asItIs.dispatchDays, 3);
        expect(asItIs.itemsAtStockRisk, 0);

        final kept = asItIs.lines.single;
        expect(kept.cartLineId, 'line-1');
        expect(kept.productId, 'prod-1');
        expect(kept.productVariantId, 'var-1');
        expect(kept.title, 'Linen shirt');
        expect(kept.quantity, 2);
        expect(kept.unitPrice, const Money(amount: 2500, currency: 'NPR'));
        expect(kept.kept, isTrue);
        expect(kept.change, BasketLineChange.unchanged);

        final cheaper = result.scenarios.last;
        expect(
          cheaper.difference,
          const Money(amount: -1128.87, currency: 'NPR'),
        );
        expect(cheaper.grandTotal.amount, 4521.13);
        expect(cheaper.itemsAtStockRisk, 1);
        expect(cheaper.changes, ['Linen shirt swapped for Cotton shirt']);

        final swapped = cheaper.lines.single;
        expect(swapped.cartLineId, isNull);
        expect(swapped.unitPrice.amount, 2000.5);
        expect(swapped.kept, isFalse);
        expect(swapped.change, BasketLineChange.swapped);
      },
    );

    test('sends no query values when nothing is constrained', () async {
      final api = _GetApiClient(<String, dynamic>{
        'currency': 'NPR',
        'budget': null,
        'scenarios': <dynamic>[],
      });

      final result = (await CartRemoteDataSource(
        apiClient: api,
      ).getScenarios()).toDomain();

      expect(api.query, isEmpty);
      expect(result.budget, isNull);
      expect(result.scenarios, isEmpty);
    });

    test('reads kinds and line changes sent as ints or as names', () {
      final kinds = <(Object?, BasketScenarioKind)>[
        (1, BasketScenarioKind.asItIs),
        (2, BasketScenarioKind.withinBudget),
        (3, BasketScenarioKind.lowerCost),
        (4, BasketScenarioKind.fasterDispatch),
        ('AsItIs', BasketScenarioKind.asItIs),
        ('withinBudget', BasketScenarioKind.withinBudget),
        ('LOWER_COST', BasketScenarioKind.lowerCost),
        ('Faster dispatch', BasketScenarioKind.fasterDispatch),
        ('2', BasketScenarioKind.withinBudget),
        (9, BasketScenarioKind.unknown),
        (null, BasketScenarioKind.unknown),
      ];
      for (final (raw, expected) in kinds) {
        expect(parseBasketScenarioKind(raw), expected, reason: 'kind $raw');
      }

      final changes = <(Object?, BasketLineChange)>[
        (1, BasketLineChange.unchanged),
        (2, BasketLineChange.quantityReduced),
        (3, BasketLineChange.removed),
        (4, BasketLineChange.swapped),
        ('Unchanged', BasketLineChange.unchanged),
        ('quantityReduced', BasketLineChange.quantityReduced),
        ('REMOVED', BasketLineChange.removed),
        ('Swapped', BasketLineChange.swapped),
        (0, BasketLineChange.unknown),
        ('moved', BasketLineChange.unknown),
      ];
      for (final (raw, expected) in changes) {
        expect(parseBasketLineChange(raw), expected, reason: 'change $raw');
      }
    });

    test('missing fields fall back to safe defaults', () {
      final result = BasketScenariosDto.fromJson(<String, dynamic>{
        'scenarios': [
          {
            'lines': [<String, dynamic>{}],
          },
        ],
      }).toDomain();

      expect(result.currency, 'NPR');
      expect(result.budget, isNull);

      final scenario = result.scenarios.single;
      expect(scenario.kind, BasketScenarioKind.unknown);
      expect(scenario.title, '');
      expect(scenario.feasible, isTrue);
      expect(scenario.summary, '');
      expect(scenario.changes, isEmpty);
      expect(scenario.subtotal, const Money(amount: 0, currency: 'NPR'));
      expect(scenario.grandTotal.amount, 0);
      expect(scenario.difference.amount, 0);
      expect(scenario.sellerCount, 0);
      expect(scenario.dispatchDays, 0);
      expect(scenario.itemsAtStockRisk, 0);

      final line = scenario.lines.single;
      expect(line.cartLineId, isNull);
      expect(line.productId, '');
      expect(line.productVariantId, '');
      expect(line.title, '');
      expect(line.quantity, 0);
      expect(line.unitPrice.amount, 0);
      expect(line.kept, isFalse);
      expect(line.change, BasketLineChange.unknown);
    });

    test('amounts carry the currency the response names', () {
      final result = BasketScenariosDto.fromJson(<String, dynamic>{
        'currency': 'USD',
        'scenarios': [
          {'grandTotalAmount': 12.5},
        ],
      }).toDomain();

      expect(
        result.scenarios.single.grandTotal,
        const Money(amount: 12.5, currency: 'USD'),
      );
    });
  });

  group('CartRepositoryImpl.getScenarios', () {
    late _MockCartRemoteDataSource remote;
    late CartRepositoryImpl repository;

    setUp(() {
      remote = _MockCartRemoteDataSource();
      repository = CartRepositoryImpl(remoteDataSource: remote);
    });

    void stubThrow(Object error) => when(
      () => remote.getScenarios(
        budget: any(named: 'budget'),
        keepLineIds: any(named: 'keepLineIds'),
        excludeProductIds: any(named: 'excludeProductIds'),
      ),
    ).thenThrow(error);

    test('forwards the constraints and maps the result', () async {
      Map<Symbol, dynamic>? sent;
      when(
        () => remote.getScenarios(
          budget: any(named: 'budget'),
          keepLineIds: any(named: 'keepLineIds'),
          excludeProductIds: any(named: 'excludeProductIds'),
        ),
      ).thenAnswer((invocation) async {
        sent = invocation.namedArguments;
        return BasketScenariosDto.fromJson(_payload);
      });

      final result = await repository.getScenarios(
        budget: 4500,
        keepLineIds: ['line-1'],
      );

      final scenarios = result.getOrElse(
        (_) => throw StateError('expected right'),
      );
      expect(scenarios.scenarios, hasLength(2));
      expect(sent?[#budget], 4500.0);
      expect(sent?[#keepLineIds], ['line-1']);
      expect(sent?[#excludeProductIds], isEmpty);
    });

    test('keeps the field of a 400 that rejects the budget', () async {
      stubThrow(
        _dioError(
          status: 400,
          body: <String, dynamic>{
            'title': 'Enter a budget above zero.',
            'status': 400,
            'errorCode': 'validation.invalid',
            'field': 'budget',
          },
        ),
      );

      final result = await repository.getScenarios(budget: 0);

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.validation(
          code: 'validation.invalid',
          message: 'Enter a budget above zero.',
          field: 'budget',
        ),
      );
    });

    test('maps a 401 to auth', () async {
      stubThrow(_dioError(status: 401));

      final result = await repository.getScenarios();

      expect(result.getLeft().toNullable(), const NetworkExceptions.auth());
    });

    test('maps a dropped connection to noInternetConnection', () async {
      stubThrow(_dioError(type: DioExceptionType.connectionError));

      final result = await repository.getScenarios();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
    });

    test('maps a malformed payload to unexpectedError', () async {
      stubThrow(TypeError());

      final result = await repository.getScenarios();

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.unexpectedError(),
      );
    });
  });
}
