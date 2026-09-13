import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/entities/demand_signals.dart';

/// Wire shape of GET `/api/v1/vendor/demand-signals` — backend
/// `DemandSignalsDto { WindowDays, GeneratedUtc, TopSearches[],
/// UnmetSearches[] }` with `DemandQueryCount(Query, long Count)` entries,
/// serialized camelCase. Missing lists read as empty and blank queries are
/// dropped, so a partial payload degrades to the empty state.
class DemandSignalsDto {
  const DemandSignalsDto({
    required this.windowDays,
    required this.topSearches,
    required this.unmetSearches,
    this.generatedUtc,
  });

  factory DemandSignalsDto.fromJson(Map<String, dynamic> json) =>
      DemandSignalsDto(
        windowDays: (json['windowDays'] as num?)?.toInt() ?? 0,
        generatedUtc: json['generatedUtc'] is String
            ? DateTime.tryParse(json['generatedUtc'] as String)
            : null,
        topSearches: _parseQueries(json['topSearches']),
        unmetSearches: _parseQueries(json['unmetSearches']),
      );

  final int windowDays;
  final DateTime? generatedUtc;
  final List<DemandQuery> topSearches;
  final List<DemandQuery> unmetSearches;

  DemandSignals toDomain() => DemandSignals(
    windowDays: windowDays,
    generatedUtc: generatedUtc,
    topSearches: topSearches,
    unmetSearches: unmetSearches,
  );
}

List<DemandQuery> _parseQueries(Object? raw) {
  if (raw is! List) return const <DemandQuery>[];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(
        (e) => DemandQuery(
          query: (e['query'] as String? ?? '').trim(),
          count: (e['count'] as num?)?.toInt() ?? 0,
        ),
      )
      .where((q) => q.query.isNotEmpty)
      .toList(growable: false);
}
