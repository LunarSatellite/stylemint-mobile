import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Editorial section header: optional eyebrow, a display-face title, an
/// optional subtitle and an optional "See all" action with a 44dp target.
///
/// On the Mall page it also carries the block's [index] — a numeral and a
/// hairline that mark where one zone ends and the next begins, in place of
/// the decorative icons a section marker usually reaches for — and [meta],
/// the live signals for the block below it.
class MallSectionHeader extends StatelessWidget {
  const MallSectionHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.subtitle,
    this.onSeeAll,
    this.seeAllLabel,
    this.padding,
    this.index,
    this.meta = const [],
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  /// 1-based position of this block on the page, drawn as "01". Null leaves
  /// the marker off entirely.
  final int? index;

  /// Facts about the block below, each built from data the API sent.
  final List<MallSignal> meta;

  /// Overrides [MallStrings.seeAll].
  final String? seeAllLabel;

  /// Defaults to 16dp page gutters and 12dp below. The end gutter tightens
  /// when there is an action, whose own padding supplies the visual gutter.
  final EdgeInsetsGeometry? padding;

  static const TextStyle _subtitleStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: DesignTokens.textMuted,
  );

  static const TextStyle _indexStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1,
    color: DesignTokens.sectionOnBase,
    fontFeatures: mallTabularFigures,
  );

  @override
  Widget build(BuildContext context) {
    final eyebrowText = eyebrow;
    final subtitleText = subtitle;
    final action = onSeeAll;
    final marker = index;
    return Padding(
      padding:
          padding ??
          EdgeInsetsDirectional.fromSTEB(
            DesignTokens.s16,
            0,
            action == null ? DesignTokens.s16 : DesignTokens.s4,
            DesignTokens.s12,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (marker != null) ...[
            ExcludeSemantics(
              child: Row(
                children: [
                  Text(
                    marker.toString().padLeft(2, '0'),
                    style: _indexStyle,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  const Expanded(
                    child: ColoredBox(
                      color: DesignTokens.bgAppBodyLight,
                      child: SizedBox(height: 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
          ],
          _TitleRow(
            title: title,
            eyebrow: eyebrowText,
            subtitle: subtitleText,
            action: action,
            seeAllLabel: seeAllLabel,
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: DesignTokens.s6,
              runSpacing: DesignTokens.s6,
              children: [
                for (final signal in meta) MallSignalChip(signal: signal),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The header's title block and its action, kept as one row so the action
/// stays bottom-aligned to the title however tall the copy grows.
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.action,
    required this.seeAllLabel,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final VoidCallback? action;
  final String? seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final eyebrowText = eyebrow;
    final subtitleText = subtitle;
    final onSeeAll = action;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrowText != null) ...[
                MallEyebrow(eyebrowText, maxLines: 2),
                const SizedBox(height: DesignTokens.s6),
              ],
              Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.displaySection,
                ),
              ),
              if (subtitleText != null) ...[
                const SizedBox(height: DesignTokens.s4),
                Text(
                  subtitleText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MallSectionHeader._subtitleStyle,
                ),
              ],
            ],
          ),
        ),
        if (onSeeAll != null) ...[
          const SizedBox(width: DesignTokens.s8),
          _SeeAllButton(
            label: seeAllLabel ?? MallStrings.of(context).seeAll,
            sectionTitle: title,
            onPressed: onSeeAll,
          ),
        ],
      ],
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({
    required this.label,
    required this.sectionTitle,
    required this.onPressed,
  });

  final String label;
  final String sectionTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: '$label, $sectionTitle',
      excludeSemantics: true,
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: DesignTokens.textLight,
            minimumSize: const Size.square(DesignTokens.minTouchTarget),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: DesignTokens.s4),
              Icon(
                Icons.arrow_forward_rounded,
                size: MallMetrics.scalerOf(context).scale(16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
