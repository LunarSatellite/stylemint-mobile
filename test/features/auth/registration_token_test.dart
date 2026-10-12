import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/device/device_identity.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/registration_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/registration_notifier.dart';

/// Registration proof: verify-email/-phone hand back a one-time token that
/// set-password must carry as `X-Registration-Token`, so knowing an account id
/// is no longer enough to set its first password.
void main() {
  group('AuthRemoteDataSource', () {
    test('verify-email reads registrationToken from the 200 body', () async {
      final api = _AuthPostClient(
        (_) => {
          'registrationToken': 'tok-email',
          'expiresUtc': '2026-10-12T10:15:00Z',
        },
      );
      final token = await AuthRemoteDataSource(
        apiClient: api,
      ).verifyRegistrationEmail('acc-1', 'a@b.co', '12345');

      expect(token, 'tok-email');
      expect(api.calls.single.uri, '/v1/registration/acc-1/verify-email');
    });

    test('verify-phone reads registrationToken from the 200 body', () async {
      final api = _AuthPostClient((_) => {'registrationToken': 'tok-phone'});
      final token = await AuthRemoteDataSource(
        apiClient: api,
      ).verifyRegistrationPhone('acc-1', '+9779800000000', '12345');

      expect(token, 'tok-phone');
      expect(api.calls.single.uri, '/v1/registration/acc-1/verify-phone');
    });

    test('an old backend answering 204 (no body) yields no token', () async {
      for (final body in [null, '', <String, dynamic>{}]) {
        final ds = AuthRemoteDataSource(
          apiClient: _AuthPostClient((_) => body),
        );
        expect(await ds.verifyRegistrationEmail('a', 'a@b.co', '1'), isNull);
        expect(await ds.verifyRegistrationPhone('a', '+977', '1'), isNull);
      }
    });

    test('a blank or non-string token is treated as absent', () {
      expect(
        AuthRemoteDataSource.registrationTokenFrom({'registrationToken': ' '}),
        isNull,
      );
      expect(
        AuthRemoteDataSource.registrationTokenFrom({'registrationToken': 42}),
        isNull,
      );
    });

    test('set-password sends the token as X-Registration-Token', () async {
      final api = _AuthPostClient((_) => null);
      await AuthRemoteDataSource(apiClient: api).setRegistrationPassword(
        'acc-1',
        'pw',
        registrationToken: 'tok-1',
      );

      final call = api.calls.single;
      expect(call.uri, '/v1/registration/acc-1/set-password');
      expect(call.data, {'password': 'pw'});
      expect(call.headers?['X-Registration-Token'], 'tok-1');
      // Still an anonymous call: no bearer is attached.
      expect(call.headers?['requiresToken'], false);
    });

    test('set-password without a token sends no proof header', () async {
      final api = _AuthPostClient((_) => null);
      await AuthRemoteDataSource(
        apiClient: api,
      ).setRegistrationPassword('acc-1', 'pw');

      final headers = api.calls.single.headers;
      expect(headers?.containsKey('X-Registration-Token'), isFalse);
      expect(headers?['requiresToken'], false);
    });
  });

  group('AuthRepositoryImpl.setRegistrationPassword', () {
    AuthRepositoryImpl repoAnswering(Object answer) => AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(
        apiClient: _AuthPostClient((_) => answer),
      ),
      networkInfo: _Online(),
      tokenStorage: _MockTokenStorage(),
      deviceIdentity: _MockDeviceIdentity(),
    );

    for (final code in registrationProofErrorCodes) {
      test('403 $code keeps its code', () async {
        final result = await repoAnswering(
          _dioError(403, {'errorCode': code}),
        ).setRegistrationPassword('acc-1', 'pw', registrationToken: 't');

        final failure = result.getLeft().toNullable();
        expect(failure?.validationCode, code);
        expect(RegistrationNotifier.isVerificationExpired(failure!), isTrue);
      });
    }

    test('any other 403 is still a plain auth failure', () async {
      final result = await repoAnswering(
        _dioError(403, {'errorCode': 'auth.forbidden'}),
      ).setRegistrationPassword('acc-1', 'pw');

      final failure = result.getLeft().toNullable();
      expect(failure?.isAuth, isTrue);
      expect(RegistrationNotifier.isVerificationExpired(failure!), isFalse);
    });
  });

  group('RegistrationNotifier', () {
    late _MockAuthRepository repo;
    late RegistrationNotifier notifier;

    setUp(() {
      repo = _MockAuthRepository();
      notifier = RegistrationNotifier(authRepository: repo);
      when(
        () => repo.startRegistration(
          displayName: any(named: 'displayName'),
          locale: any(named: 'locale'),
          timezone: any(named: 'timezone'),
          email: any(named: 'email'),
          phoneE164: any(named: 'phoneE164'),
          countryDialCode: any(named: 'countryDialCode'),
        ),
      ).thenAnswer((_) async => right(_startResponse));
      when(
        () => repo.setRegistrationPassword(
          any(),
          any(),
          registrationToken: any(named: 'registrationToken'),
        ),
      ).thenAnswer((_) async => right(unit));
    });

    Future<void> start() => notifier.startRegistration(
      displayName: 'Sarah',
      locale: 'en-US',
      timezone: 'Asia/Kathmandu',
      email: 'a@b.co',
      phoneE164: '+9779800000000',
      countryDialCode: '+977',
    );

    void verifyAnswers({String? email, String? phone}) {
      when(
        () => repo.verifyRegistrationEmail(any(), any(), any()),
      ).thenAnswer((_) async => right(email));
      when(
        () => repo.verifyRegistrationPhone(any(), any(), any()),
      ).thenAnswer((_) async => right(phone));
    }

    String? sentToken() =>
        verify(
              () => repo.setRegistrationPassword(
                'acc-1',
                'pw',
                registrationToken: captureAny(named: 'registrationToken'),
              ),
            ).captured.single
            as String?;

    test('sends the token of the verify call that succeeded last', () async {
      verifyAnswers(email: 'tok-email', phone: 'tok-phone');
      await start();
      await notifier.verifyEmail('11111');
      await notifier.verifyPhone('22222');
      await notifier.setPassword('pw');

      expect(sentToken(), 'tok-phone');
      expect(notifier.state, const RegistrationState.step4Success());
    });

    test('old backend (204, no token): set-password sent as before', () async {
      verifyAnswers();
      await start();
      await notifier.verifyEmail('11111');
      await notifier.verifyPhone('22222');
      await notifier.setPassword('pw');

      expect(sentToken(), isNull);
      expect(notifier.state, const RegistrationState.step4Success());
    });

    test('a 403 proof failure resumes registration for new codes', () async {
      verifyAnswers(email: 'tok-email', phone: 'tok-phone');
      when(
        () => repo.setRegistrationPassword(
          any(),
          any(),
          registrationToken: any(named: 'registrationToken'),
        ),
      ).thenAnswer(
        (_) async => left(
          const NetworkExceptions.validation(
            code: 'registration.token_invalid',
          ),
        ),
      );
      await start();
      await notifier.verifyEmail('11111');
      await notifier.verifyPhone('22222');
      await notifier.setPassword('pw');

      expect(
        notifier.state,
        RegistrationState.verificationExpired(_startResponse),
      );
      // Same email/phone re-sent to `start`: once initially, once to resume.
      verify(
        () => repo.startRegistration(
          displayName: 'Sarah',
          locale: 'en-US',
          timezone: 'Asia/Kathmandu',
          email: 'a@b.co',
          phoneE164: '+9779800000000',
          countryDialCode: '+977',
        ),
      ).called(2);
    });

    test('if new codes cannot be sent, the 403 is reported', () async {
      const expired = NetworkExceptions.validation(
        code: 'registration.proof_required',
      );
      verifyAnswers();
      when(
        () => repo.setRegistrationPassword(
          any(),
          any(),
          registrationToken: any(named: 'registrationToken'),
        ),
      ).thenAnswer((_) async => left(expired));
      await start();
      when(
        () => repo.startRegistration(
          displayName: any(named: 'displayName'),
          locale: any(named: 'locale'),
          timezone: any(named: 'timezone'),
          email: any(named: 'email'),
          phoneE164: any(named: 'phoneE164'),
          countryDialCode: any(named: 'countryDialCode'),
        ),
      ).thenAnswer(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );
      await notifier.setPassword('pw');

      expect(
        notifier.state,
        const RegistrationState.step4NetworkExceptions(expired),
      );
    });

    test('other set-password failures do not restart verification', () async {
      verifyAnswers(email: 'tok-email');
      when(
        () => repo.setRegistrationPassword(
          any(),
          any(),
          registrationToken: any(named: 'registrationToken'),
        ),
      ).thenAnswer((_) async => left(const NetworkExceptions.auth()));
      await start();
      await notifier.verifyEmail('11111');
      await notifier.setPassword('pw');

      expect(
        notifier.state,
        const RegistrationState.step4NetworkExceptions(
          NetworkExceptions.auth(),
        ),
      );
      verify(
        () => repo.startRegistration(
          displayName: any(named: 'displayName'),
          locale: any(named: 'locale'),
          timezone: any(named: 'timezone'),
          email: any(named: 'email'),
          phoneE164: any(named: 'phoneE164'),
          countryDialCode: any(named: 'countryDialCode'),
        ),
      ).called(1);
    });
  });
}

final _startResponse = RegistrationStartResponseDto(
  accountId: 'acc-1',
  emailId: 'em-1',
  phoneId: 'ph-1',
  emailOtpExpiresUtc: DateTime.utc(2026, 10, 12, 10),
  phoneOtpExpiresUtc: DateTime.utc(2026, 10, 12, 10),
);

class _AuthPostCall {
  _AuthPostCall(this.uri, this.data, this.headers);

  final String uri;
  final Object? data;
  final Map<String, dynamic>? headers;
}

/// Network-free [ApiClient] answering `authPost` from [respond]; an
/// [Exception] answer is thrown like a failed request.
class _AuthPostClient extends ApiClient {
  _AuthPostClient(this.respond) : super(dio: Dio());

  final Object? Function(_AuthPostCall call) respond;
  final List<_AuthPostCall> calls = [];

  @override
  Future<dynamic> authPost(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final call = _AuthPostCall(uri, data, options?.headers);
    calls.add(call);
    final answer = respond(call);
    if (answer is Exception) throw answer;
    return answer;
  }
}

DioException _dioError(int status, Object? body) {
  final options = RequestOptions(path: '/');
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

class _Online implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockDeviceIdentity extends Mock implements DeviceIdentity {}
