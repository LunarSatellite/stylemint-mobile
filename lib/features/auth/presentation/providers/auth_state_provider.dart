import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/auth_response_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/otp_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/usecases/index.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';

// ============================================================================
// PROVIDERS - Dependency Injection
// ============================================================================

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ApiClient(
    baseUrl: 'http://localhost:5020', // TODO: Move to config
    dio: dio,
  );
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final remoteDatasource = AuthRemoteDataSource(apiClient: client);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDatasource,
  );
});

/// Provider for RequestOtpLoginUseCase
final Provider<RequestOtpLoginUseCase> requestOtpLoginUsecaseProvider =
    Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return RequestOtpLoginUseCase(authRepository: authRepository);
});

/// Provider for VerifyOtpLoginUseCase
final Provider<VerifyOtpLoginUseCase> verifyOtpLoginUsecaseProvider =
    Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return VerifyOtpLoginUseCase(authRepository: authRepository);
});

// ============================================================================
// STATE CLASSES
// ============================================================================

/// OTP Request State
/// Tracks the state of requesting OTP (loading, error, or success with OTP details)
class OtpRequestState {
  final bool isLoading;
  final Failure? error;
  final OtpLoginRequestedDto? otpData;

  const OtpRequestState({
    this.isLoading = false,
    this.error,
    this.otpData,
  });

  OtpRequestState copyWith({
    bool? isLoading,
    Failure? error,
    OtpLoginRequestedDto? otpData,
  }) {
    return OtpRequestState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpData: otpData ?? this.otpData,
    );
  }

  bool get isSuccess => otpData != null && error == null;
  bool get hasError => error != null;
}

/// OTP Verification State
/// Tracks the state of verifying OTP and logging in
class OtpVerificationState {
  final bool isLoading;
  final Failure? error;
  final AuthResponseDto? authData;

  const OtpVerificationState({
    this.isLoading = false,
    this.error,
    this.authData,
  });

  OtpVerificationState copyWith({
    bool? isLoading,
    Failure? error,
    AuthResponseDto? authData,
  }) {
    return OtpVerificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      authData: authData ?? this.authData,
    );
  }

  bool get isSuccess => authData != null && error == null;
  bool get hasError => error != null;
}

// ============================================================================
// STATE NOTIFIERS - Using StateNotifier<T> for direct state control
// ============================================================================

/// StateNotifier for OTP Request Flow
/// Handles requesting OTP for phone/email login
class OtpRequestNotifier extends StateNotifier<OtpRequestState> {
  final RequestOtpLoginUseCase requestOtpLoginUseCase;

  OtpRequestNotifier({required this.requestOtpLoginUseCase})
      : super(const OtpRequestState());

  /// Request OTP for login
  Future<void> requestOtp({
    required String identifierType,
    required String identifier,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await requestOtpLoginUseCase(
      RequestOtpLoginParams(
        identifierType: identifierType,
        identifier: identifier,
      ),
    );

    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure),
      (otpData) => state.copyWith(isLoading: false, otpData: otpData),
    );
  }

  /// Clear OTP request state
  void reset() {
    state = const OtpRequestState();
  }
}

/// StateNotifier for OTP Verification Flow
/// Handles verifying OTP code and logging in
class OtpVerificationNotifier extends StateNotifier<OtpVerificationState> {
  final VerifyOtpLoginUseCase verifyOtpLoginUseCase;

  OtpVerificationNotifier({required this.verifyOtpLoginUseCase})
      : super(const OtpVerificationState());

  /// Verify OTP code and log in
  Future<void> verifyOtp({
    required String identifierType,
    required String identifier,
    required String code,
    String? deviceId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await verifyOtpLoginUseCase(
      VerifyOtpLoginParams(
        identifierType: identifierType,
        identifier: identifier,
        code: code,
        deviceId: deviceId,
      ),
    );

    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure),
      (authData) => state.copyWith(isLoading: false, authData: authData),
    );
  }

  /// Clear verification state
  void reset() {
    state = const OtpVerificationState();
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider for OTP Request state
/// Returns the current state of OTP request operation
final otpRequestProvider =
    StateNotifierProvider<OtpRequestNotifier, OtpRequestState>((ref) {
  final usecase = ref.watch(requestOtpLoginUsecaseProvider);
  return OtpRequestNotifier(requestOtpLoginUseCase: usecase);
});

/// Provider for OTP Verification state
/// Returns the current state of OTP verification operation
final otpVerificationProvider =
    StateNotifierProvider<OtpVerificationNotifier, OtpVerificationState>(
        (ref) {
  final usecase = ref.watch(verifyOtpLoginUsecaseProvider);
  return OtpVerificationNotifier(verifyOtpLoginUseCase: usecase);
});
