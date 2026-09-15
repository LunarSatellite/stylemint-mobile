import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/home_mode.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Height of Home's top bar below the status bar: the switch plus its
/// breathing room. Mall content starts below it.
const double homeTopBarExtent = 60;

/// Where Home content starts: status bar plus [homeTopBarExtent].
double homeTopInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top + homeTopBarExtent;

/// Compact "Mall | Reels" segmented switch. Translucent so it reads over the
/// Mall and over full-screen video alike; each segment is a 44dp target.
class HomeModeSwitch extends StatelessWidget {
  const HomeModeSwitch({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final HomeMode mode;
  final ValueChanged<HomeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final duration = MallMetrics.reduceMotion(context)
        ? Duration.zero
        : DesignTokens.motionMedium;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6101012),
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        border: Border.all(color: DesignTokens.glassStroke, width: 0.5),
        boxShadow: DesignTokens.shadowCard,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in HomeMode.values)
            _Segment(
              label: switch (value) {
                HomeMode.mall => 'Mall',
                HomeMode.reels => 'Reels',
              },
              selected: value == mode,
              duration: duration,
              onTap: () => onChanged(value),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedContainer(
            duration: duration,
            curve: DesignTokens.motionCurve,
            constraints: const BoxConstraints(minWidth: 76, minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? DesignTokens.textWhite
                  : const Color(0x00FFFFFF),
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: 0.1,
                color: selected
                    ? DesignTokens.textDark
                    : DesignTokens.textLight,
              ),
              child: Text(label, maxLines: 1),
            ),
          ),
        ),
      ),
    );
  }
}
