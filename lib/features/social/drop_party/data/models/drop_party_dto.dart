import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';

class DropPartyDto {
  const DropPartyDto({
    required this.id,
    required this.creatorProfileId,
    required this.vendorProfileId,
    required this.reelId,
    required this.title,
    required this.description,
    required this.startsUtc,
    required this.duration,
    required this.joinCode,
    required this.state,
    required this.attendeeCount,
    required this.reelIsOrphaned,
    this.wentLiveUtc,
    this.endedUtc,
    this.cancellationReason,
  });

  factory DropPartyDto.fromJson(Map<String, dynamic> json) => DropPartyDto(
    id: json['id'] as String? ?? '',
    creatorProfileId: json['creatorProfileId'] as String? ?? '',
    vendorProfileId: json['vendorProfileId'] as String? ?? '',
    reelId: json['reelId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    startsUtc: DateTime.parse(json['startsUtc'] as String),
    duration: Duration(seconds: _durationSeconds(json['duration'])),
    joinCode: json['joinCode'] as String? ?? '',
    state: (json['state'] as num?)?.toInt() ?? 1,
    attendeeCount: (json['attendeeCount'] as num?)?.toInt() ?? 0,
    reelIsOrphaned: json['reelIsOrphaned'] as bool? ?? false,
    wentLiveUtc: _readDate(json['wentLiveUtc']),
    endedUtc: _readDate(json['endedUtc']),
    cancellationReason: json['cancellationReason'] as String?,
  );

  final String id;
  final String creatorProfileId;
  final String vendorProfileId;
  final String reelId;
  final String title;
  final String description;
  final DateTime startsUtc;
  final Duration duration;
  final String joinCode;
  final int state;
  final int attendeeCount;
  final bool reelIsOrphaned;
  final DateTime? wentLiveUtc;
  final DateTime? endedUtc;
  final String? cancellationReason;

  DropParty toDomain() => DropParty(
    id: id,
    creatorProfileId: creatorProfileId,
    vendorProfileId: vendorProfileId,
    reelId: reelId,
    title: title,
    description: description,
    startsAt: startsUtc.toLocal(),
    duration: duration,
    joinCode: joinCode,
    status: switch (state) {
      1 => DropPartyStatus.scheduled,
      2 => DropPartyStatus.live,
      3 => DropPartyStatus.ended,
      4 => DropPartyStatus.cancelled,
      _ => DropPartyStatus.scheduled,
    },
    attendeeCount: attendeeCount,
    reelIsOrphaned: reelIsOrphaned,
    wentLiveAt: wentLiveUtc?.toLocal(),
    endedAt: endedUtc?.toLocal(),
    cancellationReason: cancellationReason,
  );

  static DateTime? _readDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static int _durationSeconds(Object? value) {
    if (value is num) return value.toInt();
    if (value is! String) return 0;
    final parts = value.split(':');
    if (parts.length != 3) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 3600 +
        (int.tryParse(parts[1]) ?? 0) * 60 +
        (double.tryParse(parts[2]) ?? 0).round();
  }
}
