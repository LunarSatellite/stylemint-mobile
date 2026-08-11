import 'package:stylemint_mobile_frontend/core/config/api_config.dart';

/// Backend returns CDN paths in two shapes:
///   * relative (`/media/...`, `vendor-products/<uuid>`, ...) - needs the
///     base URL prepended
///   * absolute (`https://cdn.example/...`) - pass through
///
/// The catalog CDN refuses to serve image-style paths that lack a file
/// extension (e.g. `vendor-products/<uuid>` 404s), so we append a default
/// `.jpg` for relative paths that look like images and have no extension.
/// Callers that genuinely need the raw string (downloads, signed URLs)
/// should not route through this helper.
String absoluteMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final qIdx = path.indexOf('?');
  final main = qIdx == -1 ? path : path.substring(0, qIdx);
  final tail = qIdx == -1 ? '' : path.substring(qIdx);
  final lastSlash = main.lastIndexOf('/');
  final lastSegment = lastSlash == -1 ? main : main.substring(lastSlash + 1);
  // Treat the last path segment as having a real extension only when it
  // contains a dot with at least one character on each side. That avoids
  // appending `.jpg` to dotfiles (`.gitignore`), trailing-dot segments
  // (`a.`), trailing-slash inputs (`folder/`), and segmentless input.
  final hasExtension = _looksLikeFileWithExtension(lastSegment);
  if (!hasExtension) {
    return ApiConfig.baseUrl + '$main.jpg$tail';
  }
  return ApiConfig.baseUrl + path;
}

bool _looksLikeFileWithExtension(String segment) {
  if (segment.length < 3) return false;
  final dot = segment.indexOf('.');
  if (dot <= 0) return false;
  if (dot == segment.length - 1) return false;
  return true;
}
