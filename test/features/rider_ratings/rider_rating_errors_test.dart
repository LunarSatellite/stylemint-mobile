import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/data/rider_rating_error_mapper.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/data/rider_rating_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/presentation/rider_rating_messages.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/datasources/vendor_orders_remote_datasource.dart';

class _MockApiClient extends Mock implements ApiClient {}

DioException _status(int code, [Object? body]) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: code,
    data: body,
  ),
  type: DioExceptionType.badResponse,
);

Map<String, dynamic> _problem(String code) => {
  'title': 'Forbidden',
  'detail': 'Server sentence',
  'errorCode': code,
};

void main() {
  group('mapRiderRatingDioException', () {
    test('a 403 with a rider_rating code keeps the code, not "sign in"', () {
      final failure = mapRiderRatingDioException(
        _status(403, _problem('rider_rating.not_eligible')),
      );
      expect(failure.validationCode, 'rider_rating.not_eligible');
      expect(failure.isAuth, isFalse);
    });

    test('a 404 with rider_profile.not_available keeps the code', () {
      final failure = mapRiderRatingDioException(
        _status(404, _problem('rider_profile.not_available')),
      );
      expect(isRiderNotAvailable(failure), isTrue);
    });

    test('other bodies go through the shared mapper', () {
      expect(mapRiderRatingDioException(_status(404)).isNotFound, isTrue);
      expect(mapRiderRatingDioException(_status(401)).isAuth, isTrue);
      expect(
        mapRiderRatingDioException(
          _status(403, _problem('delivery.something')),
        ).isAuth,
        isTrue,
      );
    });
  });

  group('riderRatingErrorMessage', () {
    String messageFor(String code) =>
        riderRatingErrorMessage(NetworkExceptions.validation(code: code));

    test('every contract code has its own sentence', () {
      expect(messageFor('rider_rating.not_eligible'), contains("can't be rated"));
      expect(messageFor('rider_rating.window_closed'), contains('7 days'));
      expect(messageFor('rider_rating.invalid'), contains('1 to 5 stars'));
      expect(
        messageFor('rider_profile.not_available'),
        'This rider is no longer available for this parcel.',
      );
    });

    test('unknown codes of either family still read as that family', () {
      expect(messageFor('rider_rating.new_thing'), contains('rating'));
      expect(messageFor('rider_profile.new_thing'), contains('details'));
    });

    test('offline and server-down are worded, never a code', () {
      expect(
        riderRatingErrorMessage(const NetworkExceptions.noInternetConnection()),
        contains('offline'),
      );
      expect(
        riderRatingErrorMessage(const NetworkExceptions.serverUnavailable()),
        isNot(contains('rider_')),
      );
    });
  });

  group('datasources', () {
    late _MockApiClient api;

    setUpAll(() => registerFallbackValue(Options()));
    setUp(() => api = _MockApiClient());

    test('rider details: a plain 404 is "not served yet" (null)', () async {
      when(() => api.get(any<String>())).thenThrow(_status(404));
      final sut = VendorOrdersRemoteDataSource(apiClient: api);
      await expectLater(sut.getRiderProfile('sub-1', 'c-1'), completion(isNull));
    });

    test('rider details: a coded 404 is "not available"', () async {
      when(
        () => api.get(any<String>()),
      ).thenThrow(_status(404, _problem('rider_profile.not_available')));
      final sut = VendorOrdersRemoteDataSource(apiClient: api);
      await expectLater(
        sut.getRiderProfile('sub-1', 'c-1'),
        throwsA(
          isA<NetworkExceptions>().having(
            isRiderNotAvailable,
            'not available',
            isTrue,
          ),
        ),
      );
    });

    test('rating PUT goes to the role\'s path with an Idempotency-Key', () async {
      when(
        () => api.put(
          any<String>(),
          data: any<dynamic>(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => {'subOrderId': 'sub-1', 'stars': 4});
      final sut = RiderRatingRemoteDataSource(apiClient: api);
      await sut.putRating(
        role: RiderRaterRole.vendor,
        subOrderId: 'sub-1',
        body: const {'stars': 4},
        idempotencyKey: 'key-1',
      );
      final captured = verify(
        () => api.put(
          captureAny<String>(),
          data: any<dynamic>(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).captured;
      expect(captured[0], '/v1/vendor/sub-orders/sub-1/rider-rating');
      expect((captured[1] as Options).headers?['Idempotency-Key'], 'key-1');
    });

    test('my rating: a 404 is null, a coded 403 is thrown mapped', () async {
      final sut = RiderRatingRemoteDataSource(apiClient: api);
      when(() => api.get(any<String>())).thenThrow(_status(404));
      await expectLater(sut.getMyRating(), completion(isNull));

      when(
        () => api.put(
          any<String>(),
          data: any<dynamic>(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(_status(409, _problem('rider_rating.window_closed')));
      await expectLater(
        sut.putRating(
          role: RiderRaterRole.buyer,
          subOrderId: 'sub-1',
          body: const {'stars': 5},
          idempotencyKey: 'k',
        ),
        throwsA(
          isA<NetworkExceptions>().having(
            (e) => e.validationCode,
            'code',
            'rider_rating.window_closed',
          ),
        ),
      );
    });
  });
}
