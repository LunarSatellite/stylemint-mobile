import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_dto.freezed.dart';
part 'device_dto.g.dart';

/// A registered device. Returned by the device endpoints under
/// `/v1/accounts/{accountId}/devices`.
///
/// Enum fields ([platform], [trustLevel]) arrive as their string names.
@freezed
abstract class DeviceDto with _$DeviceDto {
  const factory DeviceDto({
    required String id, // UUID
    required String accountId, // UUID
    String? deviceFingerprint,
    String? platform,
    String? model,
    String? osVersion,
    String? appVersion,
    String? nickname,
    String? trustLevel,
    @JsonKey(name: 'firstSeenUtc') DateTime? firstSeenUtc,
    @JsonKey(name: 'lastSeenUtc') DateTime? lastSeenUtc,
    @JsonKey(name: 'revokedUtc') DateTime? revokedUtc,
    @JsonKey(name: 'createdUtc') DateTime? createdUtc,
    @JsonKey(name: 'updatedUtc') DateTime? updatedUtc,
    String? rowVersion,
  }) = _DeviceDto;

  factory DeviceDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceDtoFromJson(json);
}
