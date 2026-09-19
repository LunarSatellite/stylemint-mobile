/// Client-side shapes of the two values the Codes module's per-unit marker
/// work uses. Both mirror `StyleMint.Modules.Codes.Entity.UnitMarkerSecret`
/// and `UnitMarkerReference` exactly — normalising here saves a round trip
/// for input that could never be either, and nothing more. The backend
/// normalises again and is the only authority.
library;

/// Crockford base32 — the same alphabet a StyleMint code uses. No I, L, O or
/// U, so no character pair reads alike on a printed tag.
const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// The **secret** printed on a physical tag: 26 Crockford characters, 130
/// bits.
///
/// This type only ever holds a value in flight — read from a camera or typed
/// by a packer, handed straight to a repository call, and dropped. It is
/// never stored, never logged, and never placed in a route: a credential in a
/// URL lands in every access log between the phone and the database.
abstract final class UnitMarkerFormat {
  /// 26 × 5 bits = 130 bits, matching `UnitMarkerSecret.Length`.
  static const int length = 26;

  /// Canonical form of whatever was scanned or typed, or null when the input
  /// cannot be a marker at all.
  ///
  /// Crockford's read-alike substitutions are applied (`I` and `L` read as
  /// `1`, `O` reads as `0`) and grouping characters are dropped, so a tag read
  /// aloud down a phone line still resolves. Too long fails rather than
  /// truncating — a truncated credential that happened to be well formed
  /// would be a different tag.
  static String? normalize(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final buffer = StringBuffer();
    var written = 0;
    for (final raw in input.split('')) {
      if (raw == ' ' ||
          raw == '-' ||
          raw == '_' ||
          raw == '\t' ||
          raw == '\r' ||
          raw == '\n') {
        continue;
      }
      var ch = raw.toUpperCase();
      ch = switch (ch) {
        'I' || 'L' => '1',
        'O' => '0',
        _ => ch,
      };
      if (!_alphabet.contains(ch)) return null;
      if (written == length) return null;
      buffer.write(ch);
      written++;
    }
    return written == length ? buffer.toString() : null;
  }

  static bool isWellFormed(String? value) => normalize(value) == value;
}

/// The marker's **non-secret** handle — `UM` plus 10 Crockford characters.
///
/// This is what a seller or a support agent quotes. It is generated
/// independently of the secret and shares no bits with it, so it is safe in a
/// list, in a route and on a screen the secret may never appear on.
abstract final class UnitMarkerReferenceFormat {
  static const String prefix = 'UM';
  static const int length = 12;

  static bool isWellFormed(String? value) {
    if (value == null || value.length != length) return false;
    if (!value.startsWith(prefix)) return false;
    for (final ch in value.substring(prefix.length).split('')) {
      if (!_alphabet.contains(ch)) return false;
    }
    return true;
  }

  static String? normalize(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final candidate = input.trim().toUpperCase();
    return isWellFormed(candidate) ? candidate : null;
  }
}
