import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Mall's bold-retail zone: a colour-blocked plate that interrupts the
/// dark page, with the block's products running underneath it.
///
/// Everything on the plate is a fact the server sent — [topDiscountPercent]
/// is the best real discount in the block and [endsUtc] a real sale deadline.
/// Leave either null and that part simply is not drawn; nothing here is
/// filled in with a plausible-looking number.
class MallDealBand extends StatelessWidget {
  const MallDealBand({
    required this.title,
    required this.child,
    super.key,
    this.eyebrow,
    this.subtitle,
    this.topDiscountPercent,
    this.endsUtc,
    this.ctaLabel,
    this.onCta,
    this.now,
  });

  /// Section title, set in the display face against the block colour.
  final String title;

  /// The block's products, drawn on the page ground below the plate.
  final Widget child;
  final String? eyebrow;
  final String? subtitle;

  /// Largest real discount across the block, floored. Null draws no numeral.
  final int? topDiscountPercent;

  /// Soonest real sale deadline in the block. Null draws no countdown.
  final DateTime? endsUtc;
  final String? ctaLabel;
  final VoidCallback? onCta;

  /// Clock behind the countdown; tests pin it.
  final DateTime Function()? now;

  /// Depth of the angled cut at the plate's trailing bottom corner.
  static const double cut = 40;

  static const Color _ink = DesignTokens.textWhite;
  static const Color _inkMuted = DesignTokens.textLight;

  static const TextStyle _numeralStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -2,
    color: _ink,
    fontFeatures: mallTabularFigures,
  );

  static const TextStyle _subtitleStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: _inkMuted,
  );

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final direction = Directionality.of(context);
    final discount = topDiscountPercent;
    final deadline = endsUtc;
    final label = ctaLabel;
    final action = onCta;
    final subtitleText = subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipPath(
          clipper: _CutCornerClipper(cut: cut, direction: direction),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  Color(0xFF252A27),
                  DesignTokens.bgAppBody,
                ],
              ),
              boxShadow: DesignTokens.shadowLifted,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MallEyebrow(
                    eyebrow ?? strings.limitedTime,
                    color: DesignTokens.primaryGreen,
                  ),
                  const SizedBox(height: DesignTokens.s12),
                  if (discount != null) ...[
                    _Numeral(percent: discount, strings: strings),
                    const SizedBox(height: 10),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.displaySection.copyWith(
                        fontSize: 32,
                        height: 35 / 32,
                        color: _ink,
                      ),
                    ),
                  ),
                  if (subtitleText != null) ...[
                    const SizedBox(height: DesignTokens.s6),
                    Text(
                      subtitleText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _subtitleStyle,
                    ),
                  ],
                  if (deadline != null) ...[
                    const SizedBox(height: DesignTokens.s16),
                    MallCountdown(
                      endsUtc: deadline,
                      now: now,
                      builder: (context, remaining) => remaining == null
                          ? const SizedBox.shrink()
                          : _CountdownChip(
                              remaining: remaining,
                              strings: strings,
                            ),
                    ),
                  ],
                  if (label != null && action != null) ...[
                    const SizedBox(height: DesignTokens.s16),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _DropCta(label: label, onPressed: action),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        child,
      ],
    );
  }
}

/// The discount numeral, treated as a compact campaign stamp rather than a
/// loose number on the green field.
class _Numeral extends StatelessWidget {
  const _Numeral({required this.percent, required this.strings});

  final int percent;
  final MallStrings strings;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: strings.upToPercentOff(percent),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 190),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DesignTokens.primaryGreenLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x5532D477)),
              boxShadow: DesignTokens.shadowCard,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 16, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    maxLines: 1,
                    style: MallDealBand._numeralStyle.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  const Padding(
                    padding: EdgeInsetsDirectional.only(bottom: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'UP TO',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            letterSpacing: 1.2,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
                        Text(
                          'OFF',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            letterSpacing: 1.2,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Live countdown chip: the one place the urgency tone is allowed.
class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.remaining, required this.strings});

  final MallRemaining remaining;
  final MallStrings strings;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Its own node: without this the chip merges into the plate's copy and
      // the deadline stops being announced as a thing in its own right.
      container: true,
      liveRegion: true,
      label: strings.endsIn(remaining.spoken),
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DesignTokens.buttonPrimaryText,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: DesignTokens.secondaryYellow,
                ),
                const SizedBox(width: DesignTokens.s6),
                Flexible(
                  child: Text(
                    strings.endsIn(remaining.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: DesignTokens.secondaryYellow,
                      fontFeatures: mallTabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The plate's action: the primary pill inverted against the block colour.
class _DropCta extends StatelessWidget {
  const _DropCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: DesignTokens.buttonPrimaryText,
        minimumSize: const Size(DesignTokens.minTouchTarget, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

/// Slices the trailing bottom corner off the plate, so the block reads as a
/// cut sheet of colour rather than another rounded card.
class _CutCornerClipper extends CustomClipper<Path> {
  const _CutCornerClipper({required this.cut, required this.direction});

  final double cut;
  final TextDirection direction;

  @override
  Path getClip(Size size) {
    final depth = cut.clamp(0.0, size.height);
    final path = Path();
    if (direction == TextDirection.rtl) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(depth, size.height)
        ..lineTo(0, size.height - depth);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, size.height - depth)
        ..lineTo(size.width - depth, size.height)
        ..lineTo(0, size.height);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_CutCornerClipper oldClipper) =>
      oldClipper.cut != cut || oldClipper.direction != direction;
}
