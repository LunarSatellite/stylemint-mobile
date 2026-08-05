import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/youtube_channel.dart';

/// Direct (anonymous) fetch from YouTube Data API v3.
/// API key is injected at build time via --dart-define=YOUTUBE_API_KEY=...
class YouTubeChannelDataSource {
  YouTubeChannelDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _apiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');

  Future<YouTubeChannel?> getChannel(String channelId) async {
    if (_apiKey.isEmpty || channelId.isEmpty) return null;
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/channels', {
      'part': 'snippet,statistics,brandingSettings',
      'id': channelId,
      'key': _apiKey,
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return null;
    final item = items.first as Map<String, dynamic>;
    final snippet = item['snippet'] as Map<String, dynamic>? ?? const {};
    final stats = item['statistics'] as Map<String, dynamic>? ?? const {};
    final branding = item['brandingSettings'] as Map<String, dynamic>? ?? const {};
    final image = branding['image'] as Map<String, dynamic>? ?? const {};
    final thumbs = snippet['thumbnails'] as Map<String, dynamic>? ?? const {};
    final hi = thumbs['high'] as Map<String, dynamic>? ?? const {};
    final med = thumbs['medium'] as Map<String, dynamic>? ?? const {};
    return YouTubeChannel(
      id: item['id'] as String? ?? channelId,
      title: snippet['title'] as String? ?? '',
      handle: snippet['customUrl'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      avatarUrl: (hi['url'] ?? med['url'] ?? '') as String,
      bannerUrl: (image['bannerExternalUrl'] ?? '') as String,
      subscriberCount: int.tryParse((stats['subscriberCount'] ?? '0').toString()) ?? 0,
      videoCount: int.tryParse((stats['videoCount'] ?? '0').toString()) ?? 0,
      viewCount: int.tryParse((stats['viewCount'] ?? '0').toString()) ?? 0,
      lastSyncedUtc: DateTime.now().toUtc(),
    );
  }
}
