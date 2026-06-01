import 'package:flutter/material.dart';

enum SocialPlatform {
  instagram,
  tiktok,
  youtube,
  facebook,
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
