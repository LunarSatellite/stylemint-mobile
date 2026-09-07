import 'package:flutter/material.dart';

enum SocialPlatform {
  instagram,
  tiktok,
  youtube,
  facebook;

  /// Resolves the platform from whatever shape the backend sent.
  ///
  /// The wire format is not consistent across endpoints, and the two forms
  /// do not agree with Dart's enum names:
  ///
  /// - `ReelDto.sourcePlatform` (`GET /v1/public/reels/{id}`) is the C#
  ///   `ReelSourcePlatform` enum, which System.Text.Json serialises as its
  ///   **int** value — 1 Instagram, 2 TikTok, 3 YouTubeShorts, 4 Facebook.
  /// - `ReelCardDto.SourcePlatform` (the Discovery feed) is a **string**
  ///   built with `.ToString()`, so it arrives PascalCase and, for YouTube,
  ///   as `"YouTubeShorts"` — matching neither `SocialPlatform.youtube.name`
  ///   nor the label shown in the UI.
  ///
  /// Comparing against `name` therefore fails for every value and silently
  /// falls back to Instagram, which is why non-Instagram reels rendered with
  /// the wrong player. Parse tolerantly here, in one place, instead.
  ///
  /// Returns null when the value is absent or unrecognised so callers choose
  /// their own fallback rather than inheriting a wrong one.
  static SocialPlatform? tryParseWire(Object? value) {
    if (value == null) return null;

    if (value is num) return _fromCode(value.toInt());

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      final asInt = int.tryParse(trimmed);
      if (asInt != null) return _fromCode(asInt);

      // Collapse case and separators so "YouTubeShorts", "youtube_shorts"
      // and "YouTube Shorts" all land on the same key.
      final key = trimmed.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
      return switch (key) {
        'instagram' || 'ig' || 'insta' => SocialPlatform.instagram,
        'tiktok' => SocialPlatform.tiktok,
        'youtubeshorts' || 'youtube' || 'shorts' || 'yt' =>
          SocialPlatform.youtube,
        'facebook' || 'fb' => SocialPlatform.facebook,
        _ => null,
      };
    }

    return null;
  }

  /// Backend `ReelSourcePlatform` int values. Deliberately not
  /// `values[code - 1]`: that couples the wire contract to this enum's
  /// declaration order and breaks silently if a member is ever reordered.
  static SocialPlatform? _fromCode(int code) => switch (code) {
        1 => SocialPlatform.instagram,
        2 => SocialPlatform.tiktok,
        3 => SocialPlatform.youtube,
        4 => SocialPlatform.facebook,
        _ => null,
      };
}

extension SocialPlatformX on SocialPlatform {
  String get displayName => switch (this) {
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.tiktok => 'TikTok',
        SocialPlatform.youtube => 'YouTube',
        SocialPlatform.facebook => 'Facebook',
      };

  IconData get icon => switch (this) {
        SocialPlatform.instagram => Icons.camera_alt,
        SocialPlatform.tiktok => Icons.music_note,
        SocialPlatform.youtube => Icons.play_circle,
        SocialPlatform.facebook => Icons.facebook,
      };

  Color get color => switch (this) {
        SocialPlatform.instagram => const Color(0xFFE4405F),
        SocialPlatform.tiktok => const Color(0xFF000000),
        SocialPlatform.youtube => const Color(0xFFFF0000),
        SocialPlatform.facebook => const Color(0xFF1877F2),
      };
}

/// First leg of the OAuth dance: the provider authorize URL the app opens in a
/// browser, plus the opaque [state] that must round-trip back through the
/// callback so it can be matched against the request that started it (CSRF
/// protection).
class SocialAuthorization {
  const SocialAuthorization({
    required this.authorizationUrl,
    required this.state,
  });

  final String authorizationUrl;
  final String state;
}

class SocialAccount {
  const SocialAccount({
    required this.id,
    required this.platform,
    required this.handle,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.followerCount,
    required this.isConnected,
    this.accessToken,
    this.connectedAt,
  });

  final String id;
  final SocialPlatform platform;
  final String handle;
  final String username;
  final String displayName;
  final String avatarUrl;
  final int followerCount;
  final bool isConnected;
  final String? accessToken;
  final DateTime? connectedAt;

  SocialAccount copyWith({
    String? id,
    SocialPlatform? platform,
    String? handle,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? followerCount,
    bool? isConnected,
    String? accessToken,
    DateTime? connectedAt,
  }) {
    return SocialAccount(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      handle: handle ?? this.handle,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followerCount: followerCount ?? this.followerCount,
      isConnected: isConnected ?? this.isConnected,
      accessToken: accessToken ?? this.accessToken,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}
