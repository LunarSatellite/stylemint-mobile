import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_follow_button.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_hero_parts.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A cinematic talent-profile hero. The creator's identity and primary actions
/// live on the portrait itself, like an actor or artist profile, rather than in
/// a conventional account header below the cover.
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
  final PublicCreatorProfile? profile;
  final String? previewHandle;
  final String? previewAvatarUrl;
  final List<StorefrontStat> stats;
  final ValueChanged<CreatorSocialLink>? onSocialTap;

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

    return SizedBox(
      height: coverExtent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (loading)
            const SmSkeleton.box(radius: 0)
          else
            StorefrontCover(
              imageUrl: creator.coverImageUrl,
              height: coverExtent,
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.35, 0.68, 1],
                colors: [
                  Color(0x24000000),
                  Color(0x05000000),
                  Color(0xB309090B),
                  Color(0xFF09090B),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            start: DesignTokens.s16,
            end: DesignTokens.s16,
            bottom: DesignTokens.s16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (specialization != null) ...[
                  _TalentLabel(label: specialization),
                  const SizedBox(height: DesignTokens.s8),
                ],
                StorefrontDisplayName(
                  name: displayName,
                  isVerified: creator?.isVerified ?? false,
                  style: const TextStyle(
                    fontFamily: DesignTokens.displayFontFamily,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                    letterSpacing: -0.7,
                    color: DesignTokens.textWhite,
                  ),
                ),
                if (handle != null || location != null) ...[
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (handle != null) TextSpan(text: '@$handle'),
                        if (handle != null && location != null)
                          const TextSpan(text: '  ·  '),
                        if (location != null) ...[
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: DesignTokens.textLight,
                            ),
                          ),
                          TextSpan(text: ' $location'),
                        ],
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: DesignTokens.textLight,
                    ),
                  ),
                ],
                if (loading) ...const [
                  SizedBox(height: DesignTokens.s12),
                  SmSkeleton.line(width: 240),
                  SizedBox(height: DesignTokens.s8),
                  SmSkeleton.line(width: 180),
                ] else ...[
                  if (bio != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.42,
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final tag in tags.take(4)) ...[
                            _GlassTag(label: tag),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.s12),
                    _TalentStats(stats: stats),
                  ],
                ],
                const SizedBox(height: DesignTokens.s12),
                Row(
                  children: [
                    ExcludeSemantics(
                      child: MallAvatar(
                        name: displayName,
                        imageUrl: creator?.avatarUrl ?? previewAvatarUrl,
                        size: 46,
                        ringColor: DesignTokens.textWhite,
                        ringWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: loading
                          ? const SmSkeleton.box(
                              height: DesignTokens.minTouchTarget,
                              radius: DesignTokens.buttonRadius,
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: StorefrontFollowButton(
                                accountId: accountId,
                                name: displayName,
                              ),
                            ),
                    ),
                    if (!loading &&
                        links.isNotEmpty &&
                        onSocialTap != null) ...[
                      const SizedBox(width: DesignTokens.s8),
                      for (final link in links.take(2)) ...[
                        StorefrontRoundButton(
                          tooltip: '${link.platform.label} @${link.handle}',
                          onPressed: () => onSocialTap!(link),
                          child: SvgPicture.asset(
                            socialIconAsset(link.platform),
                            width: 17,
                            height: 17,
                            colorFilter: const ColorFilter.mode(
                              DesignTokens.textWhite,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _cleanHandle(String? raw) {
    final value = raw?.trim().replaceFirst(RegExp('^@+'), '') ?? '';
    return value.isEmpty ? null : value;
  }
}

class _TalentLabel extends StatelessWidget {
  const _TalentLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x4209090B),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: DesignTokens.glassStroke),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.25,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
    ),
  );
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0x29FFFFFF),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0x3DFFFFFF)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textWhite,
      ),
    ),
  );
}

class _TalentStats extends StatelessWidget {
  const _TalentStats({required this.stats});

  final List<StorefrontStat> stats;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x3809090B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignTokens.glassStroke),
        ),
        child: Row(
          children: [
            for (final (index, stat) in stats.indexed) ...[
              if (index > 0)
                Container(
                  width: 1,
                  height: 28,
                  color: const Color(0x33FFFFFF),
                ),
              Expanded(
                child: Semantics(
                  label: '${stat.value} ${stat.label}',
                  excludeSemantics: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stat.value,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
