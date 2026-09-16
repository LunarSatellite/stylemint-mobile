/// Reads the two option fields a public product card carries alongside its
/// price: whether the buyer has to choose before the product can go in a
/// cart, and the variant the server would otherwise have picked.
///
/// Both fields ship together, but the currently deployed server sends
/// neither, so both are read the way `reel` is: absent, null, or any shape
/// that is not what the contract promised must never throw and must never
/// cost the page a product card.
library;

/// The all-zero Guid the server uses for "no id".
const String _emptyGuid = '00000000-0000-0000-0000-000000000000';

/// Reads `requiresOptionSelection`.
///
/// **Absent, null or unparseable reads as `true`.** The field says whether a
/// customer must pick a size or a colour first; guessing `false` from missing
/// data is how a customer ends up with a size they never chose, so every
/// shape but a plain `false` (or the string `"false"`, for a server that
/// stringifies booleans) keeps the product behind its own page.
bool readRequiresOptionSelection(Object? raw) {
  if (raw is bool) return raw;
  if (raw is String) {
    final text = raw.trim().toLowerCase();
    if (text == 'false') return false;
    if (text == 'true') return true;
  }
  return true;
}

/// Reads `defaultVariantId`: the variant a quick add sends explicitly.
///
/// Null for anything blank, non-string or all-zero — and a null id means no
/// quick add, because the alternative is letting the server pick again.
String? readDefaultVariantId(Object? raw) {
  final text = switch (raw) {
    final String value => value.trim(),
    _ => '',
  };
  if (text.isEmpty || text == _emptyGuid) return null;
  return text;
}

/// Reads `isInStock`. Missing or malformed is false so an older response can
/// never expose a buy action for a product whose availability is unknown.
bool readIsInStock(Object? raw) {
  if (raw is bool) return raw;
  if (raw is String) {
    final text = raw.trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
  }
  return false;
}
