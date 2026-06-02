import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import 'package:stylemint_mobile_frontend/core/device/device_identity.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/index.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

/// Bridges the WebAuthn platform layer ([PasskeyAuthenticator]) with the
/// StyleMint backend repository, converting between the package's types and
/// our [PasskeyChallengeDto] / [PasskeyCredentialDto] / [AuthResponseDto].
class PasskeyService {
  PasskeyService({required this.authRepository, required this.deviceIdentity})
      : _authenticator = PasskeyAuthenticator();

  final AuthRepository authRepository;
  final DeviceIdentity deviceIdentity;
  final PasskeyAuthenticator _authenticator;

  // ---------------------------------------------------------------------------
  // Registration (add a passkey for an already-logged-in user)
  // ---------------------------------------------------------------------------

  /// Full register ceremony:
  /// 1. Fetch challenge from server (`begin` options endpoint)
  /// 2. Invoke platform authenticator (Face ID / Touch ID / security key)
  /// 3. POST the attestation back (`complete` endpoint)
  Future<Either<NetworkExceptions, PasskeyCredentialDto>> register({
    required String accountId,
    String? nickname,
  }) async {
    // Step 1 — challenge
    final challengeResult = await authRepository.beginPasskeyRegistration(
      accountId: accountId,
      nickname: nickname,
    );
    if (challengeResult.isLeft()) {
      return Left<NetworkExceptions, PasskeyCredentialDto>(
        challengeResult.fold((l) => l, (_) => const NetworkExceptions.unexpectedError()),
      );
    }
    final challenge = challengeResult.getOrElse((_) => throw StateError(''));

    // Step 2 — parse options
    final RegisterRequestType platformRequest;
    try {
      platformRequest = RegisterRequestType.fromJsonString(challenge.optionsJson);
    } catch (_) {
      return const Left(NetworkExceptions.validation(code: 'PASSKEY_OPTIONS_INVALID'));
    }

    // Step 3 — platform authenticator
    final RegisterResponseType platformResponse;
    try {
      platformResponse = await _authenticator.register(platformRequest);
    } catch (e) {
      return Left<NetworkExceptions, PasskeyCredentialDto>(_mapPasskeyError(e));
    }

    // Step 4 — complete with server
    return authRepository.completePasskeyRegistration(
      accountId: accountId,
      challengeBase64Url: challenge.challengeBase64Url,
      clientResponseJson: platformResponse.toJsonString(),
      nickname: nickname,
    );
  }

  // ---------------------------------------------------------------------------
  // Authentication (sign in with passkey — no password needed)
  // ---------------------------------------------------------------------------

  /// Full authenticate ceremony:
  /// 1. Fetch challenge from server (`authenticate/options`)
  /// 2. Invoke platform authenticator
  /// 3. POST the assertion back (`authenticate/complete`)
  Future<Either<NetworkExceptions, AuthResponseDto>> authenticate(
    String accountId,
  ) async {
    // Step 1 — challenge
    final challengeResult =
        await authRepository.beginPasskeyAuthentication(accountId);
    if (challengeResult.isLeft()) {
      return Left<NetworkExceptions, AuthResponseDto>(
        challengeResult.fold((l) => l, (_) => const NetworkExceptions.unexpectedError()),
      );
    }
    final challenge = challengeResult.getOrElse((_) => throw StateError(''));

    // Step 2 — parse options
    final AuthenticateRequestType platformRequest;
    try {
      platformRequest =
          AuthenticateRequestType.fromJsonString(challenge.optionsJson);
    } catch (_) {
      return const Left(NetworkExceptions.validation(code: 'PASSKEY_OPTIONS_INVALID'));
    }

    // Step 3 — platform authenticator
    final AuthenticateResponseType platformResponse;
    try {
      platformResponse = await _authenticator.authenticate(platformRequest);
    } catch (e) {
      return Left<NetworkExceptions, AuthResponseDto>(_mapPasskeyError(e));
    }

    // Step 4 — complete with server
    return authRepository.completePasskeyAuthentication(
      accountId: accountId,
      challengeBase64Url: challenge.challengeBase64Url,
      clientResponseJson: platformResponse.toJsonString(),
    );
  }

  // ---------------------------------------------------------------------------
  // Usernameless authentication (sign in — no account id, discoverable cred)
  // ---------------------------------------------------------------------------

  /// Passkey-first sign-in. The server issues a discoverable-credential
  /// challenge, the OS presents whatever the user enrolled (Face / fingerprint /
  /// PIN), and the server resolves the account from the credential and issues a
  /// session — binding it to this device's stable fingerprint.
  Future<Either<NetworkExceptions, AuthResponseDto>>
      authenticateUsernameless() async {
    final challengeResult =
        await authRepository.beginUsernamelessPasskeyAuthentication();
    if (challengeResult.isLeft()) {
      return Left<NetworkExceptions, AuthResponseDto>(
        challengeResult.fold((l) => l, (_) => const NetworkExceptions.unexpectedError()),
      );
    }
    final challenge = challengeResult.getOrElse((_) => throw StateError(''));

    final AuthenticateRequestType platformRequest;
    try {
      platformRequest =
          AuthenticateRequestType.fromJsonString(challenge.optionsJson);
    } catch (_) {
      return const Left(NetworkExceptions.validation(code: 'PASSKEY_OPTIONS_INVALID'));
    }

    final AuthenticateResponseType platformResponse;
    try {
      platformResponse = await _authenticator.authenticate(platformRequest);
    } catch (e) {
      return Left<NetworkExceptions, AuthResponseDto>(_mapPasskeyError(e));
    }

    final fingerprint = await deviceIdentity.fingerprint();
    return authRepository.completeUsernamelessPasskeyAuthentication(
      challengeBase64Url: challenge.challengeBase64Url,
      clientResponseJson: platformResponse.toJsonString(),
      deviceFingerprint: fingerprint,
      devicePlatform: deviceIdentity.platformCode,
      deviceOsVersion: deviceIdentity.osVersion,
    );
  }

  // ---------------------------------------------------------------------------
  // Bootstrap signup (passkey-first: bare account + passkey + session)
  // ---------------------------------------------------------------------------

  /// Passkey-first signup. Creates a bare account (display name only), registers
  /// a passkey, and returns a session — all without email/password. Email/phone
  /// are collected later (progressive onboarding).
  Future<Either<NetworkExceptions, AuthResponseDto>> bootstrapSignup({
    required String displayName,
  }) async {
    final bootstrapResult =
        await authRepository.beginPasskeyBootstrap(displayName: displayName);
    if (bootstrapResult.isLeft()) {
      return Left<NetworkExceptions, AuthResponseDto>(
        bootstrapResult.fold((l) => l, (_) => const NetworkExceptions.unexpectedError()),
      );
    }
    final bootstrap = bootstrapResult.getOrElse((_) => throw StateError(''));

    final RegisterRequestType platformRequest;
    try {
      platformRequest =
          RegisterRequestType.fromJsonString(bootstrap.optionsJson);
    } catch (_) {
      return const Left(NetworkExceptions.validation(code: 'PASSKEY_OPTIONS_INVALID'));
    }

    final RegisterResponseType platformResponse;
    try {
      platformResponse = await _authenticator.register(platformRequest);
    } catch (e) {
      return Left<NetworkExceptions, AuthResponseDto>(_mapPasskeyError(e));
    }

    final fingerprint = await deviceIdentity.fingerprint();
    return authRepository.completePasskeyBootstrap(
      accountId: bootstrap.accountId,
      challengeBase64Url: bootstrap.challengeBase64Url,
      clientResponseJson: platformResponse.toJsonString(),
      deviceFingerprint: fingerprint,
      devicePlatform: deviceIdentity.platformCode,
      deviceOsVersion: deviceIdentity.osVersion,
    );
  }

  NetworkExceptions _mapPasskeyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('cancel')) return const NetworkExceptions.auth();
    if (msg.contains('not supported') || msg.contains('device')) {
      return const NetworkExceptions.validation(code: 'PASSKEY_DEVICE_NOT_SUPPORTED');
    }
    if (msg.contains('no credentials')) {
      return const NetworkExceptions.validation(code: 'PASSKEY_NO_CREDENTIALS');
    }
    return const NetworkExceptions.unexpectedError();
  }
}

final passkeyServiceProvider = Provider<PasskeyService>((ref) {
  return PasskeyService(
    authRepository: ref.watch(authRepositoryProvider),
    deviceIdentity: ref.watch(deviceIdentityProvider),
  );
});
