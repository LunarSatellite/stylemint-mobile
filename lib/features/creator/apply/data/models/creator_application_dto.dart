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
    // ApplicationState integer enum: 1 Draft, 2 Submitted, 3 UnderReview,
    // 4 Approved, 5 Rejected.
    required int state,
    String? rejectionReason,
    DateTime? submittedAtUtc,
    DateTime? createdUtc,
    DateTime? updatedUtc,
  }) = _CreatorApplicationDto;

  const CreatorApplicationDto._();

  factory CreatorApplicationDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorApplicationDtoFromJson(json);

  CreatorApplication toDomain() {
    final created = createdUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
    return CreatorApplication(
      id: id,
      status: _statusFromState(state),
      rejectionReason: rejectionReason,
      submittedAt: submittedAtUtc ?? created,
      updatedAt: updatedUtc ?? created,
    );
  }

  static CreatorApplicationStatus _statusFromState(int state) {
    switch (state) {
      case 1: // Draft
      case 2: // Submitted
        return CreatorApplicationStatus.pending;
      case 3: // UnderReview
        return CreatorApplicationStatus.underReview;
      case 4: // Approved
        return CreatorApplicationStatus.approved;
      case 5: // Rejected
        return CreatorApplicationStatus.rejected;
      default:
        return CreatorApplicationStatus.pending;
    }
  }
}
