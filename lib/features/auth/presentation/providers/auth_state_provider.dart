import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/device/device_identity.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/auth_response_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/magic_link_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/otp_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/passkey_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/services/passkey_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

part 'auth_state_provider.freezed.dart';

// ============================================================================
// PROVIDERS - Dependency Injection
// ============================================================================

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final remoteDatasource = AuthRemoteDataSource(apiClient: client);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDatasource,
    networkInfo: NetworkInfoConnectivityImpl(
      connectivity: Connectivity(),
    ),
    tokenStorage: ref.watch(tokenStorageProvider),
    deviceIdentity: ref.watch(deviceIdentityProvider),
  );
});

// ============================================================================
// STATE — Freezed unions (initial / loadInProgress / loadSuccess / loadFailure)
// ============================================================================

/// OTP request flow state. `abstract` (not `sealed`) so when()/maybeWhen() gen.
@freezed
abstract class OtpRequestState with _$OtpRequestState {
  const OtpRequestState._();

  const factory OtpRequestState.initial() = _OtpRequestInitial;
  const factory OtpRequestState.loadInProgress() = _OtpRequestInProgress;
  const factory OtpRequestState.loadSuccess(OtpLoginRequestedDto otp) =
      _OtpRequestSuccess;
  const factory OtpRequestState.loadFailure(NetworkExceptions failure) =
      _OtpRequestNetworkExceptions;

  /// Convenience for buttons/fields that just need a spinner flag.
  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

/// OTP verification flow state.
@freezed
abstract class OtpVerificationState with _$OtpVerificationState {
  const OtpVerificationState._();

  const factory OtpVerificationState.initial() = _OtpVerifyInitial;
  const factory OtpVerificationState.loadInProgress() = _OtpVerifyInProgress;
  const factory OtpVerificationState.loadSuccess(AuthResponseDto auth) =
      _OtpVerifySuccess;
  const factory OtpVerificationState.loadFailure(NetworkExceptions failure) =
      _OtpVerifyNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

// ============================================================================
// STATE NOTIFIERS — call the repository directly; fold into the union
// ============================================================================

/// Requests an OTP for phone/email login.
class OtpRequestNotifier extends StateNotifier<OtpRequestState> {
  OtpRequestNotifier({required this.authRepository})
    : super(const OtpRequestState.initial());

  final AuthRepository authRepository;

  Future<void> requestOtp({
    required String identifierType,
    required String identifier,
  }) async {
    state = const OtpRequestState.loadInProgress();
    final result = await authRepository.requestOtpLogin(
      identifierType: identifierType,
      identifier: identifier,
    );
    state = result.fold(
      OtpRequestState.loadFailure,
      OtpRequestState.loadSuccess,
    );
  }

  void reset() => state = const OtpRequestState.initial();
}

/// Verifies an OTP code and logs in. On success, updates the session state
/// so the router guard knows the user is authenticated.
class OtpVerificationNotifier extends StateNotifier<OtpVerificationState> {
  OtpVerificationNotifier({required this.ref, required this.authRepository})
    : super(const OtpVerificationState.initial());

  final Ref ref;
  final AuthRepository authRepository;

  Future<void> verifyOtp({
    required String identifierType,
    required String identifier,
    required String code,
    String? deviceId,
  }) async {
    state = const OtpVerificationState.loadInProgress();
    final result = await authRepository.verifyOtpLogin(
      identifierType: identifierType,
      identifier: identifier,
      code: code,
      deviceId: deviceId,
    );
    state = result.fold(
      OtpVerificationState.loadFailure,
      OtpVerificationState.loadSuccess,
    );
    if (state is _OtpVerifySuccess) {
      await ref.read(sessionControllerProvider.notifier).recheck();
    }
  }

  void reset() => state = const OtpVerificationState.initial();
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider for OTP Request state
/// Returns the current state of OTP request operation
final otpRequestProvider =
    StateNotifierProvider<OtpRequestNotifier, OtpRequestState>((ref) {
      return OtpRequestNotifier(
        authRepository: ref.watch(authRepositoryProvider),
      );
    });

/// Provider for OTP Verification state
/// Returns the current state of OTP verification operation
final otpVerificationProvider =
    StateNotifierProvider<OtpVerificationNotifier, OtpVerificationState>((ref) {
      return OtpVerificationNotifier(
        ref: ref,
        authRepository: ref.watch(authRepositoryProvider),
      );
    });

// ============================================================================
// SESSION — overall authenticated/unauthenticated status for routing
// ============================================================================

/// Top-level auth status used by the router/redirect guard.
@freezed
abstract class AuthSessionState with _$AuthSessionState {
  const AuthSessionState._();

  /// Startup state before storage has been read.
  const factory AuthSessionState.unknown() = _AuthSessionUnknown;
  const factory AuthSessionState.authenticated(String accountId) =
      _AuthSessionAuthenticated;
  const factory AuthSessionState.unauthenticated() = _AuthSessionUnauthenticated;

  bool get isAuthenticated =>
      maybeWhen(authenticated: (_) => true, orElse: () => false);
}

/// Holds the app-wide auth status. Call [bootstrap] at startup, [recheck]
/// after a successful login flow, and [logout] to end the session.
class SessionController extends StateNotifier<AuthSessionState> {
  SessionController({required this.authRepository, required this.tokenStorage})
    : super(const AuthSessionState.unknown());

  final AuthRepository authRepository;
  final TokenStorage tokenStorage;

  /// Reads persisted credentials and sets the initial status.
  Future<void> bootstrap() => recheck();

  /// Re-reads storage; call after any login flow persists new tokens.
  ///
  /// MUST always resolve to a definitive state (authenticated/unauthenticated)
  /// and never throw or hang — otherwise the session stays `unknown` and the
  /// splash screen sticks forever. Secure-storage reads can throw (e.g. Android
  /// keystore decryption failures across rebuilds) or stall, so they are
  /// guarded with a try/catch + timeout that falls back to unauthenticated.
  Future<void> recheck() async {
    try {
      final accountId =
          await tokenStorage.accountId.timeout(const Duration(seconds: 6));
      final hasRefresh = await tokenStorage.hasValidRefreshToken
          .timeout(const Duration(seconds: 6));
      state = (accountId != null && accountId.isNotEmpty && hasRefresh)
          ? AuthSessionState.authenticated(accountId)
          : const AuthSessionState.unauthenticated();
    } catch (_) {
      // Any storage failure → treat as logged out so the app proceeds to
      // onboarding instead of freezing on splash.
      state = const AuthSessionState.unauthenticated();
    }
  }

  /// Revokes the session server-side (best effort) and clears local tokens.
  Future<void> logout({bool allSessions = false}) async {
    await authRepository.logout(allSessions: allSessions);
    state = const AuthSessionState.unauthenticated();
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, AuthSessionState>((ref) {
      return SessionController(
        authRepository: ref.watch(authRepositoryProvider),
        tokenStorage: ref.watch(tokenStorageProvider),
      );
    });

// ============================================================================
// MAGIC LINK login
// ============================================================================

@freezed
abstract class MagicLinkRequestState with _$MagicLinkRequestState {
  const MagicLinkRequestState._();

  const factory MagicLinkRequestState.initial() = _MagicLinkInitial;
  const factory MagicLinkRequestState.loadInProgress() = _MagicLinkInProgress;
  const factory MagicLinkRequestState.loadSuccess(MagicLoginRequestedDto link) =
      _MagicLinkSuccess;
  const factory MagicLinkRequestState.loadFailure(NetworkExceptions failure) =
      _MagicLinkNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class MagicLinkNotifier extends StateNotifier<MagicLinkRequestState> {
  MagicLinkNotifier({required this.authRepository})
    : super(const MagicLinkRequestState.initial());

  final AuthRepository authRepository;

  Future<void> requestLink(String email) async {
    state = const MagicLinkRequestState.loadInProgress();
    final result = await authRepository.requestMagicLogin(email: email);
    state = result.fold(
      MagicLinkRequestState.loadFailure,
      MagicLinkRequestState.loadSuccess,
    );
  }

  void reset() => state = const MagicLinkRequestState.initial();
}

final magicLinkProvider =
    StateNotifierProvider<MagicLinkNotifier, MagicLinkRequestState>((ref) {
      return MagicLinkNotifier(authRepository: ref.watch(authRepositoryProvider));
    });

// ============================================================================
// LOGIN — shared result state for password / magic-consume / passkey flows
// ============================================================================

@freezed
abstract class LoginState with _$LoginState {
  const LoginState._();

  const factory LoginState.initial() = _LoginInitial;
  const factory LoginState.loadInProgress() = _LoginInProgress;
  const factory LoginState.loadSuccess(AuthResponseDto auth) = _LoginSuccess;
  const factory LoginState.loadFailure(NetworkExceptions failure) = _LoginNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

/// Drives password login and magic-link consumption. On success the repository
/// has already persisted tokens; this notifier triggers a session recheck.
class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier({required this.ref, required this.authRepository})
    : super(const LoginState.initial());

  final Ref ref;
  final AuthRepository authRepository;

  Future<void> loginWithPassword({
    required String identifierType,
    required String identifier,
    required String password,
    String? deviceId,
  }) async {
    state = const LoginState.loadInProgress();
    final result = await authRepository.login(
      identifierType: identifierType,
      identifier: identifier,
      password: password,
      deviceId: deviceId,
    );
    await _apply(result);
  }

  Future<void> consumeMagicLink({required String token, String? deviceId}) async {
    state = const LoginState.loadInProgress();
    final result = await authRepository.consumeMagicLogin(
      token: token,
      deviceId: deviceId,
    );
    await _apply(result);
  }

  Future<void> _apply(Either<NetworkExceptions, AuthResponseDto> result) async {
    state = result.fold(LoginState.loadFailure, LoginState.loadSuccess);
    if (state is _LoginSuccess) {
      await ref.read(sessionControllerProvider.notifier).recheck();
    }
  }

  void reset() => state = const LoginState.initial();
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(
    ref: ref,
    authRepository: ref.watch(authRepositoryProvider),
  );
});

// ============================================================================
// PASSKEY — registration (add passkey to existing account)
// ============================================================================

@freezed
abstract class PasskeyRegisterState with _$PasskeyRegisterState {
  const PasskeyRegisterState._();

  const factory PasskeyRegisterState.initial() = _PasskeyRegInitial;
  const factory PasskeyRegisterState.loadInProgress() = _PasskeyRegInProgress;
  const factory PasskeyRegisterState.loadSuccess(PasskeyCredentialDto credential) =
      _PasskeyRegSuccess;
  const factory PasskeyRegisterState.loadFailure(NetworkExceptions failure) =
      _PasskeyRegNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class PasskeyRegisterNotifier extends StateNotifier<PasskeyRegisterState> {
  PasskeyRegisterNotifier({required this.passkeyService})
      : super(const PasskeyRegisterState.initial());

  final PasskeyService passkeyService;

  Future<void> register({required String accountId, String? nickname}) async {
    state = const PasskeyRegisterState.loadInProgress();
    final result = await passkeyService.register(
      accountId: accountId,
      nickname: nickname,
    );
    state = result.fold(
      PasskeyRegisterState.loadFailure,
      PasskeyRegisterState.loadSuccess,
    );
  }

  void reset() => state = const PasskeyRegisterState.initial();
}

final passkeyRegisterProvider =
    StateNotifierProvider<PasskeyRegisterNotifier, PasskeyRegisterState>((ref) {
  return PasskeyRegisterNotifier(
    passkeyService: ref.watch(passkeyServiceProvider),
  );
});

// ============================================================================
// PASSKEY — authentication (sign in with passkey, no password)
// ============================================================================

/// Drives passkey-based sign-in. Reuses [LoginState] since the result is an
/// [AuthResponseDto]. On success triggers a session recheck.
class PasskeyAuthNotifier extends StateNotifier<LoginState> {
  PasskeyAuthNotifier({required this.ref, required this.passkeyService})
      : super(const LoginState.initial());

  final Ref ref;
  final PasskeyService passkeyService;

  Future<void> authenticate(String accountId) async {
    state = const LoginState.loadInProgress();
    final result = await passkeyService.authenticate(accountId);
    state = result.fold(LoginState.loadFailure, LoginState.loadSuccess);
    if (state is _LoginSuccess) {
      await ref.read(sessionControllerProvider.notifier).recheck();
    }
  }

  /// Usernameless sign-in — no account id; the OS picks the discoverable
  /// credential and the server resolves the account.
  Future<void> authenticateUsernameless() async {
    state = const LoginState.loadInProgress();
    final result = await passkeyService.authenticateUsernameless();
    state = result.fold(LoginState.loadFailure, LoginState.loadSuccess);
    if (state is _LoginSuccess) {
      await ref.read(sessionControllerProvider.notifier).recheck();
    }
  }

  void reset() => state = const LoginState.initial();
}

final passkeyAuthProvider =
    StateNotifierProvider<PasskeyAuthNotifier, LoginState>((ref) {
  return PasskeyAuthNotifier(
    ref: ref,
    passkeyService: ref.watch(passkeyServiceProvider),
  );
});

// ============================================================================
// PASSKEY — bootstrap signup (passkey-first: bare account + passkey + session)
// ============================================================================

/// Drives passkey-first signup. Reuses [LoginState] since success yields an
/// [AuthResponseDto]; on success triggers a session recheck so routing flips to
/// authenticated.
class PasskeyBootstrapNotifier extends StateNotifier<LoginState> {
  PasskeyBootstrapNotifier({required this.ref, required this.passkeyService})
      : super(const LoginState.initial());

  final Ref ref;
  final PasskeyService passkeyService;

  Future<void> signup({required String displayName}) async {
    state = const LoginState.loadInProgress();
    final result = await passkeyService.bootstrapSignup(displayName: displayName);
    state = result.fold(LoginState.loadFailure, LoginState.loadSuccess);
    if (state is _LoginSuccess) {
      await ref.read(sessionControllerProvider.notifier).recheck();
    }
  }

  void reset() => state = const LoginState.initial();
}

final passkeyBootstrapProvider =
    StateNotifierProvider<PasskeyBootstrapNotifier, LoginState>((ref) {
  return PasskeyBootstrapNotifier(
    ref: ref,
    passkeyService: ref.watch(passkeyServiceProvider),
  );
});
