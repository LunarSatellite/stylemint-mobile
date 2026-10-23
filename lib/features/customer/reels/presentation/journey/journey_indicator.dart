import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_journey.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The journey chrome over a journey reel: the journey's title and city,
/// "Step 1 of 3" with a dot per step, and who is next — with a subtle
/// "swipe →" hint the first few times.
///
/// Sits under the top controls (Home's "Mall | Reels" switch, the reel
/// page's back and sound buttons). Only the next-business chip takes taps
/// (it moves to the next step, for anyone who does not swipe); the rest lets
/// touches through to the reel.
class JourneyIndicator extends StatelessWidget {
  const JourneyIndicator({
    required this.journey,
    required this.showHint,
    this.onNext,
    this.onDismissHint,
    super.key,
  });

  static const Key progressKey = Key('journey-indicator-progress');
  static const Key nextKey = Key('journey-indicator-next');
  static const Key hintKey = Key('journey-indicator-hint');

  /// The journey as seen from the step on screen.
  final ReelJourney journey;
  final bool showHint;
  final VoidCallback? onNext;
  final VoidCallback? onDismissHint;

  @override
  Widget build(BuildContext context) {
    final index = journey.stepIndex;
    final count = journey.stepCount < journey.steps.length
        ? journey.steps.length
        : journey.stepCount;
    final next = journey.stepAfter(index);
    final city = journey.city;
    final title = journey.displayTitle;
    final heading = city == null || city.isEmpty || city == title
        ? title
        : '$title · $city';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IgnorePointer(
          child: Semantics(
            label: 'Journey $heading, step ${index + 1} of $count',
            excludeSemantics: true,
            child: _Glass(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        size: 14,
                        color: DesignTokens.textWhite,
                      ),
                      const SizedBox(width: DesignTokens.s6),
                      Flexible(
                        child: Text(
                          heading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Row(
                    key: progressKey,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Step ${index + 1} of $count',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      for (var i = 0; i < journey.steps.length; i++)
                        _Dot(active: i == index),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: DesignTokens.s6),
          _NextChip(
            key: nextKey,
            step: next,
            showHint: showHint,
            onTap: onNext,
            onDismissHint: onDismissHint,
          ),
        ],
      ],
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: DesignTokens.baseBlack.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      border: Border.all(color: DesignTokens.glassStroke),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s6,
      ),
      child: child,
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    margin: const EdgeInsets.symmetric(horizontal: 2),
    width: active ? 14 : 6,
    height: 6,
    decoration: BoxDecoration(
      color: active ? DesignTokens.textWhite : DesignTokens.glassStroke,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

class _NextChip extends StatelessWidget {
  const _NextChip({
    required this.step,
    required this.showHint,
    this.onTap,
    this.onDismissHint,
    super.key,
  });

  final ReelJourneyStep step;
  final bool showHint;
  final VoidCallback? onTap;
  final VoidCallback? onDismissHint;

  @override
  Widget build(BuildContext context) {
    final name = step.vendorName.isEmpty ? 'Next stop' : step.vendorName;
    return Semantics(
      button: true,
      label: 'Next: $name',
      child: Material(
        color: DesignTokens.baseBlack.withValues(alpha: 0.45),
        shape: const StadiumBorder(
          side: BorderSide(color: DesignTokens.glassStroke),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, DesignTokens.s8, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Logo(step: step),
                const SizedBox(width: DesignTokens.s6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    'Next: $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                if (showHint) ...[
                  const SizedBox(width: DesignTokens.s6),
                  Text(
                    'swipe →',
                    key: JourneyIndicator.hintKey,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onDismissHint != null)
                    InkResponse(
                      onTap: onDismissHint,
                      radius: 14,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: DesignTokens.textLight,
                          semanticLabel: 'Hide swipe hint',
                        ),
                      ),
                    ),
                ] else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: DesignTokens.textLight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.step});

  final ReelJourneyStep step;

  @override
  Widget build(BuildContext context) {
    final logo = step.vendorLogoUrl;
    final initial = step.vendorName.isEmpty
        ? '?'
        : step.vendorName.characters.first.toUpperCase();
    return CircleAvatar(
      radius: 11,
      backgroundColor: DesignTokens.bgAppBodyLight,
      foregroundImage: logo == null || logo.isEmpty
          ? null
          : CachedNetworkImageProvider(logo),
      child: Text(
        initial,
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textWhite,
          fontSize: 11,
        ),
      ),
    );
  }
}
