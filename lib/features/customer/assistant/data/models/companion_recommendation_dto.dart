import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_recommendation.dart';

/// `GET /v1/customer/companion/recommendations` — a bare JSON array of
/// `CompanionRecommendation`.
///
/// The record used to carry a `score`. It no longer does, and this reader
/// never looked for one: a payload that still has the field (an older server,
/// a cached response) parses exactly the same, and a payload without it breaks
/// nothing. Absence of a removed field is a non-event by construction.
class CompanionRecommendationListDto {
  const CompanionRecommendationListDto(this.items);

  factory CompanionRecommendationListDto.fromJson(Object? raw) =>
      CompanionRecommendationListDto(
        raw is List
            ? raw.whereType<Map<String, dynamic>>().toList(growable: false)
            : readPagedItems(raw),
      );

  final List<Map<String, dynamic>> items;

  /// Entries without an id or a title are dropped: a card that cannot open
  /// anything, or has nothing to name, is worse than a shorter list.
  List<CompanionRecommendation> toDomain() => [
    for (final json in items) ?_one(json),
  ];

  static CompanionRecommendation? _one(Map<String, dynamic> json) {
    final id = readString(json['entityId']);
    final title = readString(json['title']);
    if (id.isEmpty || title.isEmpty) return null;
    return CompanionRecommendation(
      entityId: id,
      entityType: readString(json['entityType']).toLowerCase(),
      title: title,
      friendMessage: readString(json['friendMessage']),
      basis: RecommendationBasis.parse(json['basis']),
      // Verbatim: trimmed of surrounding whitespace and otherwise untouched.
      reason: readString(json['reason']),
    );
  }
}
