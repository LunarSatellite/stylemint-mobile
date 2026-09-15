import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator card: cover strip, overlapping avatar, name with verified tick,
/// style tags as one editorial line, follower count and a follow-button slot.
class MallCreatorCard extends StatelessWidget {
  const MallCreatorCard({
    required this.creator,
    super.key,
    this.onTap,
    this.followAction,
  });

  final MallCreatorVm creator;
  final VoidCallback? onTap;

  /// Follow button slot, laid out full width at [DesignTokens.minTouchTarget]
  /// height. The kit does not own follow state.
  final Widget? followAction;

  /// Suggested rail item width.
  static const double defaultWidth = 220;

  /// Exact rendered height at the ambient text scale. Every card in a rail
  /// reserves the same slots, so pass `hasFollowAction` for the rail as a
  /// whole.
  static double heightFor(
    BuildContext context, {
    bool hasFollowAction = true,
  }) => _CreatorMetrics(
    MallMetrics.scalerOf(context),
  ).cardHeight(hasFollowAction: hasFollowAction);

  static const TextStyle _nameStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  static const TextStyle _metaStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: DesignTokens.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final metrics = _CreatorMetrics(MallMetrics.scalerOf(context));
    final item = creator;
    final tags = item.styleTags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .join(' · ');
    final handle = item.handle;
    final meta = tags.isNotEmpty
        ? tags
        : (handle == null || handle.isEmpty ? '' : '@$handle');
    final followers = item.followerCount;
    final action = followAction;
    final radius = BorderRadius.circular(DesignTokens.cardRadius);
    final label = [
      item.name,
      if (item.isVerified) strings.verified,
      if (meta.isNotEmpty) meta,
      if (followers != null) strings.followers(followers),
    ].join(', ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: radius,
        boxShadow: DesignTokens.shadowCard,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height:
                            _CreatorMetrics.coverHeight +
                            _CreatorMetrics.avatarOverlap,
                        child: Stack(
                          children: [
                            PositionedDirectional(
                              top: 0,
                              start: 0,
                              end: 0,
                              height: _CreatorMetrics.coverHeight,
                              child: MallNetworkImage(
                                url: item.coverUrl,
                                placeholder: const MallImagePlaceholder(
                                  showMark: false,
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              start: _CreatorMetrics.inset,
                              bottom: 0,
                              child: MallAvatar(
                                name: item.name,
                                imageUrl: item.avatarUrl,
                                size: _CreatorMetrics.avatarSize,
                                ringColor: DesignTokens.surfaceRaised,
                                ringWidth: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _CreatorMetrics.avatarGap),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          _CreatorMetrics.inset,
                          0,
                          _CreatorMetrics.inset,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: metrics.nameHeight,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _nameStyle,
                                    ),
                                  ),
                                  if (item.isVerified) ...[
                                    const SizedBox(width: DesignTokens.s4),
                                    const MallVerifiedBadge(size: 15),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: _CreatorMetrics.lineGap),
                            SizedBox(
                              height: metrics.metaHeight,
                              child: Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _metaStyle,
                              ),
                            ),
                            const SizedBox(height: _CreatorMetrics.lineGap),
                            SizedBox(
                              height: metrics.metaHeight,
                              child: followers == null
                                  ? null
                                  : Text(
                                      strings.followers(followers),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _metaStyle.copyWith(
                                        color: DesignTokens.textLight,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: MallTapOverlay(semanticLabel: label, onTap: onTap),
                ),
              ],
            ),
            if (action != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  _CreatorMetrics.inset,
                  _CreatorMetrics.actionGap,
                  _CreatorMetrics.inset,
                  0,
                ),
                child: SizedBox(
                  height: DesignTokens.minTouchTarget,
                  child: action,
                ),
              ),
            const SizedBox(height: _CreatorMetrics.bottomGap),
          ],
        ),
      ),
    );
  }
}

class _CreatorMetrics {
  _CreatorMetrics(TextScaler scaler)
    : nameHeight = MallMetrics.textHeight(
        scaler,
        fontSize: 15,
        lineHeight: 1.3,
      ),
      metaHeight = MallMetrics.textHeight(
        scaler,
        fontSize: 12,
        lineHeight: 1.4,
      );

  static const double coverHeight = 76;
  static const double avatarSize = 56;
  static const double avatarOverlap = 28;
  static const double avatarGap = 10;
  static const double lineGap = 2;
  static const double actionGap = 12;
  static const double bottomGap = 14;
  static const double inset = 14;

  final double nameHeight;
  final double metaHeight;

  double cardHeight({required bool hasFollowAction}) =>
      coverHeight +
      avatarOverlap +
      avatarGap +
      nameHeight +
      lineGap +
      metaHeight +
      lineGap +
      metaHeight +
      (hasFollowAction ? actionGap + DesignTokens.minTouchTarget : 0) +
      bottomGap;
}
