import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/device/device_identity.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/index.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/role_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.tokenStorage,
    required this.deviceIdentity,
  });

  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;
  final TokenStorage tokenStorage;
  final DeviceIdentity deviceIdentity;

  Future<void> _persist(AuthResponseDto auth) {
    return tokenStorage.saveSession(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      accessExpiresUtc: auth.accessExpiresUtc.toUtc(),
      refreshExpiresUtc: auth.refreshExpiresUtc.toUtc(),
      accountId: auth.accountId,
      sessionId: auth.sessionId,
    );
  }

  // ==========================================================================
  // OTP login
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, OtpLoginRequestedDto>> requestOtpLogin({
    required String identifierType,
    required String identifier,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.requestOtpLogin(
          identifierType: identifierType,
          identifier: identifier,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, AuthResponseDto>> verifyOtpLogin({
    required String identifierType,
    required String identifier,
    required String code,
    String? deviceId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final auth = await remoteDataSource.verifyOtpLogin(
          identifierType: identifierType,
          identifier: identifier,
          code: code,
          deviceId: deviceId,
          deviceFingerprint: await deviceIdentity.fingerprint(),
          devicePlatform: deviceIdentity.platformCode,
          deviceOsVersion: deviceIdentity.osVersion,
        );
        await _persist(auth);
        return right(auth);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Password login
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, AuthResponseDto>> login({
    required String identifierType,
    required String identifier,
    required String password,
    String? deviceId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final auth = await remoteDataSource.login(
          identifierType: identifierType,
          identifier: identifier,
          password: password,
          deviceId: deviceId,
          deviceFingerprint: await deviceIdentity.fingerprint(),
          devicePlatform: deviceIdentity.platformCode,
          deviceOsVersion: deviceIdentity.osVersion,
        );
        await _persist(auth);
        return right(auth);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Magic link login
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, MagicLoginRequestedDto>> requestMagicLogin({
    required String email,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.requestMagicLogin(
          email: email,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, AuthResponseDto>> consumeMagicLogin({
    required String token,
    String? deviceId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final auth = await remoteDataSource.consumeMagicLogin(
          token: token,
          deviceId: deviceId,
          deviceFingerprint: await deviceIdentity.fingerprint(),
          devicePlatform: deviceIdentity.platformCode,
          deviceOsVersion: deviceIdentity.osVersion,
        );
        await _persist(auth);
        return right(auth);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Password reset
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, PasswordResetRequestedDto>>
      requestPasswordReset({
    required String email,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.requestPasswordReset(
          email: email,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> consumePasswordReset({
    required String token,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.consumePasswordReset(
          token: token,
          newPassword: newPassword,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Token lifecycle
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, AuthResponseDto>> refresh({
    required String refreshToken,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final auth = await remoteDataSource.refresh(
          refreshToken: refreshToken,
        );
        await _persist(auth);
        return right(auth);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> logout({
    bool allSessions = false,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final rt = await tokenStorage.refreshToken;
        try {
          await remoteDataSource.logout(
            refreshToken: rt,
            allSessions: allSessions,
          );
        } finally {
          await tokenStorage.clear();
        }
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      await tokenStorage.clear();
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> sessionPing() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sessionPing();
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // OAuth / social
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, OAuthAuthorizeResultDto>> oauthAuthorize({
    required String provider,
    required String redirectUri,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.oauthAuthorize(
          provider: provider,
          redirectUri: redirectUri,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, OAuthCallbackResultDto>> oauthCallback({
    required String code,
    required String state,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.oauthCallback(
          code: code,
          state: state,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Accounts
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, AccountDto>> getAccount(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getAccount(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, AccountDto>> registerAccount({
    String? displayName,
    String? locale,
    String? timezone,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.registerAccount(
          displayName: displayName,
          locale: locale,
          timezone: timezone,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, AccountDto>> updateProfile({
    required String accountId,
    String? displayName,
    String? locale,
    String? timezone,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
    String? countryCode,
    String? rowVersion,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateProfile(
          accountId: accountId,
          displayName: displayName,
          locale: locale,
          timezone: timezone,
          dateOfBirth: dateOfBirth,
          gender: gender,
          avatarUrl: avatarUrl,
          countryCode: countryCode,
          rowVersion: rowVersion,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Registration
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, RegistrationStartResponseDto>>
      startRegistration({
    required String displayName,
    required String locale,
    required String timezone,
    required String email,
    required String phoneE164,
    required String countryDialCode,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.startRegistration(
          displayName: displayName,
          locale: locale,
          timezone: timezone,
          email: email,
          phoneE164: phoneE164,
          countryDialCode: countryDialCode,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> verifyRegistrationEmail(
    String accountId,
    String email,
    String code,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyRegistrationEmail(
          accountId,
          email,
          code,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> verifyRegistrationPhone(
    String accountId,
    String phoneE164,
    String code,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyRegistrationPhone(
          accountId,
          phoneE164,
          code,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> setRegistrationPassword(
    String accountId,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.setRegistrationPassword(
          accountId,
          password,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, RegistrationCompletionDto>>
      acceptRegistrationTerms(
    String accountId, {
    required String consentVersion,
    String? ipAddress,
    String? userAgent,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.acceptRegistrationTerms(
          accountId,
          consentVersion: consentVersion,
          ipAddress: ipAddress,
          userAgent: userAgent,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Sessions
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<UserSessionDto>>> listSessions(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listSessions(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> revokeSession({
    required String accountId,
    required String sessionId,
    String? reason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.revokeSession(
          accountId: accountId,
          sessionId: sessionId,
          reason: reason,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, int>> revokeAllSessions(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.revokeAllSessions(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Devices
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<DeviceDto>>> listDevices(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listDevices(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, DeviceDto>> registerDevice({
    required String accountId,
    String? deviceFingerprint,
    String? platform,
    String? model,
    String? osVersion,
    String? appVersion,
    String? nickname,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.registerDevice(
          accountId: accountId,
          deviceFingerprint: deviceFingerprint,
          platform: platform,
          model: model,
          osVersion: osVersion,
          appVersion: appVersion,
          nickname: nickname,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> trustDevice({
    required String accountId,
    required String deviceId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.trustDevice(
          accountId: accountId,
          deviceId: deviceId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> untrustDevice({
    required String accountId,
    required String deviceId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.untrustDevice(
          accountId: accountId,
          deviceId: deviceId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> revokeDevice({
    required String accountId,
    required String deviceId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.revokeDevice(
          accountId: accountId,
          deviceId: deviceId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> renameDevice({
    required String accountId,
    required String deviceId,
    required String nickname,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.renameDevice(
          accountId: accountId,
          deviceId: deviceId,
          nickname: nickname,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Passkeys
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<PasskeyCredentialDto>>> listPasskeys(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listPasskeys(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, PasskeyChallengeDto>>
      beginPasskeyRegistration({
    required String accountId,
    String? nickname,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.beginPasskeyRegistration(
          accountId: accountId,
          nickname: nickname,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, PasskeyCredentialDto>>
      completePasskeyRegistration({
    required String accountId,
    required String challengeBase64Url,
    required String clientResponseJson,
    String? nickname,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.completePasskeyRegistration(
          accountId: accountId,
          challengeBase64Url: challengeBase64Url,
          clientResponseJson: clientResponseJson,
          nickname: nickname,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, PasskeyChallengeDto>>
      beginPasskeyAuthentication(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.beginPasskeyAuthentication(
          accountId,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, AuthResponseDto>>
      completePasskeyAuthentication({
    required String accountId,
    required String challengeBase64Url,
    required String clientResponseJson,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final body = await remoteDataSource.completePasskeyAuthentication(
          accountId: accountId,
          challengeBase64Url: challengeBase64Url,
          clientResponseJson: clientResponseJson,
        );
        if (body == null) {
          return left(NetworkExceptions.formatException());
        }
        final auth = AuthResponseDto.fromJson(body);
        await _persist(auth);
        return right(auth);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> deletePasskey({
    required String accountId,
    required String credentialId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePasskey(
          accountId: accountId,
          credentialId: credentialId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Usernameless passkey login + bootstrap signup
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, PasskeyChallengeDto>>
      beginUsernamelessPasskeyAuthentication() async {
    if (await networkInfo.isConnected) {
      try {
        final response =
            await remoteDataSource.beginUsernamelessPasskeyAuthentication();
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, AuthResponseDto>>
      completeUsernamelessPasskeyAuthentication({
    required String challengeBase64Url,
    required String clientResponseJson,
    required String deviceFingerprint,
    required int devicePlatform,
    String? deviceOsVersion,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final body =
            await remoteDataSource.completeUsernamelessPasskeyAuthentication(
          challengeBase64Url: challengeBase64Url,
          clientResponseJson: clientResponseJson,
          deviceFingerprint: deviceFingerprint,
          devicePlatform: devicePlatform,
          deviceOsVersion: deviceOsVersion,
        );
        if (body == null) return left(NetworkExceptions.formatException());
        final auth = AuthResponseDto.fromJson(body);
        await _persist(auth);
        return right(auth);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, PasskeyBootstrapDto>> beginPasskeyBootstrap({
    required String displayName,
    String locale = 'en-US',
    String timezone = 'Asia/Kathmandu',
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.beginPasskeyBootstrap(
          displayName: displayName,
          locale: locale,
          timezone: timezone,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, AuthResponseDto>> completePasskeyBootstrap({
    required String accountId,
    required String challengeBase64Url,
    required String clientResponseJson,
    required String deviceFingerprint,
    required int devicePlatform,
    String? deviceOsVersion,
    String? nickname,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final body = await remoteDataSource.completePasskeyBootstrap(
          accountId: accountId,
          challengeBase64Url: challengeBase64Url,
          clientResponseJson: clientResponseJson,
          deviceFingerprint: deviceFingerprint,
          devicePlatform: devicePlatform,
          deviceOsVersion: deviceOsVersion,
          nickname: nickname,
        );
        if (body == null) return left(NetworkExceptions.formatException());
        final auth = AuthResponseDto.fromJson(body);
        await _persist(auth);
        return right(auth);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // MFA / TOTP
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<MfaMethodDto>>> listMfaMethods(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listMfaMethods(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, TotpEnrollmentDto>> beginTotpEnrollment(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.beginTotpEnrollment(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, MfaMethodDto>> confirmTotp({
    required String accountId,
    required String methodId,
    required String code,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.confirmTotp(
          accountId: accountId,
          methodId: methodId,
          code: code,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> disableMfa({
    required String accountId,
    required String methodId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.disableMfa(
          accountId: accountId,
          methodId: methodId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> setPrimaryMfa({
    required String accountId,
    required String methodId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.setPrimaryMfa(
          accountId: accountId,
          methodId: methodId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> renameMfa({
    required String accountId,
    required String methodId,
    required String label,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.renameMfa(
          accountId: accountId,
          methodId: methodId,
          label: label,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Handles
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<HandleDto>>> listHandles(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listHandles(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, HandleDto>> registerHandle({
    required String accountId,
    required String handle,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.registerHandle(
          accountId: accountId,
          handle: handle,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> activateHandle({
    required String accountId,
    required String handleId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.activateHandle(
          accountId: accountId,
          handleId: handleId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> deactivateHandle({
    required String accountId,
    required String handleId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deactivateHandle(
          accountId: accountId,
          handleId: handleId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Interests
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<InterestDto>>> listInterests(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listInterests(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<InterestDto>>> listPublicInterests() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listPublicInterests();
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> addInterest({
    required String accountId,
    required String categoryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addInterest(
          accountId: accountId,
          categoryId: categoryId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> removeInterest({
    required String accountId,
    required String categoryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.removeInterest(
          accountId: accountId,
          categoryId: categoryId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Blocked users
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<BlockedUserDto>>> listBlockedUsers(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listBlockedUsers(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, BlockedUserDto>> blockUser({
    required String accountId,
    required String blockedAccountId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.blockUser(
          accountId: accountId,
          blockedAccountId: blockedAccountId,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> unblockUser({
    required String accountId,
    required String blockedAccountId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.unblockUser(
          accountId: accountId,
          blockedAccountId: blockedAccountId,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // External IDs
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<ExternalIdDto>>> listExternalIds(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listExternalIds(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, ExternalIdDto>> linkExternalId({
    required String accountId,
    required String provider,
    Map<String, dynamic>? additionalData,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.linkExternalId(
          accountId: accountId,
          provider: provider,
          additionalData: additionalData,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> unlinkExternalId({
    required String accountId,
    required String provider,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.unlinkExternalId(
          accountId: accountId,
          provider: provider,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Marketing consents
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<MarketingConsentDto>>>
      listMarketingConsents(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.listMarketingConsents(
          accountId,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<MarketingConsentDto>>>
      getCurrentMarketingConsents(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getCurrentMarketingConsents(
          accountId,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> toggleMarketingConsent({
    required String accountId,
    required String category,
    required bool consented,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.toggleMarketingConsent(
          accountId: accountId,
          category: category,
          consented: consented,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Account pause
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, AccountPauseDto>> getPause() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getPause();
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> pause({required int days}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.pause(days: days);
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> resume() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resume();
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Roles
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, List<RoleProfileDto>>> getRoles(
    String accountId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getRoles(accountId);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, RoleProfileDto>> requestRole(
    String accountId,
    int role,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.requestRole(accountId, role);
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> activateRole(
    String accountId,
    int role,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.activateRole(accountId, role);
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Password management
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, Unit>> changePassword({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.changePassword(
          accountId: accountId,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, bool>> verifyPassword(
    String accountId,
    String password,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.verifyPassword(
          accountId,
          password,
        );
        return right(response);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // ==========================================================================
  // Account deletion
  // ==========================================================================

  @override
  Future<Either<NetworkExceptions, Unit>> deleteAccount(
    String accountId,
    String idempotencyKey,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteAccount(
          accountId: accountId,
          idempotencyKey: idempotencyKey,
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }
}
