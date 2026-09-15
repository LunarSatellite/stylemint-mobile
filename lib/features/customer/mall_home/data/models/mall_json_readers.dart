/// Tolerant JSON readers for the Mall DTOs, used through `@JsonKey(fromJson:)`
/// so one malformed card or an enum sent as a number never breaks a page.
library;

import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';

/// Parses each object in [raw] with [parse], skipping entries that aren't
/// objects or fail to parse.
List<T> readJsonList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) parse,
) {
  if (raw is! List) return const [];
  final out = <T>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    try {
      out.add(parse(Map<String, dynamic>.from(entry)));
    } on Object catch (_) {
      // A malformed card is dropped; the rest of the list still renders.
    }
  }
  return List.unmodifiable(out);
}

/// A string, a number as its text, or `''`.
String readWireString(Object? raw) => switch (raw) {
  final String value => value.trim(),
  final num value => value.toString(),
  _ => '',
};

/// Backend enums arrive as names (`"Collection"`) or explicit integers
/// (`1`). Returns the trimmed name or the integer as text.
String readWireEnum(Object? raw) => switch (raw) {
  final String value => value.trim(),
  final num value => value.toInt().toString(),
  _ => '',
};

/// A string map; non-string values become their text, nulls are dropped.
Map<String, String> readStringMap(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final MapEntry(:key, :value) in raw.entries)
      if (key is String && value != null) key: readWireString(value),
  };
}

/// Strings in a list; anything else is dropped.
List<String> readStringList(Object? raw) => raw is List
    ? List.unmodifiable(raw.whereType<String>().where((s) => s.isNotEmpty))
    : const [];

/// An absolute media URL, or null for a missing one.
String? mediaUrlOrNull(String? raw) {
  final url = absoluteMediaUrl(raw?.trim());
  return url.isEmpty ? null : url;
}

/// Trims and turns blank into null.
String? optionalText(String? raw) {
  final value = raw?.trim();
  return value == null || value.isEmpty ? null : value;
}

/// Name or integer (`1..4`) of a Catalog `CollectionKind`; unknown values
/// read as editorial.
CollectionKind collectionKindFromWire(String raw) =>
    switch (raw.toLowerCase()) {
      '2' || 'creatorcollection' => CollectionKind.creatorCollection,
      '3' || 'brandcollection' => CollectionKind.brandCollection,
      '4' || 'look' => CollectionKind.look,
      _ => CollectionKind.editorial,
    };
