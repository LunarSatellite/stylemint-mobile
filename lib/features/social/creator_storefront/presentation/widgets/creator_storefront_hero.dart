import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_follow_button.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_hero_parts.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The top of a creator's storefront: cover, overlapping avatar, name in the
/// display face, handle and location, bio, style tags, stats, follow and
/// social links. While [profile] is null it shows the preview name, handle
/// and avatar with skeletons for the rest.
class CreatorStorefrontHero extends StatelessWidget {
  const CreatorStorefrontHero({
    required this.accountId,
    required this.displayName,
    required this.coverExtent,
    super.key,
    this.profile,
    this.previewHandle,
    this.previewAvatarUrl,
    this.stats = const [],
    this.onSocialTap,
  });

  final String accountId;
  final String displayName;
  final double coverExtent;

  /// Null while loading.
  final PublicCreatorProfile? profile;
  final String? previewHandle;
  final String? previewAvatarUrl;
  final List<StorefrontStat> stats;
  final ValueChanged<CreatorSocialLink>? onSocialTap;

  static const double avatarSize = 92;
  static const double _ring = 4;

  static const TextStyle _metaStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: DesignTokens.textLight,
  );

  static String socialIconAsset(CreatorSocialPlatform platform) =>
      'assets/icons/${platform.name}.svg';

  @override
  Widget build(BuildContext context) {
    final creator = profile;
    final loading = creator == null;
    final handle = creator?.handle ?? _cleanHandle(previewHandle);
    final location = creator?.location;
    final specialization = creator?.specializationSummary;
    final bio = creator?.bio;
    final tags = creator?.styleTags ?? const <String>[];
    final links = creator?.socialLinks ?? const <CreatorSocialLink>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: coverExtent + avatarSize / 2,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: coverExtent,
                child: loading
                    ? const SmSkeleton.box(radius: 0)
                    : StorefrontCover(
                        imageUrl: creator.coverImageUrl,
                        height: coverExtent,
                      ),
              ),
              PositionedDirectional(
                start: DesignTokens.s16,
                end: DesignTokens.s16,
                top: storefrontOverlapTop(coverExtent, avatarSize),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: DesignTokens.shadowLifted,
                        ),
                        child: MallAvatar(
                          name: displayName,
                          imageUrl: creator?.avatarUrl ?? previewAvatarUrl,
                          size: avatarSize,
                          ringColor: DesignTokens.bgAppFoundation,
                          ringWidth: _ring,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    // Scales down rather than overflowing on small phones
                    // with large text.
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.bottomEnd,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.bottomEnd,
                          child: loading
                              ? const SmSkeleton.box(
                                  width: 112,
                                  height: DesignTokens.minTouchTarget,
                                  radius: DesignTokens.buttonRadius,
                                )
                              : StorefrontFollowButton(
                                  accountId: accountId,
                                  name: displayName,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DesignTokens.s16,
            DesignTokens.s12,
            DesignTokens.s16,
            DesignTokens.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (specialization != null) ...[
                MallEyebrow(specialization, maxLines: 2),
                const SizedBox(height: 6),
              ],
              StorefrontDisplayName(
                name: displayName,
                isVerified: creator?.isVerified ?? false,
              ),
              if (handle != null || location != null) ...[
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      if (handle != null) TextSpan(text: '@$handle'),
                      if (handle != null && location != null)
                        const TextSpan(text: '   '),
                      if (location != null) ...[
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: DesignTokens.textMuted,
                          ),
                        ),
                        TextSpan(text: ' $location'),
                      ],
                    ],
                  ),
                  style: _metaStyle,
                ),
              ],
              if (loading) ...const [
                SizedBox(height: DesignTokens.s16),
                SmSkeleton.line(width: 260),
                SizedBox(height: DesignTokens.s8),
                SmSkeleton.line(width: 190),
                SizedBox(height: DesignTokens.s20),
                SmSkeleton.line(width: 220, height: 32),
              ] else ...[
                if (bio != null) ...[
                  const SizedBox(height: DesignTokens.s12),
                  StorefrontExpandableText(text: bio),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.s12),
                  Wrap(
                    spacing: DesignTokens.s8,
                    runSpacing: DesignTokens.s8,
                    children: [
                      for (final tag in tags) StorefrontTagChip(label: tag),
                    ],
                  ),
                ],
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.s20),
                  StorefrontStatsRow(stats: stats),
                ],
                if (links.isNotEmpty && onSocialTap != null) ...[
                  const SizedBox(height: DesignTokens.s16),
                  Wrap(
                    spacing: DesignTokens.s8,
                    runSpacing: DesignTokens.s8,
                    children: [
                      for (final link in links)
                        StorefrontRoundButton(
                          tooltip: '${link.platform.label} @${link.handle}',
                          onPressed: () => onSocialTap!(link),
                          child: SvgPicture.asset(
                            socialIconAsset(link.platform),
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              DesignTokens.textLight,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String? _cleanHandle(String? raw) {
    final value = raw?.trim().replaceFirst(RegExp('^@+'), '') ?? '';
    return value.isEmpty ? null : value;
  }
}
