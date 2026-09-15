import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Cover photo with top and bottom scrims; a tonal placeholder without one.
class StorefrontCover extends StatelessWidget {
  const StorefrontCover({
    required this.imageUrl,
    required this.height,
    super.key,
  });

  final String? imageUrl;
  final double height;

  /// Cover height for the screen width: [ratio] of the width clamped to
  /// [min]..[max], plus the top bar it runs under.
  static double extentFor(
    BuildContext context, {
    required double ratio,
    required double min,
    required double max,
    required double topBarExtent,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    return topBarExtent + (width * ratio).clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: DesignTokens.surfaceRaised),
            if (url != null)
              MallNetworkImage(url: url)
            else
              const MallImagePlaceholder(),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: DesignTokens.imageScrimTop),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.55,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: DesignTokens.imageScrim),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A name in the display face with the verified tick after its last word.
class StorefrontDisplayName extends StatelessWidget {
  const StorefrontDisplayName({
    required this.name,
    required this.isVerified,
    super.key,
    this.style = DesignTokens.displayTitle,
  });

  final String name;
  final bool isVerified;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    return Semantics(
      header: true,
      label: isVerified ? '$name, ${strings.verified}' : name,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: name,
          children: [
            if (isVerified)
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: 8),
                  child: MallVerifiedBadge(size: 20),
                ),
              ),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

/// One figure in a stats row, e.g. "12.4K" over "Followers".
@immutable
class StorefrontStat {
  const StorefrontStat({required this.value, required this.label});

  final String value;
  final String label;
}

class StorefrontStatsRow extends StatelessWidget {
  const StorefrontStatsRow({required this.stats, super.key});

  final List<StorefrontStat> stats;

  static const TextStyle _valueStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: DesignTokens.textWhite,
  );

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: DesignTokens.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignTokens.s28,
      runSpacing: DesignTokens.s12,
      children: [
        for (final stat in stats)
          Semantics(
            label: '${stat.value} ${stat.label}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stat.value, style: _valueStyle),
                Text(stat.label, style: _labelStyle),
              ],
            ),
          ),
      ],
    );
  }
}

/// A quiet pill for a style tag.
class StorefrontTagChip extends StatelessWidget {
  const StorefrontTagChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.3,
          color: DesignTokens.textLight,
        ),
      ),
    );
  }
}

/// Text clamped to [maxLines] with a "Read more" / "Show less" toggle when it
/// doesn't fit.
class StorefrontExpandableText extends StatefulWidget {
  const StorefrontExpandableText({
    required this.text,
    super.key,
    this.maxLines = 3,
    this.style = _defaultStyle,
  });

  final String text;
  final int maxLines;
  final TextStyle style;

  static const TextStyle _defaultStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: DesignTokens.textLight,
  );

  @override
  State<StorefrontExpandableText> createState() =>
      _StorefrontExpandableTextState();
}

class _StorefrontExpandableTextState extends State<StorefrontExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return AnimatedSize(
          duration: MallMetrics.reduceMotion(context)
              ? Duration.zero
              : DesignTokens.motionMedium,
          curve: DesignTokens.motionCurve,
          alignment: AlignmentDirectional.topStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                maxLines: _expanded ? null : widget.maxLines,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: widget.style,
              ),
              if (overflows)
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.textWhite,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(
                      DesignTokens.minTouchTarget,
                      DesignTokens.minTouchTarget,
                    ),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    alignment: AlignmentDirectional.centerStart,
                  ),
                  child: Text(
                    _expanded ? 'Show less' : 'Read more',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A 44dp round icon button on the page (share, social links).
class StorefrontRoundButton extends StatelessWidget {
  const StorefrontRoundButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: DesignTokens.surfaceRaised,
        fixedSize: const Size.square(DesignTokens.minTouchTarget),
        minimumSize: const Size.square(DesignTokens.minTouchTarget),
        padding: EdgeInsets.zero,
      ),
      icon: child,
    );
  }
}

/// Where the avatar or logo row sits over the cover bottom.
double storefrontOverlapTop(double coverExtent, double markSize) =>
    math.max(0, coverExtent - markSize / 2);
