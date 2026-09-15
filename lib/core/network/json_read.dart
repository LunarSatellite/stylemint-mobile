/// Tolerant readers for backend JSON. A missing or wrongly typed value reads
/// as empty, zero or null instead of throwing, so one odd field never breaks
/// a whole screen.
library;

/// A trimmed string, or `''` when missing or not a string.
String readString(Object? raw) => raw is String ? raw.trim() : '';

/// A trimmed string, or null when missing or blank.
String? readOptionalString(Object? raw) {
  final value = readString(raw);
  return value.isEmpty ? null : value;
}

/// An int from a JSON number or numeric string; anything else is 0.
int readInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? 0;
  return 0;
}

/// A double from a JSON number or numeric string, else null.
double? readOptionalDouble(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim());
  return null;
}

/// A bool from `true`/`false` or their string forms; anything else is false.
bool readBool(Object? raw) {
  if (raw is bool) return raw;
  if (raw is String) return raw.trim().toLowerCase() == 'true';
  return false;
}

/// An ISO 8601 timestamp, or null when missing or unparseable.
DateTime? readDate(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? DateTime.tryParse(raw) : null;

/// Backend enums arrive as numbers or names. Returns an int for numeric
/// input, a lowercase name with `_`, `-` and spaces removed for other
/// strings, and null for anything else.
Object? normalizeWireEnum(Object? raw) {
  if (raw is int) return raw;
  if (raw is num && raw == raw.roundToDouble()) return raw.toInt();
  if (raw is String) {
    final trimmed = raw.trim();
    return int.tryParse(trimmed) ??
        trimmed.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }
  return null;
}

/// The response body as a JSON object; throws [FormatException] otherwise.
Map<String, dynamic> readJsonObject(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  throw const FormatException('Expected a JSON object');
}

/// The `items` of a `PagedResult` body. Entries that aren't objects are
/// dropped; a body without a list reads as no items.
List<Map<String, dynamic>> readPagedItems(Object? raw) {
  final items = raw is Map ? raw['items'] : null;
  if (items is! List) return const [];
  return items.whereType<Map<String, dynamic>>().toList(growable: false);
}

/// The `nextCursor` of a `PagedResult` body; null on the last page.
String? readNextCursor(Object? raw) =>
    raw is Map ? readOptionalString(raw['nextCursor']) : null;
