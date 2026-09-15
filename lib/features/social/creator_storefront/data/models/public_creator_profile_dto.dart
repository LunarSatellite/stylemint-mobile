import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_json.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';

/// Identity `PublicCreatorProfileDto`.
class PublicCreatorProfileDto {
  const PublicCreatorProfileDto({
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
    this.socialHandles = const {},
  });

  factory PublicCreatorProfileDto.fromJson(Map<String, dynamic> json) {
    final handles = json['socialHandles'];
    return PublicCreatorProfileDto(
      accountId: readString(json['accountId']),
      displayName: readString(json['displayName']),
      handle: readOptionalString(json['handle']),
      avatarUrl: readOptionalString(json['avatarUrl']),
      coverImageUrl: readOptionalString(json['coverImageUrl']),
      bio: readOptionalString(json['bio']),
      location: readOptionalString(json['location']),
      styleTags: readStorefrontStrings(json['styleTags']),
      isVerified: readBool(json['isVerified']),
      specializationSummary: readOptionalString(json['specializationSummary']),
      socialHandles: {
        if (handles is Map)
          for (final platform in CreatorSocialPlatform.values)
            platform: ?readOptionalString(handles[platform.name]),
      },
    );
  }

  final String accountId;
  final String displayName;
  final String? handle;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? bio;
  final String? location;
  final List<String> styleTags;
  final bool isVerified;
  final String? specializationSummary;
  final Map<CreatorSocialPlatform, String> socialHandles;

  static const int maxStyleTags = 12;

  /// [requestedAccountId] fills a missing id; a missing name falls back to
  /// the handle.
  PublicCreatorProfile toDomain(String requestedAccountId) {
    final cleanHandle = handle?.replaceFirst(RegExp('^@+'), '').trim();
    final name = displayName.isNotEmpty
        ? displayName
        : (cleanHandle == null || cleanHandle.isEmpty
              ? 'StyleMint creator'
              : cleanHandle);
    final seen = <String>{};
    return PublicCreatorProfile(
      accountId: accountId.isEmpty ? requestedAccountId : accountId,
      displayName: name,
      handle: cleanHandle == null || cleanHandle.isEmpty ? null : cleanHandle,
      avatarUrl: avatarUrl,
      coverImageUrl: coverImageUrl,
      bio: bio,
      location: location,
      styleTags: [
        for (final tag in styleTags)
          if (seen.add(tag.toLowerCase())) tag,
      ].take(maxStyleTags).toList(growable: false),
      isVerified: isVerified,
      specializationSummary: specializationSummary,
      socialLinks: [
        for (final platform in CreatorSocialPlatform.values)
          ?CreatorSocialLink.from(platform, socialHandles[platform]),
      ],
    );
  }
}
