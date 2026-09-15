/// What a StyleMint code points at. [wireName] is the backend's string enum
/// value (`ProductTag`, `Store`, `Profile`).
enum CodeKind {
  productTag('ProductTag'),
  store('Store'),
  profile('Profile'),

  /// A kind this version of the app doesn't know yet.
  unknown('');

  const CodeKind(this.wireName);

  final String wireName;
}

/// Whether a code still opens anything. Revoked codes resolve as not found.
enum CodeStatus { active, revoked, unknown }

/// How a code was opened: the StyleMint scanner, an NFC tag or a link.
enum CodeScanVia {
  qr('Qr'),
  nfc('Nfc'),
  link('Link');

  const CodeScanVia(this.wireName);

  final String wireName;

  /// Reads a `via` value in any casing; anything else counts as a [link].
  static CodeScanVia parse(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    for (final via in values) {
      if (via.wireName.toLowerCase() == value) return via;
    }
    return link;
  }
}
