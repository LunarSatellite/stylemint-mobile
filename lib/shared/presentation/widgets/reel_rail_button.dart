import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/platform_avatar_carousel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// Building blocks of a reel's right-hand rail ("A · Studio", approved
// 2026-09-14): crisp icons straight on the video with counts underneath, the
// creator (profile + follow) on top and the tagged product — or the cart — at
// the bottom. No boxes, and no BackdropFilter over live video.

/// Shared measurements and colours of the reel rail.
abstract final class ReelRailStyle {
  /// Width of the rail column; every item is centred in it.
  static const double width = 52;

  /// Half of the rail's 18dp rhythm above and below each item, so the hit
  /// areas of neighbouring items meet and a near miss never falls through to
  /// play/pause.
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(vertical: 9);

  /// Text and icons drawn on brand green.
  static const Color ink = Color(0xFF062612);

  /// The check on the white "following" badge.
  static const Color inkDeep = Color(0xFF0B3D22);

  /// Keeps rail text legible over bright video.
  static const List<Shadow> textShadow = [
    Shadow(color: Color(0x80000000), blurRadius: 5, offset: Offset(0, 1)),
  ];

  static const double pressedScale = 0.9;
  static const Duration pressDuration = Duration(milliseconds: 120);

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Tap target for one rail item: at least 48×48dp, scales to 0.9 while
/// pressed (not with reduced motion) and exposes a single semantics node.
class ReelRailPressable extends StatefulWidget {
  const ReelRailPressable({
    required this.label,
    required this.child,
    this.hint,
    this.onTap,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Widget child;

  static const double minTarget = 48;

  @override
  State<ReelRailPressable> createState() => _ReelRailPressableState();
}

class _ReelRailPressableState extends State<ReelRailPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ReelRailStyle.reduceMotion(context);
    final onTap = widget.onTap;
    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: ReelRailPressable.minTarget,
        minHeight: ReelRailPressable.minTarget,
      ),
      child: Padding(
        padding: widget.padding,
        child: AnimatedScale(
          scale: _pressed && !reduceMotion ? ReelRailStyle.pressedScale : 1,
          duration: reduceMotion ? Duration.zero : ReelRailStyle.pressDuration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
    if (onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: content,
      );
    }
    return Semantics(
      container: true,
      button: onTap != null,
      label: widget.label,
      hint: widget.hint,
      onTap: onTap,
      excludeSemantics: true,
      child: content,
    );
  }
}

/// A rail action — [icon] (a [ReelRailIcons] document) with its [count]
/// underneath: likes, comments, shares or views.
class ReelRailButton extends StatefulWidget {
  const ReelRailButton({
    required this.icon,
    required this.label,
    this.count,
    this.hint,
    this.onTap,
    this.iconColor = DesignTokens.textWhite,
    this.popOnTap = false,
    this.padding = ReelRailStyle.itemPadding,
    super.key,
  });

  final String icon;

  /// Semantics label; the count is appended ("Like, 128").
  final String label;

  /// Shown under the icon. Null or empty hides it.
  final String? count;
  final String? hint;
  final VoidCallback? onTap;
  final Color iconColor;

  /// Plays a short pop (1 → 1.28 → 1 over 420ms) on tap, except with reduced
  /// motion.
  final bool popOnTap;
  final EdgeInsetsGeometry padding;

  static const TextStyle countStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: DesignTokens.textWhite,
    shadows: ReelRailStyle.textShadow,
  );

  @override
  State<ReelRailButton> createState() => _ReelRailButtonState();
}

class _ReelRailButtonState extends State<ReelRailButton>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.28,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.28,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 65,
    ),
  ]);

  AnimationController? _pop;

  AnimationController get _popController => _pop ??= AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  void _handleTap() {
    final onTap = widget.onTap;
    if (onTap == null) return;
    if (widget.popOnTap && !ReelRailStyle.reduceMotion(context)) {
      unawaited(_popController.forward(from: 0));
    }
    onTap();
  }

  @override
  void dispose() {
    _pop?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.count;
    final count = raw == null || raw.isEmpty ? null : raw;
    Widget icon = ReelRailIcon(widget.icon, color: widget.iconColor);
    if (widget.popOnTap) {
      icon = ScaleTransition(
        scale: _popController.drive(_popScale),
        child: icon,
      );
    }
    return ReelRailPressable(
      label: count == null ? widget.label : '${widget.label}, $count',
      hint: widget.hint,
      onTap: widget.onTap == null ? null : _handleTap,
      padding: widget.padding,
      child: SizedBox(
        width: ReelRailStyle.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (count != null) ...[
              const SizedBox(height: 3),
              Text(
                count,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: ReelRailButton.countStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The creator at the top of the rail: a 44dp avatar in a 2dp white ring and
/// a 20dp follow badge overlapping its bottom edge.
///
/// Two targets share the avatar. The upper part opens the profile
/// ([onOpenProfile]); a 48×48 area around the badge toggles follow
/// ([onToggleFollow]). A null callback leaves its target (and, for follow, the
/// badge) out.
class ReelRailAvatar extends StatefulWidget {
  const ReelRailAvatar({
    required this.creatorName,
    required this.imageUrls,
    this.isFollowing = false,
    this.onOpenProfile,
    this.onToggleFollow,
    this.imageProviderBuilder,
    super.key,
  });

  final String creatorName;

  /// Rotated by [PlatformAvatarCarousel].
  final List<String> imageUrls;
  final bool isFollowing;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onToggleFollow;
  final AvatarImageProviderBuilder? imageProviderBuilder;

  static const double size = 44;

  /// The avatar, the badge's 8dp overhang and the space above the next item's
  /// own padding (18dp rhythm).
  static const double height = 63;

  static const Key followBadgeKey = ValueKey('reel-rail-follow-badge');
  static const Key followingBadgeKey = ValueKey('reel-rail-following-badge');

  static const double _badgeSize = 20;
  static const double _badgeOverhang = 8;
  static const double _profileTargetHeight = 32;

  @override
  State<ReelRailAvatar> createState() => _ReelRailAvatarState();
}

class _ReelRailAvatarState extends State<ReelRailAvatar> {
  bool _facePressed = false;
  bool _badgePressed = false;

  void _pressFace(bool value) {
    if (_facePressed != value) setState(() => _facePressed = value);
  }

  void _pressBadge(bool value) {
    if (_badgePressed != value) setState(() => _badgePressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ReelRailStyle.reduceMotion(context);
    final pressDuration = reduceMotion
        ? Duration.zero
        : ReelRailStyle.pressDuration;
    double scale({required bool pressed}) =>
        pressed && !reduceMotion ? ReelRailStyle.pressedScale : 1;
    final name = widget.creatorName;
    final following = widget.isFollowing;
    final onOpenProfile = widget.onOpenProfile;
    final onToggleFollow = widget.onToggleFollow;

    final Widget face = Container(
      width: ReelRailAvatar.size,
      height: ReelRailAvatar.size,
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DesignTokens.textWhite, width: 2),
      ),
      child: PlatformAvatarCarousel(
        imageUrls: widget.imageUrls,
        size: ReelRailAvatar.size,
        imageProviderBuilder: widget.imageProviderBuilder,
      ),
    );

    return SizedBox(
      width: ReelRailStyle.width,
      height: ReelRailAvatar.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (ReelRailStyle.width - ReelRailAvatar.size) / 2,
            top: 0,
            child: AnimatedScale(
              scale: scale(pressed: _facePressed),
              duration: pressDuration,
              curve: Curves.easeOut,
              child: onOpenProfile == null
                  ? Semantics(image: true, label: name, child: face)
                  : ExcludeSemantics(child: face),
            ),
          ),
          if (onToggleFollow != null) ...[
            Positioned(
              left: (ReelRailStyle.width - ReelRailAvatar._badgeSize) / 2,
              top:
                  ReelRailAvatar.size +
                  ReelRailAvatar._badgeOverhang -
                  ReelRailAvatar._badgeSize,
              child: AnimatedScale(
                scale: scale(pressed: _badgePressed),
                duration: pressDuration,
                curve: Curves.easeOut,
                child: _FollowBadge(
                  following: following,
                  reduceMotion: reduceMotion,
                ),
              ),
            ),
            Positioned(
              left: (ReelRailStyle.width - ReelRailPressable.minTarget) / 2,
              top: ReelRailAvatar.height - ReelRailPressable.minTarget,
              width: ReelRailPressable.minTarget,
              height: ReelRailPressable.minTarget,
              child: _HitTarget(
                label: following ? 'Following $name' : 'Follow $name',
                onTap: onToggleFollow,
                onPressed: _pressBadge,
              ),
            ),
          ],
          // Above the follow target, so a tap on the face opens the profile.
          if (onOpenProfile != null)
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: ReelRailAvatar._profileTargetHeight,
              child: _HitTarget(
                label: "Open $name's profile",
                onTap: onOpenProfile,
                onPressed: _pressFace,
              ),
            ),
        ],
      ),
    );
  }
}

class _FollowBadge extends StatelessWidget {
  const _FollowBadge({required this.following, required this.reduceMotion});

  final bool following;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      width: ReelRailAvatar._badgeSize,
      height: ReelRailAvatar._badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: following ? DesignTokens.textWhite : DesignTokens.primaryGreen,
        shape: BoxShape.circle,
        border: Border.all(color: DesignTokens.textWhite, width: 2),
      ),
      child: following
          ? const ReelRailIcon(
              ReelRailIcons.check,
              key: ReelRailAvatar.followingBadgeKey,
              size: 12,
              color: ReelRailStyle.inkDeep,
              shadow: false,
            )
          : const ReelRailIcon(
              ReelRailIcons.plus,
              key: ReelRailAvatar.followBadgeKey,
              size: 12,
              color: ReelRailStyle.ink,
              shadow: false,
            ),
    );
  }
}

/// An invisible, labelled tap area that reports press state to its owner.
class _HitTarget extends StatelessWidget {
  const _HitTarget({
    required this.label,
    required this.onTap,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onTap;
  final ValueChanged<bool> onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onTapDown: (_) => onPressed(true),
        onTapUp: (_) => onPressed(false),
        onTapCancel: () => onPressed(false),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// The reel's first tagged product at the bottom of the rail: a 48dp photo
/// tile with a green bag badge and the compact price in a green chip.
class ReelRailProductTile extends StatelessWidget {
  const ReelRailProductTile({
    required this.imageUrl,
    required this.priceLabel,
    required this.label,
    this.onTap,
    this.padding = ReelRailStyle.itemPadding,
    super.key,
  });

  final String imageUrl;

  /// Compact price, e.g. "Rs 1.8K" ([formatMoneyCompact]).
  final String priceLabel;

  /// Semantics label, e.g. "Shop Nomad Canvas Tote, Rs 1,800".
  final String label;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  static const double size = 48;
  static const double radius = 13;

  static const TextStyle priceStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: ReelRailStyle.ink,
  );

  static const Widget _placeholder = ColoredBox(
    color: DesignTokens.bgAppBodyLight,
    child: Center(
      child: ReelRailIcon(
        ReelRailIcons.bag,
        size: 20,
        color: DesignTokens.iconLight,
        shadow: false,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.isEmpty
        ? _placeholder
        : CachedNetworkImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                const ColoredBox(color: DesignTokens.bgAppBodyLight),
            errorWidget: (_, _, _) => _placeholder,
          );
    return ReelRailPressable(
      label: label,
      onTap: onTap,
      padding: padding,
      child: SizedBox(
        width: ReelRailStyle.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        borderRadius: BorderRadius.all(Radius.circular(radius)),
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(radius),
                        ),
                        border: Border.all(
                          color: const Color(0xE6FFFFFF),
                          width: 1.5,
                        ),
                      ),
                      child: image,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF111111),
                          width: 2,
                        ),
                      ),
                      child: const ReelRailIcon(
                        ReelRailIcons.bagBadge,
                        size: 11,
                        color: ReelRailStyle.ink,
                        shadow: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            // A long price may be wider than the rail; let the chip spill
            // evenly past it rather than clip, as in the design.
            OverflowBox(
              maxWidth: 96,
              fit: OverflowBoxFit.deferToChild,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: DesignTokens.primaryGreen,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  child: Text(
                    priceLabel,
                    maxLines: 1,
                    softWrap: false,
                    style: priceStyle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The cart at the bottom of the rail when a reel has no tagged products: a
/// 44dp brand-green disc with a bag, and the cart's item count as a badge.
class ReelRailCartDisc extends StatelessWidget {
  const ReelRailCartDisc({
    this.itemCount = 0,
    this.onTap,
    this.padding = ReelRailStyle.itemPadding,
    super.key,
  });

  final int itemCount;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final badge = itemCount > 0 ? formatRailCount(itemCount) : null;
    return ReelRailPressable(
      label: badge == null ? 'Cart' : 'Cart, $badge',
      onTap: onTap,
      padding: padding,
      child: SizedBox(
        width: ReelRailStyle.width,
        height: size,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: DesignTokens.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const ReelRailIcon(
                  ReelRailIcons.bag,
                  size: 22,
                  color: ReelRailStyle.ink,
                  shadow: false,
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DesignTokens.textWhite,
                      borderRadius: const BorderRadius.all(Radius.circular(9)),
                      border: Border.all(
                        color: DesignTokens.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: ReelRailStyle.ink,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact count for rail labels: 950, 1.2K, 3.4M.
String formatRailCount(int count) => formatCompactNumber(count);
