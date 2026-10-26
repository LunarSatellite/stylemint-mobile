import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/feed_provenance_badge.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/creator_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_more_button.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_pinch_recognizer.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/tagged_products_section.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_layout_policy.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_scope.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/reel_shapes.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_fullscreen.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_sound_button.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_resolver.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Where the player sits on a feed page of size [page]. A vertical reel fills
/// the whole page with no bars: its player takes the reel's shape and covers
/// the page, which clips the overflow. A square or landscape video shows
/// whole, the way it was made: its player fills the page and the platform fits
/// the picture inside. Reels are vertical (9:16) unless [ReelShapes] learns a
/// YouTube video's real shape. A native video fills the page and follows the
/// same rule itself. The feed places its shared players with the same
/// rectangle. [topInset] is the status bar's height: a TikTok player starts
/// below it (see [EmbedLayoutPolicy.keepsClearOfStatusBar]).
///
/// With [fitWhole] (a reel watched full screen) every video shows whole: the
/// player fills the page and the platform letterboxes the picture inside it.
Rect reelPlayerRect(
  Reel reel,
  Size page, {
  double topInset = 0,
  bool fitWhole = false,
}) {
  final source = resolveReelPlayback(reel);
  if (source is! EmbedSource) return Offset.zero & page;
  final clearsStatusBar =
      topInset > 0 && EmbedLayoutPolicy.keepsClearOfStatusBar(source.platform);
  if (fitWhole) {
    return Rect.fromLTRB(
      0,
      clearsStatusBar ? topInset.clamp(0.0, page.height) : 0,
      page.width,
      page.height,
    );
  }
  final aspect =
      ReelShapes.instance.aspectOf(reel) ?? EmbedLayoutPolicy.shortsAspectRatio;
  if (clearsStatusBar) {
    return EmbedLayoutPolicy.fillsScreen(aspect)
        ? EmbedLayoutPolicy.coverRectBelow(
            page: page,
            aspectRatio: aspect,
            topInset: topInset,
          )
        : Rect.fromLTRB(
            0,
            topInset.clamp(0.0, page.height),
            page.width,
            page.height,
          );
  }
  return EmbedLayoutPolicy.fillsScreen(aspect)
      ? EmbedLayoutPolicy.coverRect(page: page, aspectRatio: aspect)
      : Offset.zero & page;
}

/// A single full-screen reel: inline video background with a gradient
/// scrim, creator info + caption, right-rail actions and tagged products.
///
/// [isActive] must be true for the reel currently visible in the viewport
/// so that [ReelPlayer] auto-plays it and pauses all others.
///
/// The reel can also be watched full screen — the video and nothing else —
/// from the small button under the right rail or by spreading two fingers on
/// the video (see [reelFullscreenProvider]). A close button in the corner, a
/// pinch, or the system back gesture brings the reel's overlay back, on the
/// same reel, still playing.
class ReelCard extends ConsumerStatefulWidget {
  const ReelCard({required this.reel, required this.isActive, super.key});

  /// How far the right rail is anchored above the bottom of the card.
  static const double railBottom = 180;

  /// The chip naming the reel-page rail a reel came from.
  static const Key railLabelKey = Key('reel-card-rail-label');

  /// The small button under the right rail that takes the reel full screen.
  static const Key enterFullscreenKey = Key('reel-card-enter-fullscreen');

  /// The close button shown while the reel is full screen.
  static const Key exitFullscreenKey = Key('reel-card-exit-fullscreen');

  /// Sound on/off beside [exitFullscreenKey] while the reel is full screen.
  static const Key fullscreenSoundKey = Key('reel-card-fullscreen-sound');

  /// Spoken label of [enterFullscreenKey]'s button.
  static const String enterFullscreenLabel = 'Watch full screen';

  /// Spoken label of [exitFullscreenKey]'s button.
  static const String exitFullscreenLabel = 'Exit full screen';

  /// How far two fingers must spread (as a scale) to go full screen. Closing
  /// them by the same proportion leaves it.
  static const double pinchThreshold = 1.15;

  final Reel reel;
  final bool isActive;

  @override
  ConsumerState<ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends ConsumerState<ReelCard> {
  final _playback = ReelPlaybackController();

  /// Held rather than looked up: a reel that goes away while it owns full
  /// screen hands it back from dispose, where a provider cannot be read.
  late final ReelFullscreenNotifier _fullscreen;

  /// One full-screen change per pinch: spreading on past the threshold after
  /// going full screen must not count again, nor flip straight back out.
  bool _pinchHandled = false;

  // Keys keep the player and the gesture layer the same elements while the
  // overlay around them comes and goes, so full screen never rebuilds the
  // player (which would reload the video) or drops a pinch in progress.
  static const _playerKey = ValueKey<String>('reel-card-player');
  static const _gesturesKey = ValueKey<String>('reel-card-gestures');

  bool get _ownsFullscreen => _fullscreen.isOwnedBy(this);

  @override
  void initState() {
    super.initState();
    _fullscreen = ref.read(reelFullscreenProvider.notifier);
    unawaited(ReelShapes.instance.learnReel(widget.reel));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Another tab, or a page pushed over this one (a notification opened,
    // say): the reel is no longer on screen, and full screen ends with it so
    // the bottom bar and status bar are back wherever the viewer went.
    if (!TickerMode.valuesOf(context).enabled) _handBackFullscreen();
  }

  @override
  void didUpdateWidget(ReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.reel, widget.reel)) {
      unawaited(ReelShapes.instance.learnReel(widget.reel));
    }
    if (!widget.isActive) _handBackFullscreen();
  }

  @override
  void dispose() {
    _handBackFullscreen();
    super.dispose();
  }

  /// Ends full screen if this reel owns it — after the current frame, since
  /// this runs while the tree is being built or torn down, when providers
  /// may not change.
  void _handBackFullscreen() {
    if (!_ownsFullscreen) return;
    final notifier = _fullscreen;
    scheduleMicrotask(() => notifier.exit(this));
  }

  void _enterFullscreen() {
    if (_ownsFullscreen) return;
    // A landscape video may turn the phone sideways while full screen; a
    // vertical one (or one whose shape is not known yet) stays portrait.
    final aspect =
        _playback.videoAspectRatio ?? ReelShapes.instance.aspectOf(widget.reel);
    _fullscreen.enter(this, allowLandscape: aspect != null && aspect > 1);
  }

  void _exitFullscreen() => _fullscreen.exit(this);

  void _onPinchUpdate(double scale) {
    if (_pinchHandled) return;
    final fullscreen = ref.read(reelFullscreenProvider);
    if (!fullscreen && scale >= ReelCard.pinchThreshold) {
      _pinchHandled = true;
      _enterFullscreen();
    } else if (_ownsFullscreen && scale <= 1 / ReelCard.pinchThreshold) {
      _pinchHandled = true;
      _exitFullscreen();
    }
  }

  void _onPinchEnd() => _pinchHandled = false;

  @override
  Widget build(BuildContext context) {
    final fullscreen = ref.watch(reelFullscreenProvider);
    final source = resolveReelPlayback(widget.reel);
    final embed = source is EmbedSource ? EmbedRequest(source) : null;
    final topInset = MediaQuery.paddingOf(context).top;
    return PopScope<Object?>(
      // While this reel is full screen, back (the Android button or gesture,
      // or the iOS edge swipe on a pushed reel page) only leaves full screen.
      canPop: !(fullscreen && _ownsFullscreen),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitFullscreen();
      },
      child: ListenableBuilder(
        listenable: ReelShapes.instance,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final player = reelPlayerRect(
              widget.reel,
              constraints.biggest,
              topInset: topInset,
              fitWhole: fullscreen,
            );
            return Stack(
              fit: StackFit.expand,
              // The player can be larger than the page; the page clips it.
              clipBehavior: Clip.hardEdge,
              children: [
                // Behind the status bar, above a player that starts below it:
                // plain black, beside the player rather than over it. Nothing
                // opaque goes over the rest of the page, even full screen: an
                // embedded reel's player sits beneath the page and shows
                // through it (its own page and a native player's are black).
                if (player.top > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    height: player.top,
                    child: const ColoredBox(color: DesignTokens.baseBlack),
                  ),
                Positioned.fromRect(
                  key: _playerKey,
                  rect: player,
                  child: ReelPlayer(
                    reel: widget.reel,
                    isActive: widget.isActive,
                    playbackController: _playback,
                    // The full-screen play/pause tap target below is layered
                    // over the player, so a control drawn inside it would
                    // never receive a tap. This card draws its own, above
                    // that target.
                    showSoundControl: false,
                    fitWhole: fullscreen,
                  ),
                ),

                // Full-screen tap target for play/pause, and the two-finger
                // pinch in and out of full screen. Sits above the video but
                // below the interactive controls, so a tap anywhere toggles
                // playback while the buttons below still receive their own
                // taps. The pinch recognizer never claims a single finger, so
                // the feed's swipes are untouched (see
                // ReelPinchGestureRecognizer).
                Positioned.fill(
                  key: _gesturesKey,
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: <Type, GestureRecognizerFactory>{
                      TapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            TapGestureRecognizer
                          >(
                            () => TapGestureRecognizer(debugOwner: this),
                            (recognizer) => recognizer.onTap = _playback.toggle,
                          ),
                      ReelPinchGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            ReelPinchGestureRecognizer
                          >(
                            () => ReelPinchGestureRecognizer(debugOwner: this),
                            (recognizer) => recognizer
                              ..onUpdate = _onPinchUpdate
                              ..onEnd = _onPinchEnd,
                          ),
                    },
                  ),
                ),

                if (fullscreen)
                  // Only the video, sound on/off, and a way out.
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(DesignTokens.s12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // The player's own state, native or embedded: the
                            // same mute the feed's sound button sets.
                            ValueListenableBuilder<bool>(
                              valueListenable: _playback.muted,
                              builder: (context, muted, _) => KeyedSubtree(
                                key: ReelCard.fullscreenSoundKey,
                                child: ReelSoundButton(
                                  muted: muted,
                                  onTap: _playback.toggleMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: DesignTokens.s8),
                            _FullscreenButton(
                              buttonKey: ReelCard.exitFullscreenKey,
                              label: ReelCard.exitFullscreenLabel,
                              icon: Icons.close_rounded,
                              onTap: _exitFullscreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Bottom scrim so overlaid text stays legible over any
                  // video.
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  if (embed != null)
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.s12),
                          child: _SoundOffButton(embed: embed),
                        ),
                      ),
                    ),

                  // Right rail (creator + follow, like, comments, share,
                  // tagged product or cart), drawn over the video for every
                  // platform — pulled down so it sits near the creator row
                  // instead of floating high above it. The full-screen button
                  // sits at its foot, in the rail's own column, so it can
                  // never land on a tag, a caption or the sound button.
                  //
                  // Bounded by the card's own top edge. The Home feed's first
                  // reel sits below the stories strip and is that much
                  // shorter, and on a small phone the rail would otherwise
                  // run off the top of the page, where the page clips it.
                  // scaleDown shrinks it only then; wherever it fits it keeps
                  // its natural size, as it always has.
                  Positioned(
                    right: DesignTokens.s12,
                    bottom: ReelCard.railBottom,
                    top: 0,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReelActions(
                              reel: widget.reel,
                              // Only the watched reel's rail flips its
                              // product photos.
                              isActive: widget.isActive,
                            ),
                            const SizedBox(height: DesignTokens.s12),
                            _FullscreenButton(
                              buttonKey: ReelCard.enterFullscreenKey,
                              label: ReelCard.enterFullscreenLabel,
                              icon: Icons.fullscreen_rounded,
                              onTap: _enterFullscreen,
                              subtle: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Creator info, caption and tagged products pinned to the
                  // bottom.
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Why this reel is here, said plainly — absent when
                        // the feed did not tell us, rather than guessed at —
                        // and the reel's "More" actions (Not interested,
                        // Report).
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 72,
                            bottom: DesignTokens.s8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: _ReelWhy(reel: widget.reel),
                                ),
                              ),
                              ReelMoreButton(reel: widget.reel),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 72),
                          // The rail carries follow; this row keeps name +
                          // track.
                          child: CreatorInfo(
                            reel: widget.reel,
                            showFollow: false,
                          ),
                        ),
                        if (widget.reel.taggedProducts.isNotEmpty) ...[
                          const SizedBox(height: DesignTokens.s12),
                          TaggedProductsSection(
                            products: widget.reel.taggedProducts,
                            reelId: widget.reel.id,
                            // Only the reel being watched cycles its product
                            // photos; neighbours the pager keeps alive hold
                            // still.
                            isActive: widget.isActive,
                          ),
                        ],
                        const SizedBox(height: DesignTokens.s16),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The round button that takes a reel full screen, or brings it back.
///
/// [subtle] is the entry point under the rail: smaller and fainter than the
/// rail's own actions, so it is there without competing with them.
class _FullscreenButton extends StatelessWidget {
  const _FullscreenButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtle = false,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final side = subtle ? 36.0 : 40.0;
    // One node that says what the button does and does it, rather than a
    // label beside an anonymous tap target.
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: buttonKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DesignTokens.baseBlack.withValues(
              alpha: subtle ? 0.3 : 0.45,
            ),
          ),
          child: Icon(
            icon,
            size: subtle ? 20 : 22,
            color: DesignTokens.iconWhite.withValues(
              alpha: subtle ? 0.8 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sound on/off for the reel on screen.
///
/// This used to render only once a platform had already refused sound, so a
/// reel that simply played quietly showed nothing at all — the viewer could
/// neither tell it was muted nor do anything about it (SM-016). It is now
/// always on screen for the active reel and always shows the current state.
class _SoundOffButton extends StatelessWidget {
  const _SoundOffButton({required this.embed});

  final EmbedRequest embed;

  @override
  Widget build(BuildContext context) {
    final pool = EmbedPlayerScope.maybeOf(context);
    if (pool == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: pool,
      builder: (context, _) {
        // Only the reel on screen: the neighbours either side are paused, and
        // their controls would sit under this one.
        if (pool.activeKey != embed.key) return const SizedBox.shrink();
        return ReelSoundButton(
          muted: pool.muted,
          onTap: () => pool.setMuted(!pool.muted),
        );
      },
    );
  }
}

/// The feed's provenance badge, or the reel-page rail a reel came from, or
/// nothing.
class _ReelWhy extends StatelessWidget {
  const _ReelWhy({required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    if (reel.provenance case final provenance?) {
      return FeedProvenanceBadge(provenance: provenance);
    }
    // Which AI rail of the reel page placed it here.
    if (reel.railLabel case final label?) {
      return MallSignalChip(
        key: ReelCard.railLabelKey,
        signal: MallSignal(label: label, icon: Icons.auto_awesome_outlined),
      );
    }
    return const SizedBox.shrink();
  }
}
