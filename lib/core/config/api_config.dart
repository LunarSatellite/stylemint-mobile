/// Central API configuration — the single source of truth for the base URL
/// and basic network settings used by [dioClient].
///
/// Override the base URL at build/run time with:
/// `--dart-define=API_BASE_URL=https://stylemint.voyageritnepal.com`
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stylemint.voyageritnepal.com',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(minutes: 5);
  static const Duration sendTimeout = Duration(minutes: 5);

  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
  };
}
