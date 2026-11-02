import 'package:stylemint_mobile_frontend/features/customer/composed_screens/domain/composed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/home_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/mall_json_readers.dart';

/// Parses a composer response tolerantly: unknown section kinds, items
/// without a usable embedded `card`, and malformed entries are dropped, and
/// sections left empty are omitted. Never throws.
ComposedScreen parseComposedScreen(Map<String, dynamic> json) {
  final sections = <ComposedSection>[];
  final rawSections = json['sections'];
  if (rawSections is List) {
    for (final raw in rawSections) {
      if (raw is! Map) continue;
      try {
        final section = _section(Map<String, dynamic>.from(raw));
        if (section != null) sections.add(section);
      } on Object catch (_) {
        // A malformed section is skipped; the rest still render.
      }
    }
  }
  return ComposedScreen(
    requestId: readRankingRequestId(json['requestId']),
    screen: readWireString(json['screen']),
    fallback: json['fallback'] == true,
    sections: List.unmodifiable(sections),
    nextCursor: _text(json['nextCursor']),
    question: _question(json['question']),
  );
}

String? _text(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

ComposedSection? _section(Map<String, dynamic> json) {
  final kind = ComposedSectionKind.parse(json['kind']);
  final id = _text(json['sectionId']);
  if (kind == null || id == null) return null;
  final items = <ComposedItem>[];
  final rawItems = json['items'];
  if (rawItems is List) {
    for (final (index, raw) in rawItems.indexed) {
      if (raw is! Map) continue;
      try {
        final item = _item(kind, Map<String, dynamic>.from(raw), index);
        if (item != null) items.add(item);
      } on Object catch (_) {
        // Dropped like a malformed home card.
      }
    }
  }
  if (items.isEmpty) return null;
  final title = _text(json['title']) ?? '';
  return ComposedSection(
    sectionId: id,
    kind: kind,
    title: title,
    titleKey: _text(json['titleKey']),
    titleParams: readStringMap(json['titleParams']),
    reasonKey: _text(json['reasonKey']),
    source: _text(json['source']),
    items: List.unmodifiable(items),
  );
}

ComposedItem? _item(
  ComposedSectionKind kind,
  Map<String, dynamic> json,
  int index,
) {
  final id = _text(json['id']);
  final rawCard = json['card'];
  if (id == null || rawCard is! Map) return null;
  final card = Map<String, dynamic>.from(rawCard);
  String fill(String field) {
    final value = card[field];
    return value is String && value.trim().isNotEmpty ? value : id;
  }

  final domain = switch (kind) {
    ComposedSectionKind.products => HomeProductCardDto.fromJson({
      ...card,
      'id': fill('id'),
    }).toDomain(),
    ComposedSectionKind.reels => HomeReelCardDto.fromJson({
      ...card,
      'id': fill('id'),
    }).toDomain(),
    ComposedSectionKind.creators => HomeCreatorCardDto.fromJson({
      ...card,
      'accountId': fill('accountId'),
    }).toDomain(),
    ComposedSectionKind.vendors ||
    ComposedSectionKind.brands => HomeBrandCardDto.fromJson({
      ...card,
      'vendorAccountId': fill('vendorAccountId'),
    }).toDomain(),
  };
  if (domain == null) return null;
  final score = json['score'];
  return ComposedItem(
    id: id,
    position: readRankingPosition(json['position']) ?? index,
    card: domain,
    score: score is num ? score.toDouble() : null,
    reasonKey: _text(json['reasonKey']),
    reasonParams: readStringMap(json['reasonParams']),
  );
}

ScreenQuestion? _question(Object? raw) {
  if (raw is! Map) return null;
  final key = _text(raw['key']);
  final label = _text(raw['label']);
  final values = readStringList(raw['values']);
  if (key == null || label == null || values.isEmpty) return null;
  return ScreenQuestion(
    key: key,
    department: _text(raw['department']),
    label: label,
    values: values,
  );
}
