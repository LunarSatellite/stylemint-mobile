import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_return_record_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_return_record.dart';

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
  'categoryId': 'c-totes',
  'windowDays': 180,
  'orderingApplied': true,
  'orderingSkippedReason': null,
  'basis': {
    'categoryId': 'c-totes',
    'available': true,
    'unavailableReason': null,
    'productsCounted': 42,
    'unitsSold': 12400,
    'unitsReturned': 620,
    'returnsPerHundredSold': 5,
  },
  'options': [
    {
      'position': 1,
      'suppliedPosition': 2,
      'productId': 'p-alt',
      'productName': '  Canvas tote  ',
      'hasEnoughSales': true,
      'unitsSold': 412,
      'unitsReturned': 12,
      'returnsPerHundredSold': 3,
      'comparedWithCategory': 'BelowCategoryTypical',
      'returnedUnits': {
        'classifiedReturns': 10,
        'fitToResell': 7,
        'notFitToResell': 3,
      },
      'facts': [
        '12 of the 412 sold in the last 180 days came back.',
        '   ',
        42,
      ],
    },
    {
      'position': 2,
      'suppliedPosition': 1,
      'productId': 'p-viewed',
      'productName': 'Leather tote',
      'hasEnoughSales': true,
      'unitsSold': 260,
      'unitsReturned': 31,
      'returnsPerHundredSold': 12,
      'comparedWithCategory': 'AboveCategoryTypical',
      'returnedUnits': null,
      'facts': <String>[],
    },
    {
      // Below the product minimum. The server would not send a rate here;
      // this one does, to prove the app drops it anyway.
      'position': 3,
      'suppliedPosition': 3,
      'productId': 'p-new',
      'productName': 'Jute tote',
      'hasEnoughSales': false,
      'unitsSold': 8,
      'unitsReturned': 1,
      'returnsPerHundredSold': 13,
      'comparedWithCategory': 'NotEnoughData',
      'returnedUnits': null,
      'facts': ['Fewer than 50 sold in the last 180 days.'],
    },
    {'productId': '', 'productName': 'Nameless'},
  ],
};

ProductReturnRecord _parse([Map<String, dynamic> json = _payload]) =>
    ProductReturnRecordDto.fromJson(json).toDomain();

ProductReturnOption _optionById(ProductReturnRecord record, String id) =>
    record.options.firstWhere((o) => o.productId == id);

void main() {
  group('ProductReturnRecordDto', () {
    test('reads the record and its within-category basis', () {
      final record = _parse();

      expect(record.productId, 'p-viewed');
      expect(record.categoryId, 'c-totes');
      expect(record.windowDays, 180);
      expect(record.orderingApplied, isTrue);
      expect(record.orderingSkippedReason, isNull);
      expect(record.basis.available, isTrue);
      expect(record.basis.productsCounted, 42);
      expect(record.basis.unitsSold, 12400);
      expect(record.basis.unitsReturned, 620);
      expect(record.basis.returnsPerHundredSold, 5);
      expect(record.basis.hasQuotableRate, isTrue);
    });

    test('reads one option in full, trimming its name and facts', () {
      final option = _optionById(_parse(), 'p-alt');

      expect(option.productName, 'Canvas tote');
      expect(option.position, 1);
      expect(option.suppliedPosition, 2);
      expect(option.hasEnoughSales, isTrue);
      expect(option.unitsSold, 412);
      expect(option.unitsReturned, 12);
      expect(option.returnsPerHundredSold, 3);
      expect(
        option.comparedWithCategory,
        CategoryComparison.belowCategoryTypical,
      );
      expect(option.returnedUnits?.classifiedReturns, 10);
      expect(option.returnedUnits?.fitToResell, 7);
      expect(option.returnedUnits?.notFitToResell, 3);
      // Blanks and non-strings are dropped; no placeholder takes their place.
      expect(option.facts, [
        '12 of the 412 sold in the last 180 days came back.',
      ]);
      expect(option.hasQuotableRate, isTrue);
    });

    test('drops a rate the product has not sold enough to support, even '
        'when the payload carries one', () {
      final option = _optionById(_parse(), 'p-new');

      expect(option.hasEnoughSales, isFalse);
      expect(option.returnsPerHundredSold, isNull);
      expect(option.hasQuotableRate, isFalse);
      expect(option.comparedWithCategory, CategoryComparison.notEnoughData);
    });

    test('drops a rate with no denominator behind it', () {
      final record = _parse({
        ..._payload,
        'options': [
          {
            'productId': 'p-zero',
            'productName': 'Zero tote',
            'hasEnoughSales': true,
            'unitsSold': 0,
            'unitsReturned': 0,
            'returnsPerHundredSold': 0,
            'comparedWithCategory': 'AboutCategoryTypical',
          },
        ],
      });

      expect(record.options.single.returnsPerHundredSold, isNull);
      expect(record.options.single.hasQuotableRate, isFalse);
      expect(record.hasQuotableOptions, isFalse);
    });

    test('quotableOptions keeps only options with a rate and its counts', () {
      final record = _parse();

      expect(record.hasQuotableOptions, isTrue);
      expect(
        record.quotableOptions.map((o) => o.productId),
        ['p-alt', 'p-viewed'],
      );
    });

    test('drops options with no product id', () {
      expect(_parse().options.map((o) => o.productId), [
        'p-alt',
        'p-viewed',
        'p-new',
      ]);
    });

    group('returnedUnits', () {
      ProductReturnOption parseSplit(Object? raw) => _parse({
        ..._payload,
        'options': [
          {
            'productId': 'p-split',
            'productName': 'Split tote',
            'hasEnoughSales': true,
            'unitsSold': 100,
            'unitsReturned': 9,
            'returnsPerHundredSold': 9,
            'comparedWithCategory': 'AboutCategoryTypical',
            'returnedUnits': raw,
          },
        ],
      }).options.single;

      test('is null when absent — never a row of zeros', () {
        expect(parseSplit(null).returnedUnits, isNull);
      });

      test('is null when a count is missing rather than assumed zero', () {
        expect(
          parseSplit(const {'classifiedReturns': 10, 'fitToResell': 7})
              .returnedUnits,
          isNull,
        );
      });

      test('is null when nothing was classified', () {
        expect(
          parseSplit(const {
            'classifiedReturns': 0,
            'fitToResell': 0,
            'notFitToResell': 0,
          }).returnedUnits,
          isNull,
        );
      });
    });

    group('basis', () {
      test('carries no rate while unavailable, only the reason', () {
        final record = _parse({
          ..._payload,
          'basis': {
            'categoryId': 'c-totes',
            'available': false,
            'unavailableReason':
                'This category has not sold enough in the last 180 days to '
                'compare against (312 of the 500 needed).',
            'productsCounted': 3,
            'unitsSold': 312,
            'unitsReturned': 9,
            'returnsPerHundredSold': 3,
          },
        });

        expect(record.basis.available, isFalse);
        expect(record.basis.returnsPerHundredSold, isNull);
        expect(record.basis.hasQuotableRate, isFalse);
        expect(record.basis.unavailableReason, contains('500 needed'));
      });

      test('survives a payload with no basis at all', () {
        final record = _parse({..._payload, 'basis': null});

        expect(record.basis.available, isFalse);
        expect(record.basis.returnsPerHundredSold, isNull);
        expect(record.basis.unavailableReason, isNull);
      });
    });
  });

  group('parseCategoryComparison', () {
    test('reads the enum names the server sends', () {
      expect(
        parseCategoryComparison('NotEnoughData'),
        CategoryComparison.notEnoughData,
      );
      expect(
        parseCategoryComparison('belowcategorytypical'),
        CategoryComparison.belowCategoryTypical,
      );
      expect(
        parseCategoryComparison('AboutCategoryTypical'),
        CategoryComparison.aboutCategoryTypical,
      );
      expect(
        parseCategoryComparison('AboveCategoryTypical'),
        CategoryComparison.aboveCategoryTypical,
      );
    });

    test('tolerates the underlying enum ints', () {
      expect(parseCategoryComparison(0), CategoryComparison.notEnoughData);
      expect(
        parseCategoryComparison(1),
        CategoryComparison.belowCategoryTypical,
      );
      expect(
        parseCategoryComparison(2),
        CategoryComparison.aboutCategoryTypical,
      );
      expect(
        parseCategoryComparison(3),
        CategoryComparison.aboveCategoryTypical,
      );
    });

    test('degrades an unrecognised value to unknown, never to a middle '
        'value', () {
      for (final raw in <Object?>[
        null,
        '',
        'WellBelowEverything',
        99,
        -1,
        <String, dynamic>{},
      ]) {
        expect(
          parseCategoryComparison(raw),
          CategoryComparison.unknown,
          reason: '$raw',
        );
        expect(parseCategoryComparison(raw).isStated, isFalse);
      }
    });

    test('only the three measured comparisons are stated', () {
      expect(CategoryComparison.belowCategoryTypical.isStated, isTrue);
      expect(CategoryComparison.aboutCategoryTypical.isStated, isTrue);
      expect(CategoryComparison.aboveCategoryTypical.isStated, isTrue);
      expect(CategoryComparison.notEnoughData.isStated, isFalse);
      expect(CategoryComparison.unknown.isStated, isFalse);
    });
  });

  group('DiscoveryRemoteDataSource.getReturnRecord', () {
    test('calls the within-category return-record route', () async {
      final client = _GetApiClient(_payload);
      final dto = await DiscoveryRemoteDataSource(
        apiClient: client,
      ).getReturnRecord('p-viewed');

      expect(client.getUri, '/v1/public/products/p-viewed/return-record');
      expect(client.query, {'maxAlternatives': 4});
      expect(dto.toDomain().productId, 'p-viewed');
    });

    test('passes maxAlternatives through', () async {
      final client = _GetApiClient(_payload);
      await DiscoveryRemoteDataSource(
        apiClient: client,
      ).getReturnRecord('p-viewed', maxAlternatives: 2);

      expect(client.query, {'maxAlternatives': 2});
    });
  });

  group('DiscoveryRepositoryImpl.getReturnRecord', () {
    late _MockDiscoveryRemoteDataSource remote;

    setUp(() => remote = _MockDiscoveryRemoteDataSource());

    DiscoveryRepositoryImpl repository({bool connected = true}) =>
        DiscoveryRepositoryImpl(
          remoteDataSource: remote,
          networkInfo: _Network(connected: connected),
        );

    test('maps the payload to the domain record', () async {
      when(
        () => remote.getReturnRecord('p-viewed'),
      ).thenAnswer((_) async => ProductReturnRecordDto.fromJson(_payload));

      final result = await repository().getReturnRecord('p-viewed');

      expect(
        result.getRight().toNullable()?.quotableOptions.length,
        2,
      );
    });

    test('is a left when offline, without calling the network', () async {
      final result = await repository(
        connected: false,
      ).getReturnRecord('p-viewed');

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
      verifyNever(() => remote.getReturnRecord(any()));
    });

    test('maps a transport failure to a network exception', () async {
      when(() => remote.getReturnRecord('p-viewed')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          response: Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 404,
          ),
        ),
      );

      final result = await repository().getReturnRecord('p-viewed');

      expect(result.isLeft(), isTrue);
    });
  });
}
