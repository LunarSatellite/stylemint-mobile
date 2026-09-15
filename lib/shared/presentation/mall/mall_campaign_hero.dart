import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Full-width campaign carousel: swipeable imagery under a scrim, with the
/// current campaign's eyebrow, display title, subtitle and up to three CTAs
/// (first filled, the rest glass) plus a page indicator.
///
/// Auto-advances every [interval] while more than one campaign is shown. It
/// pauses while any pointer is down and is off entirely when
/// `MediaQuery.disableAnimations` is set.
///
/// Height is about 62% of the screen, clamped to [minHeight]..[maxHeight];
/// it grows beyond that only if very large text needs the room.
class MallCampaignHero extends StatefulWidget {
  const MallCampaignHero({
    required this.campaigns,
    required this.onAction,
    super.key,
    this.autoAdvance = true,
    this.interval = DesignTokens.heroAutoAdvance,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  final List<MallCampaignVm> campaigns;
  final void Function(MallCampaignVm campaign, MallCampaignAction action)
  onAction;
  final bool autoAdvance;
  final Duration interval;

  /// Overrides [heightFor].
  final double? height;
  final BorderRadius borderRadius;

  static const double minHeight = 360;
  static const double maxHeight = 640;
  static const int maxActions = 3;

  static double heightFor(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * 0.62).clamp(minHeight, maxHeight);

  @override
  State<MallCampaignHero> createState() => _MallCampaignHeroState();
}

class _MallCampaignHeroState extends State<MallCampaignHero> {
  final PageController _pages = PageController();
  Timer? _timer;
  int _index = 0;
  int _pointersDown = 0;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MallMetrics.reduceMotion(context);
    _syncTimer();
  }

  @override
  void didUpdateWidget(MallCampaignHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.campaigns.length) _index = 0;
    if (oldWidget.interval != widget.interval) _stopTimer();
    _syncTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    _pages.dispose();
    super.dispose();
  }

  bool get _shouldAutoAdvance =>
      widget.autoAdvance &&
      widget.campaigns.length > 1 &&
      _pointersDown == 0 &&
      !_reduceMotion;

  void _syncTimer() {
    if (!_shouldAutoAdvance) {
      _stopTimer();
      return;
    }
    _timer ??= Timer.periodic(widget.interval, (_) => _advance());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _advance() {
    final count = widget.campaigns.length;
    if (!mounted || !_pages.hasClients || count < 2) return;
    unawaited(
      _pages.animateToPage(
        (_index + 1) % count,
        duration: DesignTokens.motionSlow,
        curve: DesignTokens.motionCurve,
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointersDown++;
    _stopTimer();
  }

  void _onPointerEnd(PointerEvent event) {
    if (_pointersDown > 0) _pointersDown--;
    _syncTimer();
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    // A manual swipe earns a full interval before the next advance.
    _stopTimer();
    _syncTimer();
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = widget.campaigns;
    if (campaigns.isEmpty) return const SizedBox.shrink();
    final strings = MallStrings.of(context);
    final index = _index.clamp(0, campaigns.length - 1);
    final current = campaigns[index];
    final switchDuration = _reduceMotion
        ? Duration.zero
        : DesignTokens.motionMedium;
    final label = campaigns.length > 1
        ? '${strings.featured}, ${strings.slideOf(index + 1, campaigns.length)}'
        : strings.featured;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerEnd,
        onPointerCancel: _onPointerEnd,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.height ?? MallCampaignHero.heightFor(context),
            ),
            child: Stack(
              alignment: AlignmentDirectional.bottomStart,
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: campaigns.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, i) => ExcludeSemantics(
                      child: MallNetworkImage(url: campaigns[i].imageUrl),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DesignTokens.imageScrimTop,
                      ),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DesignTokens.imageScrim,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 96, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: switchDuration,
                        layoutBuilder: _bottomStartLayout,
                        child: _HeroCopy(
                          key: ValueKey(current.id),
                          campaign: current,
                          onAction: widget.onAction,
                        ),
                      ),
                      if (campaigns.length > 1) ...[
                        const SizedBox(height: DesignTokens.s20),
                        _PageIndicator(
                          count: campaigns.length,
                          index: index,
                          duration: switchDuration,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _bottomStartLayout(Widget? current, List<Widget> previous) =>
      Stack(
        alignment: AlignmentDirectional.bottomStart,
        children: [...previous, ?current],
      );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.campaign,
    required this.onAction,
    super.key,
  });

  final MallCampaignVm campaign;
  final void Function(MallCampaignVm campaign, MallCampaignAction action)
  onAction;

  static const TextStyle _subtitleStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: DesignTokens.textLight,
  );

  @override
  Widget build(BuildContext context) {
    final eyebrow = campaign.eyebrow;
    final subtitle = campaign.subtitle;
    final actions = campaign.actions.take(MallCampaignHero.maxActions).toList();
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final titleStyle = narrow
        ? DesignTokens.displayHero.copyWith(fontSize: 34, height: 38 / 34)
        : DesignTokens.displayHero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Copy lets swipes fall through to the imagery underneath.
        IgnorePointer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null) ...[
                MallEyebrow(
                  eyebrow,
                  color: DesignTokens.textLight,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
              ],
              Semantics(
                header: true,
                child: Text(
                  campaign.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _subtitleStyle,
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (i, action) in actions.indexed)
                if (i == 0)
                  MallPrimaryCta(
                    label: action.label,
                    onPressed: () => onAction(campaign, action),
                  )
                else
                  MallGlassCta(
                    label: action.label,
                    onPressed: () => onAction(campaign, action),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.index,
    required this.duration,
  });

  final int count;
  final int index;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: DesignTokens.s6,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: duration,
              curve: DesignTokens.motionCurve,
              width: i == index ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index
                    ? DesignTokens.primaryGreen
                    : const Color(0x73FFFFFF),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
