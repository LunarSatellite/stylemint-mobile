import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/data/datasources/try_on_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/data/repositories/try_on_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/data/datasources/vendor_try_on_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/data/repositories/vendor_try_on_repository_impl.dart';

class _MockDio extends Mock implements Dio {}

class _Online implements NetworkInfoConnectivity {
  _Online([this.connected = true]);
  final bool connected;
  @override
  Future<bool> get isConnected async => connected;
}

Response<dynamic> _ok(String path, Object? data, [int status = 200]) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      statusCode: status,
      data: data,
    );

DioException _problem(String path, int status, Map<String, dynamic> body) =>
    DioException(
      requestOptions: RequestOptions(path: path),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: status,
        data: body,
      ),
    );

void main() {
  late _MockDio dio;
  late TryOnRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = _MockDio();
    repo = TryOnRepositoryImpl(
      remote: TryOnRemoteDataSource(apiClient: ApiClient(dio: dio)),
      networkInfo: _Online(),
    );
  });

  void stubGet(String path, Object? data) => when(
    () => dio.get<dynamic>(
      path,
      queryParameters: any(named: 'queryParameters'),
      options: any(named: 'options'),
      data: any(named: 'data'),
    ),
  ).thenAnswer((_) async => _ok(path, data));

  void stubGetThrows(String path, DioException e) => when(
    () => dio.get<dynamic>(
      path,
      queryParameters: any(named: 'queryParameters'),
      options: any(named: 'options'),
      data: any(named: 'data'),
    ),
  ).thenThrow(e);

  test('access: integer enums, plans, dates', () async {
    stubGet('/v1/try-on/access', {
      'serviceEnabled': true,
      'hasAccess': true,
      'source': 2,
      'expiresUtc': '2026-11-01T00:00:00Z',
      'trialAvailable': false,
      'freeTrialDays': 7,
      'disclaimer': 'Approximate.',
      'plans': [
        {
          'id': 'p1',
          'name': 'Monthly',
          'priceAmount': 199,
          'currency': 'NPR',
          'durationDays': 30,
          'isActive': true,
          'sortOrder': 0,
        },
      ],
    });
    final access = (await repo.getAccess()).getOrElse(
      (_) => throw StateError('x'),
    );
    expect(access.hasAccess, isTrue);
    expect(access.source, TryOnAccessSource.trial);
    expect(access.expiresUtc, DateTime.utc(2026, 11));
    expect(access.plans.single.price.amount, 199);
  });

  test('403 tryOnAccess → noAccess, tryOnDisabled → disabled', () async {
    const path = '/v1/try-on/products/p1';
    stubGetThrows(
      path,
      _problem(path, 403, {
        'errorCode': 'auth.forbidden',
        'field': 'tryOnAccess',
      }),
    );
    final f1 = (await repo.getProduct(
      'p1',
    )).swap().getOrElse((_) => throw StateError('x'));
    expect(f1.kind, TryOnFailureKind.noAccess);

    stubGetThrows(
      path,
      _problem(path, 403, {
        'errorCode': 'auth.forbidden',
        'field': 'tryOnDisabled',
      }),
    );
    final f2 = (await repo.getProduct(
      'p1',
    )).swap().getOrElse((_) => throw StateError('x'));
    expect(f2.kind, TryOnFailureKind.disabled);
  });

  test('product with its chart', () async {
    stubGet('/v1/try-on/products/p1', {
      'productId': 'p1',
      'name': 'Tee',
      'overlayImageUrl': 'https://cdn/x.png',
      'overlayWidth': 800,
      'overlayHeight': 1000,
      'garmentType': 1,
      'disclaimer': 'd',
      'sizeChart': {
        'productId': 'p1',
        'garmentType': 1,
        'unit': 2,
        'rows': [
          {'sizeLabel': 'M', 'chest': 40, 'waist': null},
        ],
        'fitNote': null,
        'updatedUtc': '2026-10-01T00:00:00Z',
      },
    });
    final p = (await repo.getProduct(
      'p1',
    )).getOrElse((_) => throw StateError('x'));
    expect(p.overlayAspect, 1.25);
    expect(p.sizeChart!.unit, MeasurementUnit.inch);
    expect(p.sizeChart!.rows.single[SizeMeasure.chest], 40);
    expect(p.sizeChart!.rows.single[SizeMeasure.waist], isNull);
  });

  test('measurements 404 reads as "none yet"', () async {
    const path = '/v1/try-on/me/measurements';
    stubGetThrows(path, _problem(path, 404, {'errorCode': 'not_found'}));
    final r = await repo.getMeasurements();
    expect(r.isRight(), isTrue);
    expect(r.getOrElse((_) => throw StateError('x')), isNull);
  });

  test('fit: verdicts and notes', () async {
    stubGet('/v1/try-on/products/p1/fit', {
      'productId': 'p1',
      'recommendedSize': 'M',
      'confidence': 0.8,
      'perSize': [
        {
          'sizeLabel': 'S',
          'verdict': 1,
          'notes': ['Chest about 4 cm tight'],
        },
        {'sizeLabel': 'M', 'verdict': 3, 'notes': <String>[]},
      ],
      'missingMeasurements': ['hipsCm'],
      'basedOn': 'Your chest 96 cm',
    });
    final fit = (await repo.getFit(
      'p1',
    )).getOrElse((_) => throw StateError('x'));
    expect(fit.recommendedSize, 'M');
    expect(fit.fitFor('s')!.verdict, FitVerdict.tooSmall);
    expect(fit.fitFor('S')!.notes.single, contains('tight'));
    expect(fit.missingMeasurements, ['hipsCm']);
  });

  test(
    'subscribe sends planId + integer paymentMethod + Idempotency-Key',
    () async {
      when(
        () => dio.post<dynamic>(
          '/v1/try-on/subscriptions',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _ok('/v1/try-on/subscriptions', {
          'subscription': {
            'id': 's1',
            'planId': 'p1',
            'planName': 'Monthly',
            'source': 3,
            'state': 1,
            'priceAmount': 199,
            'currency': 'NPR',
            'createdUtc': '2026-10-14T00:00:00Z',
          },
          'payment': {'redirectUrl': 'https://esewa/pay'},
        }),
      );
      final start = (await repo.subscribe(
        planId: 'p1',
        rail: TryOnPaymentRail.eSewa,
        idempotencyKey: 'key-1',
      )).getOrElse((_) => throw StateError('x'));
      expect(start.subscription.state, TryOnSubscriptionState.pendingPayment);
      expect(start.redirectUrl, 'https://esewa/pay');

      final captured = verify(
        () => dio.post<dynamic>(
          '/v1/try-on/subscriptions',
          data: captureAny(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: captureAny(named: 'options'),
        ),
      ).captured;
      expect(captured[0], {'planId': 'p1', 'paymentMethod': 3});
      expect((captured[1] as Options).headers!['Idempotency-Key'], 'key-1');
    },
  );

  test('409 on trial keeps the code', () async {
    when(
      () => dio.post<dynamic>(
        '/v1/try-on/trial',
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      _problem('/v1/try-on/trial', 409, {'errorCode': 'state.conflict'}),
    );
    final f = (await repo.startTrial(idempotencyKey: 'k')).swap().getOrElse(
      (_) => throw StateError('x'),
    );
    expect(f.kind, TryOnFailureKind.conflict);
    expect(f.displayMessage, contains('already used'));
  });

  test('offline never calls the API', () async {
    final offline = TryOnRepositoryImpl(
      remote: TryOnRemoteDataSource(apiClient: ApiClient(dio: dio)),
      networkInfo: _Online(false),
    );
    final r = await offline.getAccess();
    expect(
      r.swap().getOrElse((_) => throw StateError('x')).kind,
      TryOnFailureKind.offline,
    );
    verifyZeroInteractions(dio);
  });

  group('vendor', () {
    late VendorTryOnRepositoryImpl vendor;
    setUp(() {
      vendor = VendorTryOnRepositoryImpl(
        remote: VendorTryOnRemoteDataSource(apiClient: ApiClient(dio: dio)),
        networkInfo: _Online(),
      );
    });

    test('PUT size chart writes camelCase + integer enums', () async {
      when(
        () => dio.put<dynamic>(
          '/v1/vendor/products/p1/size-chart',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (inv) async => _ok('', {
          ...(inv.namedArguments[#data] as Map<String, dynamic>),
          'productId': 'p1',
          'updatedUtc': '2026-10-14T00:00:00Z',
        }),
      );
      const chart = SizeChart(
        garmentType: GarmentType.bottom,
        unit: MeasurementUnit.cm,
        rows: [
          SizeChartRow(sizeLabel: ' 30 ', values: {SizeMeasure.waist: 76}),
        ],
        fitNote: '  ',
      );
      final saved = (await vendor.saveSizeChart(
        'p1',
        chart,
        idempotencyKey: 'k',
      )).getOrElse((_) => throw StateError('x'));
      expect(saved.garmentType, GarmentType.bottom);
      final body =
          verify(
                () => dio.put<dynamic>(
                  '/v1/vendor/products/p1/size-chart',
                  data: captureAny(named: 'data'),
                  queryParameters: any(named: 'queryParameters'),
                  options: any(named: 'options'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(body['garmentType'], 2);
      expect(body['unit'], 1);
      expect(body['fitNote'], isNull);
      final row = (body['rows'] as List).single as Map<String, dynamic>;
      expect(row['sizeLabel'], '30');
      expect(row['waist'], 76);
      expect(row.containsKey('footLength'), isTrue);
    });

    test('size chart 404 is "none yet"; readiness parses', () async {
      const path = '/v1/vendor/products/p1/size-chart';
      stubGetThrows(path, _problem(path, 404, {}));
      expect(
        (await vendor.getSizeChart(
          'p1',
        )).getOrElse((_) => throw StateError('x')),
        isNull,
      );
      stubGet('/v1/vendor/products/p1/try-on', {
        'productId': 'p1',
        'hasSizeChart': false,
        'hasTryOnImage': true,
        'ready': false,
        'garmentType': null,
        'imageUrl': 'u',
        'problems': ['Add a size chart.'],
      });
      final r = (await vendor.getReadiness(
        'p1',
      )).getOrElse((_) => throw StateError('x'));
      expect(r.hasTryOnImage, isTrue);
      expect(r.garmentType, isNull);
      expect(r.problems.single, 'Add a size chart.');
    });

    test('image upload 400 keeps the server message and field', () async {
      when(
        () => dio.post<dynamic>(
          '/v1/vendor/products/p1/try-on-image',
          data: any(named: 'data'),
          options: any(named: 'options'),
          onSendProgress: any(named: 'onSendProgress'),
        ),
      ).thenThrow(
        _problem('', 400, {
          'errorCode': 'validation.invalid_format',
          'field': 'file',
          'title': 'The image must have a transparent background.',
        }),
      );
      // postFile reads the file first; use this test file as a stand-in.
      final r = await vendor.uploadTryOnImage(
        'p1',
        'test/features/customer/try_on/try_on_repository_test.dart',
        idempotencyKey: 'k',
      );
      final f = r.swap().getOrElse((_) => throw StateError('x'));
      expect(f.kind, TryOnFailureKind.rejected);
      expect(f.field, 'file');
      expect(f.message, contains('transparent'));
    });
  });
}
