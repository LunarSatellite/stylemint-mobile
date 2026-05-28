import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/index.dart';

/// Domain repository interface for authentication
/// Defines the contract for auth operations (implementation agnostic)
abstract interface class AuthRepository {
  /// Request OTP for login
  /// Returns OTP ID and expiration time, or a Failure
  Future<Either<Failure, OtpLoginRequestedDto>> requestOtpLogin({
    required String identifierType,
    required String identifier,
  });

  /// Verify OTP code and perform login
  /// Returns authentication tokens (access + refresh), or a Failure
  Future<Either<Failure, AuthResponseDto>> verifyOtpLogin({
    required String identifierType,
    required String identifier,
    required String code,
    String? deviceId,
  });

  /// Get account details by ID
  /// Returns full account information, or a Failure
  Future<Either<Failure, AccountDto>> getAccount(String accountId);

  /// Register new account
  /// Returns newly created account details, or a Failure
  Future<Either<Failure, AccountDto>> registerAccount({
    String? displayName,
    String? locale,
    String? timezone,
  });
}
