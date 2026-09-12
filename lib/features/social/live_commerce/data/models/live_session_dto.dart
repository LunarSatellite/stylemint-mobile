import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/entities/live_session.dart';

class LiveSessionDto {
  const LiveSessionDto({
    required this.id,
    required this.creatorAccountId,
    required this.title,
    required this.status,
    required this.scheduledStartUtc,
    required this.currentViewerCount,
    required this.featuredProductIds,
  });

  final String id;
  final String creatorAccountId;
  final String title;
  final String status;
  final DateTime scheduledStartUtc;
  final int currentViewerCount;
  final List<String> featuredProductIds;

  factory LiveSessionDto.fromJson(Map<String, dynamic> json) => LiveSessionDto(
    id: json['id'] as String,
    creatorAccountId: json['creatorAccountId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    status: json['status'] as String? ?? '',
    scheduledStartUtc: DateTime.parse(json['scheduledStartUtc'] as String),
    currentViewerCount: json['currentViewerCount'] as int? ?? 0,
    featuredProductIds: (json['featuredProductIds'] as List<dynamic>? ?? const [])
        .map((e) => e as String)
        .toList(growable: false),
  );

  LiveSession toDomain() => LiveSession(
    id: id,
    creatorAccountId: creatorAccountId,
    title: title,
    status: switch (status.toLowerCase()) {
      'scheduled' => LiveSessionStatus.scheduled,
      'live' => LiveSessionStatus.live,
      'ended' => LiveSessionStatus.ended,
      _ => LiveSessionStatus.unknown,
    },
    scheduledStartUtc: scheduledStartUtc,
    currentViewerCount: currentViewerCount,
    featuredProductIds: featuredProductIds,
  );
}
