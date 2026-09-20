import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/domain/reel_caption/reel_caption.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Renders a reel caption following the StyleMint Reel Caption Standard.
///
/// Standard captions: bold white hook, product lines with the price in brand
/// green, muted CTA, green hashtags. Collapsed, only the hook and the first
/// product line show, followed by a "more" affordance; tapping toggles.
///
/// Non-standard captions (e.g. imported from a platform as-is) render as
/// plain text with hashtags highlighted, collapsed to [collapsedMaxLines]
/// with the same "more" affordance when they overflow.
class ReelCaptionText extends StatefulWidget {
  const ReelCaptionText({
    required this.caption,
    this.expandable = true,
    this.collapsedMaxLines = 3,
    this.maxExpandedHeight,
    this.emptyText,
    super.key,
  });

  static const String moreLabel = 'more';

  static const TextStyle baseStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: DesignTokens.textWhite,
  );
  static const TextStyle hookStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: DesignTokens.textWhite,
  );
  static const TextStyle productStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: DesignTokens.textLight,
  );
  static const TextStyle priceStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: DesignTokens.primaryGreen,
  );
  static const TextStyle mutedStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: DesignTokens.textMuted,
  );
  static const TextStyle hashtagStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: DesignTokens.primaryGreen,
  );
  static const TextStyle moreStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignTokens.textLight,
  );

  final String? caption;

  /// When false the full caption is always shown (e.g. editor preview).
  final bool expandable;

  /// Lines shown for a non-standard caption before "more".
  final int collapsedMaxLines;

  /// Caps the expanded height (the caption scrolls inside) so long imported
  /// captions never push a reel overlay off-screen.
  final double? maxExpandedHeight;

  /// Muted placeholder when the caption is empty; renders nothing when null.
  final String? emptyText;

  static final RegExp _hashtagPattern = RegExp(
    r'#[\p{L}\p{M}\p{N}_]+',
    unicode: true,
  );

  /// The styled span for [parsed]. [collapsed] keeps only the hook and the
  /// first product line of a standard caption.
  static TextSpan buildSpan(
    ParsedReelCaption parsed, {
    bool collapsed = false,
  }) {
    if (!parsed.isStandard) {
      return TextSpan(
        style: baseStyle,
        children: _withHashtags(parsed.raw.trim()),
      );
    }
    final lines = collapsed ? parsed.productLines.take(1) : parsed.productLines;
    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: parsed.hook, style: hookStyle),
        for (final line in lines) ...[
          const TextSpan(text: '\n'),
          TextSpan(text: line.label, style: productStyle),
          const TextSpan(text: ReelCaption.productSeparator, style: mutedStyle),
          TextSpan(text: line.price, style: priceStyle),
        ],
        if (!collapsed && parsed.hasCta) ...[
          const TextSpan(text: '\n'),
          const TextSpan(text: ReelCaptionCopy.cta, style: mutedStyle),
        ],
        if (!collapsed && parsed.hashtags.isNotEmpty) ...[
          const TextSpan(text: '\n\n'),
          ..._withHashtags(parsed.hashtags.map((t) => '#$t').join(' ')),
        ],
      ],
    );
  }

  static List<InlineSpan> _withHashtags(String text) {
    final spans = <InlineSpan>[];
    var index = 0;
    for (final match in _hashtagPattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      spans.add(TextSpan(text: match.group(0), style: hashtagStyle));
      index = match.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return spans;
  }

  @override
  State<ReelCaptionText> createState() => _ReelCaptionTextState();
}

class _ReelCaptionTextState extends State<ReelCaptionText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.caption?.trim() ?? '';
    if (text.isEmpty) {
      final empty = widget.emptyText;
      return empty == null
          ? const SizedBox.shrink()
          : Text(empty, style: ReelCaptionText.mutedStyle);
    }

    final parsed = ReelCaption.parse(text);
    final full = ReelCaptionText.buildSpan(parsed);
    if (!widget.expandable) return Text.rich(full);

    final Widget child;
    if (_expanded) {
      child = _expandedView(full);
    } else if (parsed.isStandard) {
      // A standard caption always has more below the fold (CTA/hashtags).
      child = _withMore(
        ReelCaptionText.buildSpan(parsed, collapsed: true),
        parsed.productLines.isEmpty ? 2 : 3,
      );
    } else {
      child = LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: full,
            maxLines: widget.collapsedMaxLines,
            textDirection: Directionality.of(context),
            textScaler:
                MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
          )..layout(maxWidth: constraints.maxWidth);
          final overflows = painter.didExceedMaxLines;
          painter.dispose();
          return overflows
              ? _withMore(full, widget.collapsedMaxLines)
              : Text.rich(full);
        },
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _expanded = !_expanded),
      child: child,
    );
  }

  Widget _expandedView(TextSpan span) {
    final maxHeight = widget.maxExpandedHeight;
    if (maxHeight == null) return Text.rich(span);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(child: Text.rich(span)),
    );
  }

  Widget _withMore(TextSpan span, int maxLines) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text.rich(
            span,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: DesignTokens.s4),
        const Text(
          ReelCaptionText.moreLabel,
          style: ReelCaptionText.moreStyle,
        ),
      ],
    );
  }
}
