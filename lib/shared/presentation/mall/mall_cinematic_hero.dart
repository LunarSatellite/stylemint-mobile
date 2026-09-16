import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_motion.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_primitives.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_strings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Mall's cinematic zone: a full-bleed campaign stage.
///
/// Three layers move at three speeds — the photograph drifts on its own
/// (`MallKenBurns`), lags the page as you scroll (`MallParallax`), and the
/// copy in front of it scrolls at full speed and fades out. That difference
/// is the depth; there is no blur anywhere in this widget.
///
/// Auto-advances while [autoAdvance] is set and more than one campaign is
/// live, pausing under a finger and stopping entirely under reduced motion.
///
/// [heroTagFor] opts a campaign into a shared-element flight into whatever it
/// advertises. Only the campaign on screen carries the tag, so exactly one
/// hero ever exists in this subtree.
class MallCinematicHero extends StatefulWidget {
  const MallCinematicHero({
    required this.campaigns,
    required this.onAction,
    super.key,
    this.onReel,
    this.autoAdvance = true,
    this.interval = DesignTokens.heroAutoAdvance,
    this.height,
    this.topInset = 0,
    this.overline,
    this.heroTagFor,
  });

  final List<MallCampaignVm> campaigns;
  final void Function(MallCampaignVm campaign, MallCampaignAction action)
  onAction;
  final ValueChanged<MallCampaignVm>? onReel;
  final bool autoAdvance;
  final Duration interval;

  /// Overrides [heightFor].
  final double? height;

  /// Kept clear at the top for the Home "Mall | Reels" switch.
  final double topInset;

  /// A quiet line under the switch — the Mall puts its greeting here.
  final Widget? overline;

  /// Shared-element tag for a campaign's image, or null for no flight.
  final String? Function(MallCampaignVm campaign)? heroTagFor;

  static const double minHeight = 420;
  static const double maxHeight = 720;
  static const int maxActions = 3;

  /// Just under three quarters of the screen: enough that the campaign is the
  /// page, with the next block's edge still showing under it.
  static double heightFor(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * 0.72).clamp(minHeight, maxHeight);

  /// The display face, one step above a section title, stepped down on the
  /// narrowest phones so a three-word title still fits on two lines.
  static TextStyle titleStyleFor(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return DesignTokens.displayHero.copyWith(
      fontSize: narrow ? 34 : 44,
      height: narrow ? 38 / 34 : 48 / 44,
      letterSpacing: -0.6,
    );
  }

  @override
  State<MallCinematicHero> createState() => _MallCinematicHeroState();
}

class _MallCinematicHeroState extends State<MallCinematicHero> {
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
  void didUpdateWidget(MallCinematicHero oldWidget) {
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
    final height = widget.height ?? MallCinematicHero.heightFor(context);
    final index = _index.clamp(0, campaigns.length - 1);
    final current = campaigns[index];
    final switchDuration = _reduceMotion
        ? Duration.zero
        : DesignTokens.motionMedium;
    final label = campaigns.length > 1
        ? '${strings.featured}, ${strings.slideOf(index + 1, campaigns.length)}'
        : strings.featured;
    final overline = widget.overline;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerEnd,
        onPointerCancel: _onPointerEnd,
        child: SizedBox(
          height: height,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MallParallax(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: campaigns.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, i) => ExcludeSemantics(
                      child: _HeroFrame(
                        campaign: campaigns[i],
                        active: i == index,
                        reduceMotion: _reduceMotion,
                        heroTag: i == index
                            ? widget.heroTagFor?.call(campaigns[i])
                            : null,
                      ),
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
                if (overline != null)
                  PositionedDirectional(
                    top: widget.topInset,
                    start: DesignTokens.s20,
                    end: DesignTokens.s20,
                    child: MallScrollFade(
                      distance: height * 0.45,
                      child: overline,
                    ),
                  ),
                PositionedDirectional(
                  start: DesignTokens.s20,
                  end: DesignTokens.s20,
                  bottom: DesignTokens.s24,
                  child: MallScrollFade(
                    distance: height * 0.7,
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
                            onReel: widget.onReel,
                          ),
                        ),
                        if (campaigns.length > 1) ...[
                          const SizedBox(height: DesignTokens.s20),
                          _HeroProgress(
                            count: campaigns.length,
                            index: index,
                            duration: switchDuration,
                          ),
                        ],
                      ],
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

  static Widget _bottomStartLayout(Widget? current, List<Widget> previous) =>
      Stack(
        alignment: AlignmentDirectional.bottomStart,
        children: [...previous, ?current],
      );
}

/// One campaign's photograph: the drifting layer inside the parallax layer.
class _HeroFrame extends StatelessWidget {
  const _HeroFrame({
    required this.campaign,
    required this.active,
    required this.reduceMotion,
    required this.heroTag,
  });

  final MallCampaignVm campaign;
  final bool active;
  final bool reduceMotion;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final tag = heroTag;
    final Widget image = MallNetworkImage(url: campaign.imageUrl);
    // The flight carries the photograph alone — scrims and copy belong to the
    // page each side of the transition, not to the shared element.
    final framed = tag == null
        ? image
        : Hero(
            tag: tag,
            // A hero flying between two full-bleed boxes should stay
            // full-bleed for the whole flight.
            flightShuttleBuilder: (_, _, _, _, _) => image,
            child: image,
          );
    return MallKenBurns(enabled: active && !reduceMotion, child: framed);
  }
}

/// Eyebrow, display title and actions for the campaign on screen.
class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.campaign,
    required this.onAction,
    required this.onReel,
    super.key,
  });

  final MallCampaignVm campaign;
  final void Function(MallCampaignVm campaign, MallCampaignAction action)
  onAction;
  final ValueChanged<MallCampaignVm>? onReel;

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
    final reelId = campaign.reelId?.trim();
    final canWatch = reelId != null && reelId.isNotEmpty && onReel != null;
    final actions = campaign.actions
        .take(MallCinematicHero.maxActions - (canWatch ? 1 : 0))
        .toList();
    final titleStyle = MallCinematicHero.titleStyleFor(context);

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
                _EyebrowRule(text: eyebrow),
                const SizedBox(height: DesignTokens.s12),
              ],
              Semantics(
                header: true,
                child: Text.rich(
                  _titleSpan(campaign.title, titleStyle),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
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
        if (actions.isNotEmpty || canWatch) ...[
          const SizedBox(height: DesignTokens.s20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (canWatch)
                _HeroWatchCta(
                  label: MallStrings.of(context).watchReel,
                  onPressed: () => onReel!(campaign),
                ),
              for (final (i, action) in actions.indexed)
                if (i == 0)
                  MallPrimaryCta(
                    label: action.label,
                    onPressed: () => onAction(campaign, action),
                  )
                else
                  _HeroSecondaryCta(
                    label: action.label,
                    onPressed: () => onAction(campaign, action),
                  ),
            ],
          ),
        ],
      ],
    );
  }

  /// The closing word set in the italic display face — the one editorial
  /// flourish in the zone, applied by the same rule to every campaign.
  static TextSpan _titleSpan(String title, TextStyle style) {
    final trimmed = title.trim();
    final cut = trimmed.lastIndexOf(' ');
    if (cut <= 0) return TextSpan(text: trimmed);
    return TextSpan(
      children: [
        TextSpan(text: '${trimmed.substring(0, cut)} '),
        TextSpan(
          text: trimmed.substring(cut + 1),
          style: style.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

/// The campaign eyebrow with a short rule running off its end — the zone's
/// section marker, in place of an icon.
class _EyebrowRule extends StatelessWidget {
  const _EyebrowRule({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: MallEyebrow(text, color: DesignTokens.textWhite)),
        const SizedBox(width: DesignTokens.s12),
        const SizedBox(
          width: 28,
          child: ColoredBox(
            color: Color(0x66FFFFFF),
            child: SizedBox(height: 1),
          ),
        ),
      ],
    );
  }
}

/// Reel-first hero action: a compact glass pill with a bright play mark.
class _HeroWatchCta extends StatelessWidget {
  const _HeroWatchCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const DecoratedBox(
        decoration: BoxDecoration(
          color: DesignTokens.primaryGreen,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 28,
          child: Icon(
            Icons.play_arrow_rounded,
            size: 20,
            color: DesignTokens.buttonPrimaryText,
          ),
        ),
      ),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: DesignTokens.textWhite,
        backgroundColor: const Color(0x52000000),
        minimumSize: const Size(DesignTokens.minTouchTarget, 48),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 18, 8),
        shape: const StadiumBorder(
          side: BorderSide(color: DesignTokens.glassStroke),
        ),
        textStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

/// Secondary hero action.
///
/// Deliberately not [MallGlassCta]: a real `BackdropFilter` over a full-bleed
/// photograph forces a backdrop save-layer every frame the hero drifts, which
/// the target device cannot spare. A translucent fill over the scrim reads
/// the same and costs nothing.
class _HeroSecondaryCta extends StatelessWidget {
  const _HeroSecondaryCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: DesignTokens.textWhite,
        backgroundColor: const Color(0x33FFFFFF),
        minimumSize: const Size(DesignTokens.minTouchTarget, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(
          side: BorderSide(color: DesignTokens.glassStroke),
        ),
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

/// Segmented position bars. They change only when the slide does, so the
/// hero holds no continuously animating widget besides the drift itself.
class _HeroProgress extends StatelessWidget {
  const _HeroProgress({
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
              width: i == index ? 30 : 14,
              height: 3,
              decoration: BoxDecoration(
                color: i == index
                    ? DesignTokens.primaryGreen
                    : const Color(0x59FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
