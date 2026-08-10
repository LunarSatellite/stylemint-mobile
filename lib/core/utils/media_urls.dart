import 'package:stylemint_mobile_frontend/core/config/api_config.dart';

/// Backend returns CDN paths as relative (/media/...) for some endpoints
/// and full URLs for others. Normalize to a full URL so Image.network can
/// load them. Returns an empty string for null/empty input so callers can
/// fall back to their placeholder.
String absoluteMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return ApiConfig.baseUrl + path;
}