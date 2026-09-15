/// vCard 3.0 contact cards for StyleMint profile codes.
library;

/// A vCard 3.0 card with the name, the profile link and a "StyleMint" note.
///
/// The phone number goes in only when [phone] is given — callers pass it
/// only after the person has chosen to include it.
String buildProfileVCard({
  required String displayName,
  required String profileUrl,
  String? phone,
}) {
  final trimmed = displayName.trim();
  final name = escapeVCardText(trimmed.isEmpty ? 'StyleMint member' : trimmed);
  final tel = _phoneValue(phone);
  final lines = <String>[
    'BEGIN:VCARD',
    'VERSION:3.0',
    'N:;$name;;;',
    'FN:$name',
    'URL:${profileUrl.replaceAll(RegExp(r'[\r\n]'), '')}',
    'NOTE:StyleMint',
    if (tel != null) 'TEL;TYPE=CELL:$tel',
    'END:VCARD',
  ];
  return '${lines.join('\r\n')}\r\n';
}

/// Escapes a vCard 3.0 text value: backslash, comma, semicolon and line
/// breaks (RFC 2426 §4).
String escapeVCardText(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll(',', r'\,')
    .replaceAll(';', r'\;')
    .replaceAll(RegExp(r'\r\n|\r|\n'), r'\n');

/// A file name for the card from the person's name, e.g. `asha-rai.vcf`.
String profileVCardFileName(String displayName) {
  final slug = displayName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${slug.isEmpty ? 'stylemint-contact' : slug}.vcf';
}

/// A leading `+` and digits only; null when no digits are left.
String? _phoneValue(String? phone) {
  final raw = (phone ?? '').trim();
  final digits = raw.replaceAll(RegExp('[^0-9]'), '');
  if (digits.isEmpty) return null;
  return raw.startsWith('+') ? '+$digits' : digits;
}
