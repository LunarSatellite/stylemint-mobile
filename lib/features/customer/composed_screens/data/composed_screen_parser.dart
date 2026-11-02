import 'package:stylemint_mobile_frontend/features/customer/composed_screens/domain/composed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/home_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/mall_json_readers.dart';

/// Cards fetched separately (`GET v1/public/cards`) for items the composer
/// sent without an embedded `card`: the card JSON by section-kind wire
/// (`products`, `reels`, `creators`, `vendors`, `brands`) and lower-cased id.
typedef ComposedCardLookup = Map<String, Map<String, Map<String, dynamic>>>;

/// The `cards` query key for each section kind.
String composedCardsKey(ComposedSectionKind kind) => kind.wire;

/// Items in [json] that arrived without an embedded `card`, as
/// (section kind, item id), in order and without duplicates.
List<(ComposedSectionKind, String)> missingComposedCards(
  Map<String, dynamic> json,
) {
  final out = <(ComposedSectionKind, String)>[];
  final seen = <String>{};
  final rawSections = json['sections'];
  if (rawSections is! List) return out;
  for (final raw in rawSections) {
    if (raw is! Map) continue;
    final kind = ComposedSectionKind.parse(raw['kind']);
    final items = raw['items'];
    if (kind == null || items is! List) continue;
    for (final item in items) {
      if (item is! Map || item['card'] is Map) continue;
      final id = _text(item['id']);
      if (id == null) continue;
      if (seen.add('${kind.wire}|${id.toLowerCase()}')) out.add((kind, id));
    }
  }
  return out;
}

/// Indexes a `GET v1/public/cards` response for [parseComposedScreen].
/// Malformed entries are skipped; never throws.
ComposedCardLookup readComposedCards(Object? raw) {
  final out = <String, Map<String, Map<String, dynamic>>>{};
  if (raw is! Map) return out;
  const idFields = {
    'products': ['id', 'productId'],
    'reels': ['id', 'reelId'],
    'creators': ['accountId', 'id'],
    'vendors': ['vendorAccountId', 'id'],
    'brands': ['vendorAccountId', 'id'],
  };
  for (final MapEntry(key: kind, value: fields) in idFields.entries) {
    final list = raw[kind];
    if (list is! List) continue;
    final byId = out[kind] = {};
    for (final card in list) {
      if (card is! Map) continue;
      for (final field in fields) {
        final id = _text(card[field]);
        if (id != null) {
          byId[id.toLowerCase()] = Map<String, dynamic>.from(card);
          break;
        }
      }
    }
  }
  return out;
}

/// Parses a composer response tolerantly: unknown section kinds, items
/// without a usable `card` (embedded, or found in [cards]), and malformed
/// entries are dropped, and sections left empty are omitted. Never throws.
ComposedScreen parseComposedScreen(
  Map<String, dynamic> json, {
  ComposedCardLookup cards = const {},
}) {
  final sections = <ComposedSection>[];
  final rawSections = json['sections'];
  if (rawSections is List) {
    for (final raw in rawSections) {
      if (raw is! Map) continue;
      try {
        final section = _section(Map<String, dynamic>.from(raw), cards);
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

ComposedSection? _section(
  Map<String, dynamic> json,
  ComposedCardLookup cards,
) {
  final kind = ComposedSectionKind.parse(json['kind']);
  final id = _text(json['sectionId']);
  if (kind == null || id == null) return null;
  final items = <ComposedItem>[];
  final rawItems = json['items'];
  if (rawItems is List) {
    for (final (index, raw) in rawItems.indexed) {
      if (raw is! Map) continue;
      try {
        final item = _item(
          kind,
          Map<String, dynamic>.from(raw),
          index,
          cards,
        );
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
  ComposedCardLookup cards,
) {
  final id = _text(json['id']);
  final rawCard =
      json['card'] ??
      (id == null ? null : cards[composedCardsKey(kind)]?[id.toLowerCase()]);
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
