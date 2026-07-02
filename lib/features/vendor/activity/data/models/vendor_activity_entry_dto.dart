import 'package:stylemint_mobile_frontend/features/vendor/activity/domain/entities/vendor_activity_entry.dart';

/// Matches `VendorActivityEntryDto` from `GET /v1/vendor/activity`.
class VendorActivityEntryDto {
  const VendorActivityEntryDto({
    required this.id,
    required this.kind,
    this.headline,
    this.body,
    this.actionUrl,
    required this.occurredUtc,
  });

  factory VendorActivityEntryDto.fromJson(Map<String, dynamic> json) =>
      VendorActivityEntryDto(
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

  VendorActivityEntry toDomain() => VendorActivityEntry(
    id: id,
    kind: kind,
    headline: headline,
    body: body,
    actionUrl: actionUrl,
    occurredUtc: occurredUtc,
  );
}

/// Matches the `PagedResult<VendorActivityEntryDto>` envelope.
class VendorActivityPageDto {
  const VendorActivityPageDto({required this.items, this.nextCursor});

  factory VendorActivityPageDto.fromJson(Map<String, dynamic> json) =>
      VendorActivityPageDto(
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => VendorActivityEntryDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );

  final List<VendorActivityEntryDto> items;
  final String? nextCursor;
}
