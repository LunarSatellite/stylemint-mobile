import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/entities/public_brand_profile.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_follow_button.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_hero_parts.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The flagship hero: a tall cover, the logo tile over its edge, "Official
/// store", the name in the display face with the verified tick, tagline and
/// origin ("Kathmandu, Nepal · Since 2019"), plus Follow and Share.
class BrandStorefrontHero extends StatelessWidget {
  const BrandStorefrontHero({
    required this.vendorAccountId,
    required this.coverExtent,
    required this.onShare,
    super.key,
    this.brand,
  });

  final String vendorAccountId;
  final double coverExtent;
  final VoidCallback onShare;

  /// Null while loading.
  final PublicBrandProfile? brand;

  static const double logoSize = 84;

  static const TextStyle _taglineStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: DesignTokens.textLight,
  );

  static const TextStyle _originStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: DesignTokens.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    final profile = brand;
    final tagline = profile?.tagline;
    final originLine = profile?.originLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: coverExtent + logoSize / 2,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: coverExtent,
                child: profile == null
                    ? const SmSkeleton.box(radius: 0)
                    : StorefrontCover(
                        imageUrl: profile.coverImageUrl,
                        height: coverExtent,
                      ),
              ),
              PositionedDirectional(
                start: DesignTokens.s16,
                end: DesignTokens.s16,
                top: storefrontOverlapTop(coverExtent, logoSize),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (profile == null)
                      const SmSkeleton.box(
                        width: logoSize,
                        height: logoSize,
                        radius: 22,
                      )
                    else
                      _BrandLogo(name: profile.name, url: profile.logoUrl),
                    const SizedBox(width: DesignTokens.s12),
                    // Scales down rather than overflowing on small phones
                    // with large text.
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.bottomEnd,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.bottomEnd,
                          child: profile == null
                              ? const SmSkeleton.box(
                                  width: 112,
                                  height: DesignTokens.minTouchTarget,
                                  radius: DesignTokens.buttonRadius,
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    StorefrontFollowButton(
                                      accountId: vendorAccountId,
                                      name: profile.name,
                                    ),
                                    const SizedBox(width: DesignTokens.s8),
                                    StorefrontRoundButton(
                                      tooltip: 'Share ${profile.name}',
                                      onPressed: onShare,
                                      child: const Icon(
                                        Icons.ios_share_rounded,
                                        size: 19,
                                        color: DesignTokens.textWhite,
                                      ),
                                    ),
                                  ],
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
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s20,
          ),
          child: profile == null
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SmSkeleton.line(width: 96),
                    SizedBox(height: DesignTokens.s12),
                    SmSkeleton.line(width: 210, height: 28),
                    SizedBox(height: DesignTokens.s12),
                    SmSkeleton.line(width: 250),
                    SizedBox(height: DesignTokens.s8),
                    SmSkeleton.line(width: 170),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MallEyebrow(
                      profile.isVerified
                          ? 'Verified · Official store'
                          : 'Official store',
                    ),
                    const SizedBox(height: 6),
                    StorefrontDisplayName(
                      name: profile.name,
                      isVerified: profile.isVerified,
                    ),
                    if (tagline != null) ...[
                      const SizedBox(height: DesignTokens.s8),
                      Text(
                        tagline,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: _taglineStyle,
                      ),
                    ],
                    if (originLine != null) ...[
                      const SizedBox(height: DesignTokens.s12),
                      Text.rich(
                        TextSpan(
                          children: [
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: DesignTokens.textMuted,
                              ),
                            ),
                            TextSpan(text: ' $originLine'),
                          ],
                        ),
                        style: _originStyle,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.name, required this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = BrandStorefrontHero.logoSize;
    const ring = 3.0;
    final logo = url;
    final initial = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(ring),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppFoundation,
          borderRadius: BorderRadius.circular(22),
          boxShadow: DesignTokens.shadowLifted,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22 - ring),
          child: logo != null
              ? ColoredBox(
                  color: DesignTokens.lightSurface,
                  child: MallNetworkImage(url: logo),
                )
              : ColoredBox(
                  color: DesignTokens.surfaceRaised,
                  child: Center(
                    child: Text(
                      initial,
                      style: DesignTokens.displayTitle,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
