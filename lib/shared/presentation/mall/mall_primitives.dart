import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// Small building blocks shared by the Mall components.

/// Uppercase, tracked eyebrow label above a title.
class MallEyebrow extends StatelessWidget {
  const MallEyebrow(this.text, {super.key, this.color, this.maxLines = 1});

  final String text;
  final Color? color;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: DesignTokens.eyebrow.copyWith(color: color),
    );
  }
}

enum MallBadgeTone {
  /// Brand green — discounts only.
  accent,

  /// White — "New".
  light,

  /// Warm status tone — "Low stock".
  warning,

  /// Translucent dark — counts and labels laid over imagery.
  glass,
}

/// Compact pill label. Wraps to a second line rather than truncating.
class MallBadge extends StatelessWidget {
  const MallBadge({
    required this.label,
    super.key,
    this.tone = MallBadgeTone.glass,
    this.icon,
    this.maxLines = 2,
  });

  final String label;
  final MallBadgeTone tone;
  final IconData? icon;

  /// Null lets the label wrap as far as it needs — use for disclosures that
  /// must never be truncated.
  final int? maxLines;

  static const TextStyle _style = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.2,
  );

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      MallBadgeTone.accent => (
        DesignTokens.primaryGreen,
        DesignTokens.buttonPrimaryText,
      ),
      MallBadgeTone.light => (DesignTokens.textWhite, DesignTokens.textDark),
      MallBadgeTone.warning => (
        DesignTokens.warningFillDark,
        DesignTokens.warningTextLight,
      ),
      MallBadgeTone.glass => (const Color(0x99000000), DesignTokens.textWhite),
    };
    final iconData = icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 8, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconData != null) ...[
              Icon(
                iconData,
                size: MallMetrics.scalerOf(context).scale(12),
                color: foreground,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: maxLines,
                // An ellipsis with no line cap collapses text to one line, so
                // unlimited labels (disclosures) must not set one.
                overflow: maxLines == null
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: _style.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green verified tick that scales with the adjacent text.
class MallVerifiedBadge extends StatelessWidget {
  const MallVerifiedBadge({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified_rounded,
      size: MallMetrics.scalerOf(context).scale(size),
      color: DesignTokens.primaryGreen,
      semanticLabel: MallStrings.of(context).verified,
    );
  }
}

/// Save (heart) toggle over imagery: 32dp visual inside a 44dp touch target.
class MallSaveButton extends StatelessWidget {
  const MallSaveButton({
    required this.isSaved,
    required this.onPressed,
    required this.semanticLabel,
    super.key,
  });

  final bool isSaved;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final duration = MallMetrics.reduceMotion(context)
        ? Duration.zero
        : DesignTokens.motionFast;
    return Semantics(
      container: true,
      button: true,
      toggled: isSaved,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox.square(
        dimension: DesignTokens.minTouchTarget,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: onPressed,
            radius: DesignTokens.minTouchTarget / 2,
            child: Center(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0x73000000),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 32,
                  child: AnimatedSwitcher(
                    duration: duration,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(isSaved),
                      size: 18,
                      color: isSaved
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum MallAvatarShape { circle, roundedSquare }

/// Decorative avatar or logo with an initial fallback and an optional ring
/// that separates it from a cover image. Excluded from semantics — the name
/// is always rendered next to it.
class MallAvatar extends StatelessWidget {
  const MallAvatar({
    required this.name,
    super.key,
    this.imageUrl,
    this.size = DesignTokens.avatarMedium,
    this.shape = MallAvatarShape.circle,
    this.ringColor,
    this.ringWidth = 0,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final MallAvatarShape shape;
  final Color? ringColor;
  final double ringWidth;

  BorderRadius _radius(double side) => BorderRadius.circular(
    shape == MallAvatarShape.circle ? side / 2 : side * 0.26,
  );

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? ''
        : trimmed.characters.first.toUpperCase();
    final inner = size - ringWidth * 2;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          color: ringColor,
          borderRadius: _radius(size),
        ),
        child: ClipRRect(
          borderRadius: _radius(inner),
          child: MallNetworkImage(
            url: imageUrl,
            placeholder: ColoredBox(
              color: DesignTokens.bgAppBodyLight,
              child: Center(
                child: Text(
                  initial,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: inner * 0.4,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textLight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const TextStyle _ctaTextStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w600,
  height: 1.25,
);

/// Filled brand-green pill — the one primary action in a composition.
class MallPrimaryCta extends StatelessWidget {
  const MallPrimaryCta({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: DesignTokens.buttonPrimaryText,
        disabledBackgroundColor: DesignTokens.bgAppBodyLight,
        disabledForegroundColor: DesignTokens.textMuted,
        minimumSize: const Size(DesignTokens.minTouchTarget, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: _ctaTextStyle,
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

/// Frosted-glass pill for secondary actions laid over imagery. The blur is
/// real (BackdropFilter), so use it sparingly — hero CTAs, not list items.
class MallGlassCta extends StatelessWidget {
  const MallGlassCta({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DesignTokens.glassBlurSigma,
          sigmaY: DesignTokens.glassBlurSigma,
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: DesignTokens.textWhite,
            backgroundColor: DesignTokens.glassFill,
            minimumSize: const Size(DesignTokens.minTouchTarget, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: const StadiumBorder(
              side: BorderSide(color: DesignTokens.glassStroke),
            ),
            textStyle: _ctaTextStyle,
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Transparent ink overlay that makes the area beneath it one labelled,
/// tappable semantics node. Place it in a Stack above an ExcludeSemantics
/// visual and below any nested controls (save, follow).
class MallTapOverlay extends StatelessWidget {
  const MallTapOverlay({
    required this.semanticLabel,
    required this.onTap,
    super.key,
    this.borderRadius = BorderRadius.zero,
  });

  final String semanticLabel;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: const Color(0x14FFFFFF),
          highlightColor: const Color(0x0AFFFFFF),
        ),
      ),
    );
  }
}
