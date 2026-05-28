import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/index.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository that uses remote datasource
/// Converts API responses to domain entities and errors to Failure types
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, OtpLoginRequestedDto>> requestOtpLogin({
    required String identifierType,
    required String identifier,
  }) async {
    try {
      final response = await remoteDataSource.requestOtpLogin(
        identifierType: identifierType,
        identifier: identifier,
      );
      return Right(response);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, AuthResponseDto>> verifyOtpLogin({
    required String identifierType,
    required String identifier,
    required String code,
    String? deviceId,
  }) async {
    try {
      final response = await remoteDataSource.verifyOtpLogin(
        identifierType: identifierType,
        identifier: identifier,
        code: code,
        deviceId: deviceId,
      );
      return Right(response);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, AccountDto>> getAccount(String accountId) async {
    try {
      final response = await remoteDataSource.getAccount(accountId);
      return Right(response);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, AccountDto>> registerAccount({
    String? displayName,
    String? locale,
    String? timezone,
  }) async {
    try {
      final response = await remoteDataSource.registerAccount(
        displayName: displayName,
        locale: locale,
        timezone: timezone,
      );
      return Right(response);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Map exceptions/errors to domain Failure types
  /// Handles API errors (DioException), network errors, and unknown errors
  Failure _mapExceptionToFailure(dynamic exception) {
    if (exception is DioException) {
      if (exception.response != null) {
        final statusCode = exception.response!.statusCode ?? 0;

        // Try to parse error response
        try {
          final errorData = exception.response!.data;
          if (errorData is Map<String, dynamic>) {
            final errorResponse = ErrorResponseDto.fromJson(errorData);
            return _mapErrorResponseToFailure(errorResponse);
          }
        } catch (e) {
          // Continue with standard error mapping
        }

        // Standard HTTP error mapping
        switch (statusCode) {
          case 400:
            return const Failure.validation(
              code: 'INVALID_REQUEST',
            );
          case 401:
          case 403:
            return const Failure.auth();
          case 404:
            return const Failure.notFound();
          case 409:
            return const Failure.conflict();
          case 422:
            return const Failure.validation(
              code: 'UNPROCESSABLE_ENTITY',
            );
          case >= 500:
            return const Failure.server();
          default:
            return const Failure.unknown();
        }
      }

      // Network-level errors (no response)
      if (exception.type == DioExceptionType.connectionTimeout ||
          exception.type == DioExceptionType.receiveTimeout ||
          exception.type == DioExceptionType.sendTimeout) {
        return const Failure.network();
      }

      if (exception.type == DioExceptionType.connectionError) {
        return const Failure.network();
      }

      return const Failure.unknown();
    }

    // Unknown error type
    return const Failure.unknown();
  }

  /// Map RFC 7807 error response to domain Failure
  Failure _mapErrorResponseToFailure(ErrorResponseDto errorResponse) {
    final errorCode = errorResponse.errorCode ?? 'UNKNOWN';
    final statusCode = errorResponse.status;

    // Map specific error codes to failure types
    switch (errorCode) {
      case 'INVALID_OTP':
      case 'OTP_EXPIRED':
      case 'OTP_INVALID':
        return Failure.validation(code: errorCode);

      case 'INVALID_PHONE':
      case 'INVALID_EMAIL':
      case 'INVALID_REQUEST':
        return Failure.validation(code: errorCode);

      case 'ACCOUNT_LOCKED':
      case 'ACCOUNT_SUSPENDED':
        return const Failure.auth();

      case 'DUPLICATE_ACCOUNT':
      case 'CONFLICT':
        return const Failure.conflict();

      case 'NOT_FOUND':
        return const Failure.notFound();

      default:
        // Fallback to HTTP status code
        if (statusCode >= 500) {
          return const Failure.server();
        } else if (statusCode >= 400) {
          return Failure.validation(code: errorCode);
        }
        return const Failure.unknown();
    }
  }
}
