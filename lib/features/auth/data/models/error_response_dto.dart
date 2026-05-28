import 'package:freezed_annotation/freezed_annotation.dart';

part 'error_response_dto.freezed.dart';
part 'error_response_dto.g.dart';

/// Error response following RFC 7807 Problem Details standard
/// Returned by all API endpoints on error (400, 403, 500, etc.)
@freezed
abstract class ErrorResponseDto with _$ErrorResponseDto {
  const factory ErrorResponseDto({
    String? type,
    String? title,
    required int status, // HTTP status code
    String? errorCode, // Machine-readable error code (keyed)
    String? field, // Field that failed validation (optional)
    String? correlationId, // Trace ID for debugging
    List<FieldErrorDto>? errors, // Field-level validation errors
  }) = _ErrorResponseDto;

  factory ErrorResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseDtoFromJson(json);
}

/// Field-level error details
@freezed
abstract class FieldErrorDto with _$FieldErrorDto {
  const factory FieldErrorDto({
    String? field,
    String? message,
  }) = _FieldErrorDto;

  factory FieldErrorDto.fromJson(Map<String, dynamic> json) =>
      _$FieldErrorDtoFromJson(json);
}
