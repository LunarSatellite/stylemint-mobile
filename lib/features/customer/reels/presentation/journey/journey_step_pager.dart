import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_journey.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/journey/journey_indicator.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/journey/journey_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One feed page that is a journey: the businesses' reels side by side.
///
/// Swipe right-to-left for the NEXT step's reel, left-to-right for the
/// previous one — the next business sits to the right, like every carousel,
/// and the "Next: … →" chip points there. Up and down still move the feed:
/// this pager only claims horizontal drags, and the vertical feed wins any
/// drag that leaves its slop vertically, exactly as it does today against
/// Home's tab pager.
///
/// Each step is an ordinary [ReelCard] — its tags add to the cart exactly as
/// on any reel. The feed's reel is the step this page opens on; the others
/// come from the journey (`GET /v1/journeys/{id}`, once) or, failing that,
/// each reel by id.
///
/// The feed needs to know which reel is on screen (the embedded players, the
/// watch time), so [onStepSettled] reports the step's reel once a swipe has
/// come to rest, and [onShift] how far the step on screen has been dragged
/// sideways, for the embedded player to follow.
class JourneyStepPager extends ConsumerStatefulWidget {
  const JourneyStepPager({
    required this.reel,
    required this.isActive,
    this.initialStep,
    this.onStepSettled,
    this.onShift,
    super.key,
  });

  static const Key pagerKey = Key('journey-step-pager');

  /// The feed's reel; its [Reel.journey] is non-null and swipeable.
  final Reel reel;
  final bool isActive;

  /// The step to open on, when the feed already moved this page to another
  /// step (the page was rebuilt); otherwise the feed reel's own step.
  final int? initialStep;
  final ValueChanged<Reel>? onStepSettled;
  final ValueChanged<double>? onShift;

  @override
  ConsumerState<JourneyStepPager> createState() => _JourneyStepPagerState();
}

class _JourneyStepPagerState extends ConsumerState<JourneyStepPager> {
  late final ReelJourney _journey = widget.reel.journey!;
  late final int _origin = _journey.stepIndex;
  late int _current = _clamp(widget.initialStep ?? _origin);
  late int _settled = _current;
  late final PageController _pages = PageController(initialPage: _current);

  /// The reel last reported through [JourneyStepPager.onStepSettled].
  late String _reportedReelId = widget.reel.id;

  /// Whether this page shows the swipe hint — decided once, as the page
  /// first becomes the one being watched, so the hint never vanishes
  /// mid-view because a count somewhere else moved on.
  bool? _hint;

  int _clamp(int step) => step.clamp(0, _journey.steps.length - 1);

  @override
  void initState() {
    super.initState();
    _pages.addListener(_reportShift);
  }

  @override
  void dispose() {
    _pages
      ..removeListener(_reportShift)
      ..dispose();
    super.dispose();
  }

  void _reportShift() {
    final onShift = widget.onShift;
    if (onShift == null || !widget.isActive || !_pages.hasClients) return;
    final position = _pages.position;
    if (!position.haveDimensions) return;
    final page = _pages.page ?? _settled.toDouble();
    onShift((_settled - page) * position.viewportDimension);
  }

  bool _onScrollEnd(ScrollEndNotification notification) {
    // Only this pager; a reel's product strip scrolls sideways too.
    if (notification.depth != 0 || !_pages.hasClients) return false;
    final page = _pages.page?.round();
    if (page != null && page != _settled) {
      setState(() => _settled = page);
      // Swiping between steps is the lesson the hint teaches.
      ref.read(journeyHintProvider.notifier).dismiss();
    }
    return false;
  }

  JourneyStepKey _keyAt(int step) =>
      (journeyId: _journey.journeyId, reelId: _journey.steps[step].reelId);

  /// The reel for [step], or null while it loads (or when it cannot).
  AsyncValue<Reel?> _reelAt(int step) {
    if (step == _origin) return AsyncData<Reel?>(widget.reel);
    return ref.watch(journeyStepReelProvider(_keyAt(step)));
  }

  void _maybeReportSettled(AsyncValue<Reel?> settled) {
    final reel = settled.value;
    if (reel == null || reel.id == _reportedReelId) return;
    _reportedReelId = reel.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onStepSettled?.call(reel);
    });
  }

  void _takeHintSnapshot() {
    if (_hint != null || !widget.isActive) return;
    final hint = ref.read(journeyHintProvider);
    if (!hint.loaded) return;
    _hint = hint.showsHint;
    if (_hint!) {
      final reelId = widget.reel.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(journeyHintProvider.notifier).recordShown(reelId);
        }
      });
    }
  }

  void _goNext() {
    if (!_pages.hasClients || _current + 1 >= _journey.steps.length) return;
    unawaited(
      _pages.animateToPage(
        _current + 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hint = ref.watch(journeyHintProvider);
    _takeHintSnapshot();
    _maybeReportSettled(_reelAt(_settled));
    final showHint = (_hint ?? false) && !hint.dismissed;
    final topInset = MediaQuery.paddingOf(context).top;

    return NotificationListener<ScrollEndNotification>(
      onNotification: _onScrollEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            key: JourneyStepPager.pagerKey,
            controller: _pages,
            // The same reason as the feed's own PageView: this horizontal
            // pager sits inside a vertical one (and, on Home, the tab pager),
            // so it tracks the drag from touch-down.
            dragStartBehavior: DragStartBehavior.down,
            allowImplicitScrolling: true,
            itemCount: _journey.steps.length,
            onPageChanged: (step) => setState(() => _current = step),
            itemBuilder: (context, step) => _StepPage(
              step: _journey.steps[step],
              reel: _reelAt(step),
              isActive: widget.isActive && step == _current,
            ),
          ),
          Positioned(
            top: topInset + 68,
            left: DesignTokens.s16,
            right: DesignTokens.s16,
            child: Center(
              child: JourneyIndicator(
                journey: _journey.atStep(_current),
                showHint: showHint,
                onNext: _goNext,
                onDismissHint: () =>
                    ref.read(journeyHintProvider.notifier).dismiss(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One step: its reel, a poster while the reel loads, or a short note when
/// it cannot be loaded.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.step,
    required this.reel,
    required this.isActive,
  });

  final ReelJourneyStep step;
  final AsyncValue<Reel?> reel;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final loaded = reel.value;
    if (loaded != null) return ReelCard(reel: loaded, isActive: isActive);
    final loading = reel.isLoading;
    final thumb = step.thumbnailUrl;
    return ColoredBox(
      color: DesignTokens.baseBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumb != null && thumb.isNotEmpty)
            Image.network(
              thumb,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: DesignTokens.textWhite,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(DesignTokens.s24),
                    child: Text(
                      step.vendorName.isEmpty
                          ? 'This stop is not available right now.'
                          : "${step.vendorName}'s reel is not available "
                                'right now.',
                      textAlign: TextAlign.center,
                      style: DesignTokens.bodyText.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
