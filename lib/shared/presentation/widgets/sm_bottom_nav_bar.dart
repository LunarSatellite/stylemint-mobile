import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_nav_icons.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Resolves a Profile tab photo URL to an image.
typedef SmNavAvatarImage = ImageProvider Function(String url);

/// One tab of [SmBottomNavBar].
@immutable
class SmBottomNavItem {
  const SmBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
    this.avatarUrl,
  });

  /// A tab drawn with a [SmNavIcons] glyph: outline when inactive, filled
  /// mint with cut-out details when active.
  SmBottomNavItem.glyph(
    SmNavGlyph glyph, {
    required String label,
    int badge = 0,
    String? avatarUrl,
  }) : this(
         icon: SmNavIcon(glyph),
         activeIcon: SmNavIcon(glyph, active: true),
         label: label,
         badge: badge,
         avatarUrl: avatarUrl,
       );

  final Widget icon;
  final Widget activeIcon;

  /// One word, shown under the icon.
  final String label;

  /// Count on the red badge; hidden at 0, capped at "99+".
  final int badge;

  /// Profile photo drawn instead of the icons. The icons remain the fallback
  /// when this is null or empty, or when the photo fails to load.
  final String? avatarUrl;
}

/// The app's bottom navigation ("A · Studio bar", approved 2026-09-14), shared
/// by the customer, creator and vendor surfaces.
///
/// A solid #0B0E0D bar, 64dp over the bottom safe area, under a white 7%
/// hairline — no blur and no elevation, so it reads the same over a video reel
/// and over a plain page. The active tab gets a mint pill behind a filled
/// icon. Purely presentational: the host navigates in [onTap].
class SmBottomNavBar extends StatelessWidget {
  const SmBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerAction,
    this.avatarImage = _networkAvatar,
    super.key,
  }) : assert(items.length >= 2, 'A bottom bar needs at least two tabs');

  /// Height of the bar's content, between the hairline and the safe area.
  static const double height = 64;

  /// Vertical centre of the tab icons within the content; a [centerAction]
  /// lines up with it.
  static const double iconCenterY = _pillTop + _pillHeight / 2;

  /// How long the active pill takes to fade in or out.
  static const Duration pillDuration = Duration(milliseconds: 200);

  static const double _pillTop = 9;
  static const double _pillWidth = 56;
  static const double _pillHeight = 30;
  static const double _labelGap = 3;

  static const Key badgeKey = ValueKey('sm-nav-badge');
  static const Key avatarKey = ValueKey('sm-nav-avatar');
  static Key tabKey(int index) => ValueKey('sm-nav-tab-$index');
  static Key pillKey(int index) => ValueKey('sm-nav-pill-$index');

  final List<SmBottomNavItem> items;

  /// Index into [items] of the selected tab.
  final int currentIndex;

  /// Called with the tapped tab's index — including the selected tab, which
  /// hosts may use to refresh.
  final ValueChanged<int> onTap;

  /// Optional action between the two halves of [items], such as
  /// [SmNavCenterAction]. It is not a tab and takes no index.
  final Widget? centerAction;

  /// Loads a Profile tab photo; a cached network image by default.
  final SmNavAvatarImage avatarImage;

  static ImageProvider _networkAvatar(String url) =>
      CachedNetworkImageProvider(url);

  void _handleTap(int index) {
    if (index != currentIndex) unawaited(HapticFeedback.selectionClick());
    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[
      for (var i = 0; i < items.length; i++)
        Expanded(
          child: _NavTab(
            key: tabKey(i),
            index: i,
            item: items[i],
            active: i == currentIndex,
            avatarImage: avatarImage,
            onTap: () => _handleTap(i),
          ),
        ),
    ];
    final action = centerAction;
    if (action != null) {
      slots.insert(items.length ~/ 2, Expanded(child: action));
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: SmNavPalette.bar,
        border: Border(top: BorderSide(color: SmNavPalette.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Material(
          type: MaterialType.transparency,
          // Keeps the press ripple inside the bar.
          clipBehavior: Clip.hardEdge,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: slots,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The mint button in the bar's centre slot (create for creators, scan for
/// customers), without a label. The whole slot is its tap target.
///
/// At the default 44dp it sits level with the tab icons; a larger circle
/// (such as the customer Scan action) is centred in the bar and gets a soft
/// mint glow.
class SmNavCenterAction extends StatelessWidget {
  const SmNavCenterAction({
    required this.onTap,
    required this.semanticLabel,
    this.icon = SmNavIcons.plus,
    this.diameter = defaultDiameter,
    this.iconSize = SmNavIcons.size,
    super.key,
  });

  static const double defaultDiameter = 44;
  static const Key circleKey = ValueKey('sm-nav-center-circle');

  final VoidCallback onTap;
  final String semanticLabel;

  /// White SVG drawn dark on the circle; [SmNavIcons.plus] by default.
  final String icon;

  final double diameter;
  final double iconSize;

  bool get _large => diameter > defaultDiameter;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(
              top: _large
                  ? (SmBottomNavBar.height - diameter) / 2
                  : SmBottomNavBar.iconCenterY - diameter / 2,
            ),
            child: Container(
              key: circleKey,
              width: diameter,
              height: diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DesignTokens.primaryGreen,
                shape: BoxShape.circle,
                boxShadow: _large
                    ? [
                        BoxShadow(
                          color: DesignTokens.primaryGreen.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: ReelRailIcon(
                icon,
                size: iconSize,
                color: DesignTokens.buttonPrimaryText,
                shadow: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.index,
    required this.item,
    required this.active,
    required this.avatarImage,
    required this.onTap,
    super.key,
  });

  final int index;
  final SmBottomNavItem item;
  final bool active;
  final SmNavAvatarImage avatarImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final badge = item.badge > 0 ? _badgeText(item.badge) : null;
    final icon = active ? item.activeIcon : item.icon;
    final avatarUrl = item.avatarUrl;

    return Semantics(
      container: true,
      button: true,
      selected: active,
      label: badge == null ? item.label : '${item.label}, $badge',
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        excludeFromSemantics: true,
        radius: 32,
        splashFactory: InkRipple.splashFactory,
        splashColor: SmNavPalette.splash,
        focusColor: SmNavPalette.splash,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(top: SmBottomNavBar._pillTop),
          child: Column(
            children: [
              AnimatedContainer(
                key: SmBottomNavBar.pillKey(index),
                duration: reduceMotion
                    ? Duration.zero
                    : SmBottomNavBar.pillDuration,
                curve: Curves.easeOut,
                width: SmBottomNavBar._pillWidth,
                height: SmBottomNavBar._pillHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? SmNavPalette.pill
                      : SmNavPalette.pill.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(
                    SmBottomNavBar._pillHeight / 2,
                  ),
                ),
                child: SizedBox.square(
                  dimension: SmNavIcons.size,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      if (avatarUrl == null || avatarUrl.isEmpty)
                        icon
                      else
                        _NavAvatar(
                          image: avatarImage(avatarUrl),
                          active: active,
                          fallback: icon,
                        ),
                      if (badge != null)
                        Positioned(
                          left: 13,
                          top: -6,
                          child: _NavBadge(text: badge),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SmBottomNavBar._labelGap),
              // Large text shrinks to the column instead of overflowing it.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 11.5,
                      height: 1.1,
                      letterSpacing: 0,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active
                          ? SmNavPalette.labelActive
                          : SmNavPalette.inactive,
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

  static String _badgeText(int count) => count > 99 ? '99+' : '$count';
}

/// The signed-in user's photo in a 24dp circle: a white 55% ring, or a mint
/// ring with a soft mint halo when active. Shows [fallback] if it fails.
class _NavAvatar extends StatelessWidget {
  const _NavAvatar({
    required this.image,
    required this.active,
    required this.fallback,
  });

  final ImageProvider image;
  final bool active;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
      width: SmNavIcons.size,
      height: SmNavIcons.size,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
          Container(
            key: SmBottomNavBar.avatarKey,
            width: SmNavIcons.size,
            height: SmNavIcons.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SmNavPalette.avatarPlaceholder,
              border: Border.all(
                color: active ? SmNavPalette.active : SmNavPalette.avatarRing,
                width: 1.5,
              ),
              boxShadow: active
                  ? [BoxShadow(color: SmNavPalette.avatarHalo, spreadRadius: 2)]
                  : null,
            ),
            child: ClipOval(child: child),
          ),
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

/// Red count pill at the icon's top-right, edged in the bar colour.
class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: SmBottomNavBar.badgeKey,
      height: 17,
      constraints: const BoxConstraints(minWidth: 17),
      padding: const EdgeInsets.symmetric(horizontal: 3.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DesignTokens.colorError,
        borderRadius: BorderRadius.circular(8.5),
        border: Border.all(color: SmNavPalette.bar, width: 1.5),
      ),
      // The count is read out through the tab's semantics label, so the pill
      // keeps a fixed size instead of scaling with text.
      child: Text(
        text,
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 10,
          height: 1,
          letterSpacing: 0,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textWhite,
        ),
      ),
    );
  }
}
