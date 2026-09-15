/// English names of the countries StyleMint brands most often come from.
const Map<String, String> _countryNames = {
  'AE': 'United Arab Emirates',
  'AU': 'Australia',
  'BD': 'Bangladesh',
  'BT': 'Bhutan',
  'CA': 'Canada',
  'CH': 'Switzerland',
  'CN': 'China',
  'DE': 'Germany',
  'DK': 'Denmark',
  'ES': 'Spain',
  'FR': 'France',
  'GB': 'United Kingdom',
  'HK': 'Hong Kong',
  'ID': 'Indonesia',
  'IN': 'India',
  'IT': 'Italy',
  'JP': 'Japan',
  'KR': 'South Korea',
  'LK': 'Sri Lanka',
  'MV': 'Maldives',
  'MX': 'Mexico',
  'MY': 'Malaysia',
  'NL': 'Netherlands',
  'NP': 'Nepal',
  'NZ': 'New Zealand',
  'PK': 'Pakistan',
  'PT': 'Portugal',
  'QA': 'Qatar',
  'SA': 'Saudi Arabia',
  'SE': 'Sweden',
  'SG': 'Singapore',
  'TH': 'Thailand',
  'TR': 'Türkiye',
  'TW': 'Taiwan',
  'US': 'United States',
  'VN': 'Vietnam',
};

/// The English name for an ISO 3166-1 alpha-2 [code]; the upper-case code
/// itself when not listed; null for a missing or malformed code.
String? countryName(String? code) {
  final value = code?.trim().toUpperCase() ?? '';
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(value)) return null;
  return _countryNames[value] ?? value;
}
