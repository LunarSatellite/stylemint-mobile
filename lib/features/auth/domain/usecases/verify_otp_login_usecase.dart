import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/core/usecase/usecase.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/auth_response_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';

/// UseCase for verifying OTP and logging in
/// Input: identifier type, identifier, OTP code, optional device ID
/// Output: Authentication tokens (access + refresh)
class VerifyOtpLoginUseCase
    implements UseCase<AuthResponseDto, VerifyOtpLoginParams> {
  final AuthRepository authRepository;

  VerifyOtpLoginUseCase({required this.authRepository});

  @override
  Future<Either<Failure, AuthResponseDto>> call(
    VerifyOtpLoginParams params,
  ) async {
    return await authRepository.verifyOtpLogin(
      identifierType: params.identifierType,
      identifier: params.identifier,
      code: params.code,
      deviceId: params.deviceId,
    );
  }
}

/// Parameters for VerifyOtpLoginUseCase
class VerifyOtpLoginParams {
  final String identifierType; // "phone" or "email"
  final String identifier; // phone number or email address
  final String code; // 6-digit OTP code
  final String? deviceId; // Optional device ID

  VerifyOtpLoginParams({
    required this.identifierType,
    required this.identifier,
    required this.code,
    this.deviceId,
  });
}
