import 'package:freezed_annotation/freezed_annotation.dart';

part 'blocked_user_dto.freezed.dart';
part 'blocked_user_dto.g.dart';

@freezed
abstract class BlockedUserDto with _$BlockedUserDto {
  const factory BlockedUserDto({
    required String id,
    required String accountId,
    required String blockedAccountId,
    @JsonKey(name: 'blockedUserName') String? blockedUserName,
    @JsonKey(name: 'blockedUserAvatarUrl') String? blockedUserAvatarUrl,
    @JsonKey(name: 'blockedUtc') DateTime? blockedUtc,
    @JsonKey(name: 'createdUtc') DateTime? createdUtc,
    String? rowVersion,
  }) = _BlockedUserDto;

  factory BlockedUserDto.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserDtoFromJson(json);
}
