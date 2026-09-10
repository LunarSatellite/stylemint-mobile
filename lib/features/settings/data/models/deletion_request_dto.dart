import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/deletion_request.dart';

part 'deletion_request_dto.freezed.dart';
part 'deletion_request_dto.g.dart';

/// Maps `GET /v1/accounts/{id}/deletion-requests/pending`'s real response
/// shape — backend `AccountDeletionRequestDto` (StyleMint.Modules.Identity)
/// uses `requestedUtc`/`executeAtUtc`, not `requestedAt`/
/// `scheduledDeletionAt` — the old field names never existed on the wire,
/// so every pending-deletion fetch threw on parse.
@freezed
abstract class DeletionRequestDto with _$DeletionRequestDto {
  const factory DeletionRequestDto({
    required String id,
    required DateTime requestedUtc,
    required DateTime executeAtUtc,
  }) = _DeletionRequestDto;

  const DeletionRequestDto._();

  factory DeletionRequestDto.fromJson(Map<String, dynamic> json) =>
      _$DeletionRequestDtoFromJson(json);

  DeletionRequest toDomain() => DeletionRequest(
        id: id,
        requestedAt: requestedUtc,
        scheduledDeletionAt: executeAtUtc,
      );
}
