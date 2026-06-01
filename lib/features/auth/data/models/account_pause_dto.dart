import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_pause_dto.freezed.dart';
part 'account_pause_dto.g.dart';

/// Account pause (Quiet Hours / break) state. Returned by
/// `GET /v1/auth/pause`.
@freezed
abstract class AccountPauseDto with _$AccountPauseDto {
  const factory AccountPauseDto({
    required String id, // UUID
    required String accountId, // UUID
    @JsonKey(name: 'pauseUntilUtc') DateTime? pauseUntilUtc,
    @JsonKey(name: 'createdUtc') DateTime? createdUtc,
    required bool isActive,
    String? rowVersion,
  }) = _AccountPauseDto;

  factory AccountPauseDto.fromJson(Map<String, dynamic> json) =>
      _$AccountPauseDtoFromJson(json);
}
