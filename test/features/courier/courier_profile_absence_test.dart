import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_remote_datasource.dart';

class _MockApiClient extends Mock implements ApiClient {}

DioException _status(int code) => DioException(
  requestOptions: RequestOptions(path: '/v1/courier/by-account/acc-1'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/v1/courier/by-account/acc-1'),
    statusCode: code,
  ),
  type: DioExceptionType.badResponse,
);

/// `GET /v1/courier/by-account/{id}` answers 404 for an account that has never
/// applied, which is almost every account. The gate treats a null profile as
/// "become a courier" and an error as a failure, so letting that 404 propagate
/// showed every first-time visitor "Couldn't load your partner account — check
/// your connection" instead of the apply form.
void main() {
  late _MockApiClient api;
  late CourierRemoteDataSource sut;

  setUp(() {
    api = _MockApiClient();
    sut = CourierRemoteDataSource(apiClient: api);
  });

  test('404 means "not a courier yet", not a failure', () async {
    when(() => api.get(any())).thenThrow(_status(404));

    await expectLater(sut.getByAccount('acc-1'), completion(isNull));
  });

  test('a profile is returned as itself', () async {
    when(
      () => api.get(any()),
    ).thenAnswer((_) async => {'id': 'courier-1', 'state': 5});

    final profile = await sut.getByAccount('acc-1');

    expect(profile, isNotNull);
    expect(profile!['id'], 'courier-1');
  });

  // The other statuses must NOT be swallowed. Reporting a 401 or a 500 as
  // "you are not a courier yet" would send someone who already has a profile
  // back to the apply form and let them try to apply a second time.
  test('401 still throws — an expired session is not an absent profile', () {
    when(() => api.get(any())).thenThrow(_status(401));

    expect(() => sut.getByAccount('acc-1'), throwsA(isA<DioException>()));
  });

  test('403 still throws', () {
    when(() => api.get(any())).thenThrow(_status(403));

    expect(() => sut.getByAccount('acc-1'), throwsA(isA<DioException>()));
  });

  test('500 still throws', () {
    when(() => api.get(any())).thenThrow(_status(500));

    expect(() => sut.getByAccount('acc-1'), throwsA(isA<DioException>()));
  });
}
