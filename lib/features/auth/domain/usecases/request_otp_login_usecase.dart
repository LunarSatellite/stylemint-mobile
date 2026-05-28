import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/core/usecase/usecase.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/otp_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';

/// UseCase for requesting OTP for login
/// Input: phone number or email
/// Output: OTP ID and expiration time
class RequestOtpLoginUseCase
    implements UseCase<OtpLoginRequestedDto, RequestOtpLoginParams> {
  final AuthRepository authRepository;

  RequestOtpLoginUseCase({required this.authRepository});

  @override
  Future<Either<Failure, OtpLoginRequestedDto>> call(
    RequestOtpLoginParams params,
  ) async {
    return await authRepository.requestOtpLogin(
      identifierType: params.identifierType,
      identifier: params.identifier,
    );
  }
}

/// Parameters for RequestOtpLoginUseCase
class RequestOtpLoginParams {
  final String identifierType; // "phone" or "email"
  final String identifier; // phone number or email address

  RequestOtpLoginParams({
    required this.identifierType,
    required this.identifier,
  });
}
