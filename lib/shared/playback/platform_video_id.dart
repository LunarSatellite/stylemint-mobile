import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

final _youTubeId = RegExp(r'^[A-Za-z0-9_-]+$');
final _tikTokId = RegExp(r'^\d+$');
final _facebookId = RegExp(r'^[A-Za-z0-9_-]+$');

/// The platform's own video id, read from a reel permalink.
///
/// Only a fallback for when the backend did not send the id. Instagram has no
/// embeddable id, so it always yields null. Facebook embeds by URL, so any
/// recognised Facebook video path is enough there.
String? parsePlatformVideoId(SocialPlatform? platform, String permalink) {
  final uri = Uri.tryParse(permalink.trim());
  if (uri == null || !uri.hasScheme) return null;
  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  String? after(String marker) {
    final i = segments.indexOf(marker);
    return i >= 0 && i + 1 < segments.length ? segments[i + 1] : null;
  }

  String? valid(String? id, RegExp pattern) =>
      id != null && pattern.hasMatch(id) ? id : null;

  switch (platform) {
    case SocialPlatform.youtube:
      if (host == 'youtu.be') {
        return valid(segments.isEmpty ? null : segments.first, _youTubeId);
      }
      if (host != 'youtube.com' && !host.endsWith('.youtube.com')) return null;
      return valid(
        uri.queryParameters['v'] ?? after('shorts') ?? after('embed'),
        _youTubeId,
      );
    case SocialPlatform.tiktok:
      if (host != 'tiktok.com' && !host.endsWith('.tiktok.com')) return null;
      return valid(after('video') ?? after('v1'), _tikTokId);
    case SocialPlatform.facebook:
      if (host == 'fb.watch') {
        return valid(segments.isEmpty ? null : segments.first, _facebookId);
      }
      if (host != 'facebook.com' && !host.endsWith('.facebook.com')) {
        return null;
      }
      return valid(
        uri.queryParameters['v'] ?? after('reel') ?? after('videos'),
        _facebookId,
      );
    case SocialPlatform.instagram:
    case null:
      return null;
  }
}
