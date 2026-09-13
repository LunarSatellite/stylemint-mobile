import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_acceptance_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/repositories/orders_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.getBody, this.postBody}) : super(dio: Dio());

  final Object? getBody;
  final Object? postBody;
  String? getUri;
  String? postUri;
  Object? postData;
  Options? postOptions;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
    return getBody;
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    postOptions = options;
    return postBody;
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

const _tracking = 'SM-D-00000001';

Map<String, dynamic> _acceptanceJson({Object? outcome = 2}) =>
    <String, dynamic>{
      'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'packageId': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'trackingNumber': _tracking,
      'outcome': outcome,
      'sealIntact': false,
      'issueNote': 'The box was crushed and one mug is broken.',
      'photoUrls': ['https://cdn.example.com/a.jpg', ''],
      'recordedUtc': '2026-09-13T12:30:00+00:00',
    };

DioException _dioError(int status, {Object? body}) {
  final options = RequestOptions(path: '/v1/deliveries/$_tracking/acceptance');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(DeliveryAcceptanceOutcome.accepted));

  group('OrdersRemoteDataSource delivery acceptance', () {
    test(
      'getDeliveryPackageStatus reads state and seal from the package',
      () async {
        final api = _FakeApiClient(
          getBody: <String, dynamic>{
            'trackingNumber': _tracking,
            'state': 6,
            'sealId': 'SEAL-42',
            'sealPhotoUrl': 'https://cdn.example.com/seal.jpg',
            'hops': <dynamic>[],
          },
        );

        final status = (await OrdersRemoteDataSource(
          apiClient: api,
        ).getDeliveryPackageStatus(_tracking)).toDomain();

        expect(api.getUri, '/v1/deliveries/SM-D-00000001');
        expect(status.state, DeliveryPackageState.outForDelivery);
        expect(status.hasSeal, isTrue);
        expect(status.canRecordAcceptance, isTrue);
      },
    );

    test('a seal needs both an id and a photo; string states parse', () {
      final delivered = DeliveryPackageStatusDto.fromJson(<String, dynamic>{
        'state': 'Delivered',
        'sealId': 'SEAL-42',
        'sealPhotoUrl': '  ',
      }).toDomain();
      final inTransit = DeliveryPackageStatusDto.fromJson(<String, dynamic>{
        'state': 4,
      }).toDomain();

      expect(delivered.state, DeliveryPackageState.delivered);
      expect(delivered.hasSeal, isFalse);
      expect(delivered.canRecordAcceptance, isTrue);
      expect(inTransit.state, DeliveryPackageState.inTransit);
      expect(inTransit.canRecordAcceptance, isFalse);
    });

    test(
      'getDeliveryAcceptance calls the acceptance route and maps it',
      () async {
        final api = _FakeApiClient(getBody: _acceptanceJson());

        final acceptance = (await OrdersRemoteDataSource(
          apiClient: api,
        ).getDeliveryAcceptance(_tracking)).toDomain();

        expect(api.getUri, '/v1/deliveries/SM-D-00000001/acceptance');
        expect(acceptance.id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
        expect(acceptance.packageId, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
        expect(acceptance.trackingNumber, _tracking);
        expect(acceptance.outcome, DeliveryAcceptanceOutcome.acceptedWithIssue);
        expect(acceptance.sealIntact, isFalse);
        expect(
          acceptance.issueNote,
          'The box was crushed and one mug is broken.',
        );
        expect(acceptance.photoUrls, ['https://cdn.example.com/a.jpg']);
        expect(acceptance.recordedUtc, DateTime.utc(2026, 9, 13, 12, 30));
      },
    );

    test('int and string outcomes decode identically', () {
      final fromInt = DeliveryAcceptanceDto.fromJson(
        _acceptanceJson(outcome: 3),
      );
      final fromName = DeliveryAcceptanceDto.fromJson(
        _acceptanceJson(outcome: 'Refused'),
      );

      expect(fromInt.outcome, DeliveryAcceptanceOutcome.refused);
      expect(fromName.outcome, DeliveryAcceptanceOutcome.refused);
    });

    test('a partial record degrades to safe defaults', () {
      final acceptance = DeliveryAcceptanceDto.fromJson(
        <String, dynamic>{},
      ).toDomain();

      expect(acceptance.id, '');
      expect(acceptance.outcome, DeliveryAcceptanceOutcome.unknown);
      expect(acceptance.sealIntact, isNull);
      expect(acceptance.issueNote, isNull);
      expect(acceptance.photoUrls, isEmpty);
      expect(acceptance.recordedUtc, isNull);
    });

    test(
      'recordDeliveryAcceptance posts the answer with an Idempotency-Key',
      () async {
        final api = _FakeApiClient(postBody: _acceptanceJson());

        final dto =
            await OrdersRemoteDataSource(
              apiClient: api,
            ).recordDeliveryAcceptance(
              _tracking,
              'key-1',
              outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
              sealIntact: false,
              issueNote: '  Box crushed  ',
            );

        expect(api.postUri, '/v1/deliveries/SM-D-00000001/acceptance');
        expect(api.postData, <String, dynamic>{
          'outcome': 2,
          'sealIntact': false,
          'issueNote': 'Box crushed',
        });
        expect(api.postOptions?.headers?['Idempotency-Key'], 'key-1');
        expect(api.postOptions?.headers?['requiresToken'], isTrue);
        expect(dto.outcome, DeliveryAcceptanceOutcome.acceptedWithIssue);
      },
    );

    test('the body leaves out a missing seal answer and a blank note', () {
      expect(
        recordDeliveryAcceptanceBody(
          outcome: DeliveryAcceptanceOutcome.accepted,
          issueNote: '   ',
        ),
        <String, dynamic>{'outcome': 1},
      );
    });
  });

  group('parseDeliveryAcceptanceOutcome', () {
    test('maps backend ints, names and numeric strings', () {
      expect(
        parseDeliveryAcceptanceOutcome(1),
        DeliveryAcceptanceOutcome.accepted,
      );
      expect(
        parseDeliveryAcceptanceOutcome(2),
        DeliveryAcceptanceOutcome.acceptedWithIssue,
      );
      expect(
        parseDeliveryAcceptanceOutcome(3),
        DeliveryAcceptanceOutcome.refused,
      );
      expect(
        parseDeliveryAcceptanceOutcome('Accepted'),
        DeliveryAcceptanceOutcome.accepted,
      );
      expect(
        parseDeliveryAcceptanceOutcome('accepted_with_issue'),
        DeliveryAcceptanceOutcome.acceptedWithIssue,
      );
      expect(
        parseDeliveryAcceptanceOutcome('REFUSED'),
        DeliveryAcceptanceOutcome.refused,
      );
      expect(
        parseDeliveryAcceptanceOutcome('2'),
        DeliveryAcceptanceOutcome.acceptedWithIssue,
      );
    });

    test('unknown values map to unknown', () {
      expect(
        parseDeliveryAcceptanceOutcome(0),
        DeliveryAcceptanceOutcome.unknown,
      );
      expect(
        parseDeliveryAcceptanceOutcome(9),
        DeliveryAcceptanceOutcome.unknown,
      );
      expect(
        parseDeliveryAcceptanceOutcome('Lost'),
        DeliveryAcceptanceOutcome.unknown,
      );
      expect(
        parseDeliveryAcceptanceOutcome(null),
        DeliveryAcceptanceOutcome.unknown,
      );
    });

    test('outcome values match the backend enum', () {
      expect(DeliveryAcceptanceOutcome.accepted.value, 1);
      expect(DeliveryAcceptanceOutcome.acceptedWithIssue.value, 2);
      expect(DeliveryAcceptanceOutcome.refused.value, 3);
    });
  });

  group('parseDeliveryPackageState', () {
    test('maps every backend PackageState int value in order', () {
      const expected = [
        DeliveryPackageState.created,
        DeliveryPackageState.awaitingPickup,
        DeliveryPackageState.pickedUp,
        DeliveryPackageState.inTransit,
        DeliveryPackageState.atHandoff,
        DeliveryPackageState.outForDelivery,
        DeliveryPackageState.delivered,
        DeliveryPackageState.failedDelivery,
        DeliveryPackageState.returning,
        DeliveryPackageState.returned,
      ];
      for (var i = 0; i < expected.length; i++) {
        expect(parseDeliveryPackageState(i + 1), expected[i]);
      }
    });

    test('accepts names and rejects unknowns', () {
      expect(
        parseDeliveryPackageState('OutForDelivery'),
        DeliveryPackageState.outForDelivery,
      );
      expect(
        parseDeliveryPackageState('out_for_delivery'),
        DeliveryPackageState.outForDelivery,
      );
      expect(
        parseDeliveryPackageState('AT_HANDOFF'),
        DeliveryPackageState.atHandoff,
      );
      expect(parseDeliveryPackageState(0), DeliveryPackageState.unknown);
      expect(
        parseDeliveryPackageState('Teleported'),
        DeliveryPackageState.unknown,
      );
      expect(parseDeliveryPackageState(null), DeliveryPackageState.unknown);
    });
  });

  group('OrdersRepositoryImpl delivery acceptance', () {
    late _MockOrdersRemoteDataSource remote;

    setUp(() => remote = _MockOrdersRemoteDataSource());

    OrdersRepositoryImpl repo({bool connected = true}) => OrdersRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: _Network(connected: connected),
    );

    void stubRecord(Future<DeliveryAcceptanceDto> Function() answer) {
      when(
        () => remote.recordDeliveryAcceptance(
          any(),
          any(),
          outcome: any(named: 'outcome'),
          sealIntact: any(named: 'sealIntact'),
          issueNote: any(named: 'issueNote'),
        ),
      ).thenAnswer((_) => answer());
    }

    test('records the answer with a fresh Idempotency-Key per send', () async {
      stubRecord(() async => DeliveryAcceptanceDto.fromJson(_acceptanceJson()));

      final first = await repo().recordDeliveryAcceptance(
        _tracking,
        outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
        sealIntact: false,
        issueNote: 'Box crushed',
      );
      await repo().recordDeliveryAcceptance(
        _tracking,
        outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
        sealIntact: false,
        issueNote: 'Box crushed',
      );

      final acceptance = first.getOrElse(
        (_) => throw StateError('expected right'),
      );
      expect(acceptance.outcome, DeliveryAcceptanceOutcome.acceptedWithIssue);
      final keys = verify(
        () => remote.recordDeliveryAcceptance(
          _tracking,
          captureAny(),
          outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
          sealIntact: false,
          issueNote: 'Box crushed',
        ),
      ).captured.cast<String>();
      expect(keys, hasLength(2));
      expect(keys.first, isNotEmpty);
      expect(keys.first, isNot(keys.last));
    });

    test('maps a 404 on the acceptance read to notFound', () async {
      when(
        () => remote.getDeliveryAcceptance(_tracking),
      ).thenThrow(_dioError(404));

      final result = await repo().getDeliveryAcceptance(_tracking);

      expect(result.getLeft().toNullable(), const NetworkExceptions.notFound());
    });

    test('maps a 404 on the package read to notFound', () async {
      when(
        () => remote.getDeliveryPackageStatus(_tracking),
      ).thenThrow(_dioError(404));

      final result = await repo().getDeliveryPackageStatus(_tracking);

      expect(result.getLeft().toNullable(), const NetworkExceptions.notFound());
    });

    test('maps a 409 on record to conflict', () async {
      stubRecord(
        () => Future.error(
          _dioError(
            409,
            body: <String, dynamic>{
              'title':
                  'What you received for this parcel has already been '
                  'recorded.',
              'errorCode': 'conflict',
            },
          ),
        ),
      );

      final result = await repo().recordDeliveryAcceptance(
        _tracking,
        outcome: DeliveryAcceptanceOutcome.refused,
        issueNote: 'Wrong item',
      );

      expect(result.getLeft().toNullable(), const NetworkExceptions.conflict());
    });

    test("keeps the backend's sentence for a 400", () async {
      const sentence =
          'You can confirm a parcel once it is out for delivery or delivered.';
      stubRecord(
        () => Future.error(
          _dioError(
            400,
            body: <String, dynamic>{
              'title': sentence,
              'errorCode': 'business_rule',
            },
          ),
        ),
      );

      final result = await repo().recordDeliveryAcceptance(
        _tracking,
        outcome: DeliveryAcceptanceOutcome.accepted,
      );

      final failure = result.getLeft().toNullable()!;
      expect(failure.validationCode, 'business_rule');
      expect(NetworkExceptions.getMessage(failure), sentence);
    });

    test('maps an unexpected error to unexpectedError', () async {
      when(
        () => remote.getDeliveryAcceptance(_tracking),
      ).thenThrow(const FormatException('bad json'));

      final result = await repo().getDeliveryAcceptance(_tracking);

      expect(
        result.getLeft().toNullable(),
        const NetworkExceptions.unexpectedError(),
      );
    });

    test(
      'returns noInternetConnection without calling the API when offline',
      () async {
        final offline = repo(connected: false);

        final package = await offline.getDeliveryPackageStatus(_tracking);
        final record = await offline.recordDeliveryAcceptance(
          _tracking,
          outcome: DeliveryAcceptanceOutcome.accepted,
        );

        for (final result in [package, record]) {
          expect(
            result.getLeft().toNullable(),
            const NetworkExceptions.noInternetConnection(),
          );
        }
        verifyNever(() => remote.getDeliveryPackageStatus(any()));
        verifyNever(
          () => remote.recordDeliveryAcceptance(
            any(),
            any(),
            outcome: any(named: 'outcome'),
            sealIntact: any(named: 'sealIntact'),
            issueNote: any(named: 'issueNote'),
          ),
        );
      },
    );
  });
}
