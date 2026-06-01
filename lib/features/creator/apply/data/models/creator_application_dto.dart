import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';

part 'creator_application_dto.freezed.dart';
part 'creator_application_dto.g.dart';

@freezed
abstract class PlatformDto with _$PlatformDto {
  const factory PlatformDto({
    required String id,
    required String name,
    required String handle,
    required int followerCount,
    @Default(false) bool connected,
  }) = _PlatformDto;

  const PlatformDto._();

  factory PlatformDto.fromJson(Map<String, dynamic> json) =>
      _$PlatformDtoFromJson(json);

  Platform toDomain() => Platform(
    id: id,
    name: name,
    handle: handle,
    followerCount: followerCount,
    connected: connected,
  );
}

@freezed
abstract class CreatorApplicationDto with _$CreatorApplicationDto {
  const factory CreatorApplicationDto({
    required String id,
    required String status,
    String? rejectionReason,
    required DateTime submittedAt,
    required DateTime updatedAt,
  }) = _CreatorApplicationDto;

  const CreatorApplicationDto._();

  factory CreatorApplicationDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorApplicationDtoFromJson(json);

  CreatorApplication toDomain() => CreatorApplication(
    id: id,
    status: _statusFromCode(status),
    rejectionReason: rejectionReason,
    submittedAt: submittedAt,
    updatedAt: updatedAt,
  );

  static CreatorApplicationStatus _statusFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'pending':
        return CreatorApplicationStatus.pending;
      case 'under_review':
      case 'review':
        return CreatorApplicationStatus.underReview;
      case 'approved':
        return CreatorApplicationStatus.approved;
      case 'rejected':
        return CreatorApplicationStatus.rejected;
      default:
        return CreatorApplicationStatus.pending;
    }
  }
}
