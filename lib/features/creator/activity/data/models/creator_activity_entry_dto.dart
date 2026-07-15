import 'package:stylemint_mobile_frontend/features/creator/activity/domain/entities/creator_activity_entry.dart';

class CreatorActivityEntryDto {
  const CreatorActivityEntryDto({
    required this.id,
    required this.kind,
    this.headline,
    this.body,
    this.actionUrl,
    required this.occurredUtc,
  });

  factory CreatorActivityEntryDto.fromJson(Map<String, dynamic> json) =>
      CreatorActivityEntryDto(
        id: json['id'] as String? ?? '',
        kind: (json['kind'] as num?)?.toInt() ?? 0,
        headline: json['headline'] as String?,
        body: json['body'] as String?,
        actionUrl: json['actionUrl'] as String?,
        occurredUtc: DateTime.tryParse(json['occurredUtc'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  final String id;
  final int kind;
  final String? headline;
  final String? body;
  final String? actionUrl;
  final DateTime occurredUtc;

  CreatorActivityEntry toDomain() => CreatorActivityEntry(
        id: id,
        kind: kind,
        headline: headline,
        body: body,
        actionUrl: actionUrl,
        occurredUtc: occurredUtc,
      );
}

class CreatorActivityPageDto {
  const CreatorActivityPageDto({required this.items, this.nextCursor});

  factory CreatorActivityPageDto.fromJson(Map<String, dynamic> json) =>
      CreatorActivityPageDto(
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) =>
                CreatorActivityEntryDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );

  final List<CreatorActivityEntryDto> items;
  final String? nextCursor;
}
