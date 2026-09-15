/// Social platforms a creator can link from their storefront.
enum CreatorSocialPlatform {
  instagram('Instagram', 'instagram.com'),
  tiktok('TikTok', 'tiktok.com'),
  youtube('YouTube', 'youtube.com'),
  facebook('Facebook', 'facebook.com');

  const CreatorSocialPlatform(this.label, this.host);

  final String label;

  /// The platform's web host; links elsewhere are ignored.
  final String host;
}

/// A creator's handle on a social platform and its https profile link.
class CreatorSocialLink {
  const CreatorSocialLink({
    required this.platform,
    required this.handle,
    required this.url,
  });

  final CreatorSocialPlatform platform;
  final String handle;
  final Uri url;

  static final RegExp _handle = RegExp(r'^[A-Za-z0-9._-]{1,100}$');

  /// The link for [raw] on [platform]: a plain handle (with or without `@`)
  /// or an https link on that platform's own host. Anything else is null.
  static CreatorSocialLink? from(CreatorSocialPlatform platform, String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;

    if (value.contains('://')) {
      final uri = Uri.tryParse(value);
      if (uri == null || uri.scheme.toLowerCase() != 'https') return null;
      final host = uri.host.toLowerCase();
      if (host != platform.host && !host.endsWith('.${platform.host}')) {
        return null;
      }
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      final handle = segments.isEmpty
          ? platform.label
          : segments.last.replaceFirst(RegExp('^@+'), '');
      return CreatorSocialLink(platform: platform, handle: handle, url: uri);
    }

    final handle = value.replaceFirst(RegExp('^@+'), '');
    if (!_handle.hasMatch(handle)) return null;
    final url = switch (platform) {
      CreatorSocialPlatform.instagram => 'https://www.instagram.com/$handle',
      CreatorSocialPlatform.tiktok => 'https://www.tiktok.com/@$handle',
      CreatorSocialPlatform.youtube => 'https://www.youtube.com/@$handle',
      CreatorSocialPlatform.facebook => 'https://www.facebook.com/$handle',
    };
    return CreatorSocialLink(
      platform: platform,
      handle: handle,
      url: Uri.parse(url),
    );
  }
}

/// `GET v1/public/creators/{accountId}`: what shoppers see about a creator.
class PublicCreatorProfile {
  const PublicCreatorProfile({
    required this.accountId,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.coverImageUrl,
    this.bio,
    this.location,
    this.styleTags = const [],
    this.isVerified = false,
    this.specializationSummary,
    this.socialLinks = const [],
  });

  final String accountId;
  final String displayName;

  /// Without the leading `@`.
  final String? handle;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? bio;
  final String? location;
  final List<String> styleTags;
  final bool isVerified;

  /// e.g. "Streetwear stylist".
  final String? specializationSummary;
  final List<CreatorSocialLink> socialLinks;

  /// First word of the display name, for copy such as "Shop Sarah's picks".
  String get firstName {
    final words = displayName.trim().split(RegExp(r'\s+'));
    return words.first.isEmpty ? displayName : words.first;
  }
}
