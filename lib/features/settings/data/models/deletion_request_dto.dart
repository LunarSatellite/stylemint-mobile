import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/deletion_request.dart';

part 'deletion_request_dto.freezed.dart';
part 'deletion_request_dto.g.dart';

@freezed
abstract class DeletionRequestDto with _$DeletionRequestDto {
  const factory DeletionRequestDto({
    required String id,
    required DateTime requestedAt,
    DateTime? scheduledDeletionAt,
  }) = _DeletionRequestDto;

  const DeletionRequestDto._();

  factory DeletionRequestDto.fromJson(Map<String, dynamic> json) =>
      _$DeletionRequestDtoFromJson(json);

  DeletionRequest toDomain() => DeletionRequest(
        id: id,
        requestedAt: requestedAt,
        scheduledDeletionAt: scheduledDeletionAt,
      );
}
