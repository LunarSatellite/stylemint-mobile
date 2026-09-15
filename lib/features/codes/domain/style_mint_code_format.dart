/// The shape of a StyleMint code: 8 characters of Crockford base32 (`0-9`
/// and `A-Z` without `I`, `L`, `O` and `U`), upper case.
abstract final class StyleMintCodeFormat {
  static const int length = 8;

  static final RegExp _pattern = RegExp(r'^[0-9A-HJKMNP-TV-Z]{8}$');

  /// [raw] in upper case when it is a StyleMint code, otherwise null. Codes
  /// are case-insensitive, so `abcd2345` reads as `ABCD2345`.
  static String? normalize(String? raw) {
    final value = raw?.trim().toUpperCase() ?? '';
    return _pattern.hasMatch(value) ? value : null;
  }

  /// [code] split in two for reading or typing: `ABCD 2345`.
  static String display(String code) => code.length == length
      ? '${code.substring(0, 4)} ${code.substring(4)}'
      : code;
}
