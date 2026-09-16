import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_poster.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The reel behind a window, by id.
///
/// A Mall tile's [MallReelRef] carries the reel id and a poster — no
/// permalink, no media URL, and (deliberately, so the Mall kit stays free of
/// domain types) no platform or external id either. So the window resolves
/// playback the way every other reel surface does:
/// `ReelsRepository.getReelDetail`, which yields the [Reel] entity — a
/// `ReelMedia` — that [ReelPlayer] and `resolveReelPlayback` already know how
/// to play. One request per open, and the player is the app's only one.
///
/// Null when the fetch failed: the window says so in its chrome rather than
/// throwing inside a dialog that has nowhere to put an error.
// The family's provider type is long and says nothing the right side doesn't.
// ignore: specify_nonobvious_property_types
final reelWindowReelProvider = FutureProvider.autoDispose.family<Reel?, String>(
  (ref, reelId) async {
    final either = await ref.watch(reelsRepositoryProvider).getReelDetail(
      reelId,
    );
    return either.fold((_) => null, (reel) => reel);
  },
);

/// Opens [reel] in a window over whatever screen is showing (owner decision,
/// 2026-09-16: "it's like a play button tile — users will click it and we
/// will play reels as a window").
Future<void> openMallReelWindow(BuildContext context, MallReelRef reel) =>
    ReelWindow.open(
      context,
      reelId: reel.reelId,
      hook: reel.hook,
      isAiGenerated: reel.isAiGenerated,
    );

/// One reel, played in a window layered over the screen that opened it —
/// never a full-screen push, never inline in the tile.
///
/// **The player rectangle is untouchable.** YouTube's embedded player terms
/// forbid drawing anything in front of it, so the close control, the
/// AI-generated disclosure, the hook and the shoppable products all live in
/// the chrome above and below [playerRectKey], never over it. The one
/// transparent layer that spans the window ([panelKey]) is painted *behind*
/// the content and draws nothing: it is there so a tap on the window's own
/// padding does not fall through to the barrier and close it.
///
/// Dismissed by the close control, a swipe down on the chrome, a tap outside
/// the window, or the system back button.
///
/// Exactly one window exists at a time ([isOpen]): a second [open] while one
/// is up is refused rather than stacked, so two players can never be alive
/// together, and closing the window unmounts — and so disposes — the single
/// [ReelPlayer] it built, along with the embed pool that player owns.
class ReelWindow extends ConsumerStatefulWidget {
  const ReelWindow({
    required this.reelId,
    super.key,
    this.hook,
    this.isAiGenerated = false,
  });

  /// The player rectangle. Nothing may be drawn in front of this box.
  static const Key playerRectKey = Key('reel-window-player');
  static const Key closeKey = Key('reel-window-close');
  static const Key headerKey = Key('reel-window-header');
  static const Key footerKey = Key('reel-window-footer');
  static const Key aiLabelKey = Key('reel-window-ai-label');
  static const Key hookKey = Key('reel-window-hook');
  static const Key productsKey = Key('reel-window-products');

  /// Keys the transparent, childless tap sink behind the window's content.
  /// Its box spans the window, so it is the one thing a "nothing in front of
  /// the player" sweep has to skip — see the test that asserts it paints
  /// nothing.
  static const Key panelKey = Key('reel-window-panel');

  /// Reduced motion only: starts playback on the viewer's own tap.
  static const Key playKey = Key('reel-window-play');

  static const String closeLabel = 'Close reel';
  static const String playLabel = 'Play reel';
  static const String aiGeneratedLabel = 'AI-generated';
  static const String unavailableMessage =
      "This reel can't be opened right now";

  /// Widest the player rectangle ever gets: a reel is a portrait video, and a
  /// window wider than this is all letterbox.
  static const double maxPlayerWidth = 380;

  /// Narrowest it gets before the box stops shrinking and letterboxes
  /// instead — a player the size of a stamp is not a window.
  static const double minPlayerWidth = 240;

  /// Share of the window's height the player rectangle may take. The rest is
  /// chrome, which is where every control has to live.
  static const double playerHeightShare = 0.62;

  /// Breathing room between the window's edge and its content.
  static const double panelPadding = DesignTokens.s12;

  final String reelId;

  /// The tile's hook, shown in the chrome under the player.
  final String? hook;

  /// Flagged reels keep the disclosure in the chrome. Non-negotiable.
  final bool isAiGenerated;

  /// Whether a reel window is open. Exactly one is allowed at a time.
  static bool get isOpen => _openToken != null;

  /// Identifies the open window so a stale [open] call — one whose route has
  /// already been replaced — cannot clear a newer window's claim.
  static Object? _openToken;

  /// Forgets the open window. For tests, which share the static claim and
  /// can tear a tree down before a window's route future ever completes.
  @visibleForTesting
  static void debugResetOpenState() => _openToken = null;

  /// The player rectangle for a window with [maxWidth] × [maxHeight] to
  /// spend. Portrait 9:16 whenever it fits; on a short or narrow screen the
  /// box holds [minPlayerWidth] and lets the player letterbox itself rather
  /// than shrinking past the point of being worth opening.
  static Size playerSize(double maxWidth, double maxHeight) {
    if (maxWidth <= 0 || maxHeight <= 0) return Size.zero;
    final width = math.min(maxWidth, maxPlayerWidth);
    final height = math.min(maxHeight * playerHeightShare, width * 16 / 9);
    final portrait = math.min(width, height * 9 / 16);
    return Size(
      math.max(portrait, math.min(maxWidth, minPlayerWidth)),
      height,
    );
  }

  /// Opens the window over the current screen. A second call while one is
  /// open is refused — windows never stack.
  static Future<void> open(
    BuildContext context, {
    required String reelId,
    String? hook,
    bool isAiGenerated = false,
  }) async {
    if (_openToken != null) return;
    final token = Object();
    _openToken = token;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    try {
      await showGeneralDialog<void>(
        context: context,
        // On the root navigator (the default), so the window layers over the
        // whole app rather than inside a tab's shell branch.
        // Tap outside dismisses; the system back button pops the route.
        barrierDismissible: true,
        barrierLabel: closeLabel,
        barrierColor: const Color(0xE6000000),
        transitionDuration: reduceMotion
            ? Duration.zero
            : DesignTokens.motionFast,
        pageBuilder: (context, _, _) => ReelWindow(
          reelId: reelId,
          hook: hook,
          isAiGenerated: isAiGenerated,
        ),
        transitionBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      );
    } finally {
      if (identical(_openToken, token)) _openToken = null;
    }
  }

  @override
  ConsumerState<ReelWindow> createState() => _ReelWindowState();
}

class _ReelWindowState extends ConsumerState<ReelWindow> {
  /// Reduced motion: the window opens on the poster and the viewer starts
  /// playback themselves. Nothing ever autoplays.
  bool _started = false;

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _openProduct(String productId) {
    final router = GoRouter.of(context);
    _close();
    unawaited(
      router.push(
        RouteNames.productDetail.replaceFirst(':productId', productId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final async = ref.watch(reelWindowReelProvider(widget.reelId));
    final reel = async.asData?.value;
    final hook = widget.hook?.trim();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const inset = ReelWindow.panelPadding * 2;
              final player = ReelWindow.playerSize(
                constraints.maxWidth - inset,
                constraints.maxHeight - inset,
              );
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: DesignTokens.surfaceRaised,
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                  border: Border.all(color: DesignTokens.glassStroke),
                ),
                child: Stack(
                  children: [
                    // Behind everything and drawing nothing: it keeps a tap
                    // on the window's padding from reaching the barrier.
                    // Never in front of the player.
                    Positioned.fill(
                      key: ReelWindow.panelKey,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(ReelWindow.panelPadding),
                      child: SizedBox(
                        width: player.width,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _header(),
                            // The player rectangle. Chrome sits around it,
                            // never on it.
                            SizedBox(
                              key: ReelWindow.playerRectKey,
                              width: player.width,
                              height: player.height,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusMedium,
                                ),
                                child: _playerArea(
                                  async.isLoading,
                                  reel,
                                  reduceMotion: reduceMotion,
                                ),
                              ),
                            ),
                            Flexible(
                              child: SingleChildScrollView(
                                child: _footer(reel, hook),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Grab handle, the AI-generated disclosure and the close control — all of
  /// it above the player rectangle.
  Widget _header() => _DismissDrag(
    key: ReelWindow.headerKey,
    onDismiss: _close,
    child: Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.glassStroke,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              if (widget.isAiGenerated)
                const Flexible(
                  child: _ChromeBadge(
                    key: ReelWindow.aiLabelKey,
                    icon: Icons.auto_awesome_rounded,
                    label: ReelWindow.aiGeneratedLabel,
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: DesignTokens.minTouchTarget,
                height: DesignTokens.minTouchTarget,
                child: IconButton(
                  key: ReelWindow.closeKey,
                  onPressed: _close,
                  tooltip: ReelWindow.closeLabel,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DesignTokens.iconWhite,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  /// The hook and the reel's shoppable products — all of it below the player
  /// rectangle.
  Widget _footer(Reel? reel, String? hook) {
    final products = reel?.taggedProducts ?? const <TaggedProductEntity>[];
    return _DismissDrag(
      key: ReelWindow.footerKey,
      onDismiss: _close,
      child: Padding(
        padding: const EdgeInsets.only(top: DesignTokens.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hook != null && hook.isNotEmpty)
              Text(
                hook,
                key: ReelWindow.hookKey,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: _hookStyle,
              ),
            if (products.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s8),
              SizedBox(
                key: ReelWindow.productsKey,
                height: DesignTokens.minTouchTarget,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: DesignTokens.s8),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductChip(
                      label: product.name,
                      onTap: () => _openProduct(product.id),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _playerArea(
    bool isLoading,
    Reel? reel, {
    required bool reduceMotion,
  }) {
    if (reel == null) {
      return ColoredBox(
        color: DesignTokens.baseBlack,
        child: isLoading ? const SmPageLoader() : _unavailable(),
      );
    }
    // Reduced motion: the poster and a play control, never an autoplay. The
    // control sits over the *poster* — by the time a player exists it is
    // gone, so nothing is ever drawn in front of a player.
    if (reduceMotion && !_started) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ReelPoster(reel: reel),
          Center(
            child: _PlayControl(
              key: ReelWindow.playKey,
              onTap: () => setState(() => _started = true),
            ),
          ),
        ],
      );
    }
    return ReelPlayer(reel: reel, isActive: true);
  }

  Widget _unavailable() => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.s24),
      child: Text(
        ReelWindow.unavailableMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: DesignTokens.iconWhite,
        ),
      ),
    ),
  );

  static const TextStyle _hookStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: DesignTokens.textWhite,
  );
}

/// A piece of window chrome that swallows taps meant for the window (so they
/// never reach the dismiss barrier) and closes the window on a downward
/// fling. Only ever wrapped around chrome — never around the player, whose
/// own gestures stay its own.
class _DismissDrag extends StatelessWidget {
  const _DismissDrag({required this.onDismiss, required this.child, super.key});

  /// Downward velocity, in logical pixels per second, that counts as a
  /// deliberate swipe down rather than a stray drag.
  static const double dismissVelocity = 200;

  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onVerticalDragEnd: (details) {
      if ((details.primaryVelocity ?? 0) > dismissVelocity) onDismiss();
    },
    child: child,
  );
}

/// Disclosure pill in the window chrome.
class _ChromeBadge extends StatelessWidget {
  const _ChromeBadge({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: DesignTokens.glassFill,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DesignTokens.iconWhite),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: DesignTokens.textWhite,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One shoppable product from the reel, in the chrome below the player.
class _ProductChip extends StatelessWidget {
  const _ProductChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: DesignTokens.glassFill,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 14,
              color: DesignTokens.iconWhite,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The reduced-motion start control. It only ever sits over the poster — by
/// the time a player exists, it is gone.
class _PlayControl extends StatelessWidget {
  const _PlayControl({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: ReelWindow.playLabel,
    child: Material(
      color: const Color(0x8C000000),
      shape: const CircleBorder(
        side: BorderSide(color: DesignTokens.glassStroke),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            Icons.play_arrow_rounded,
            size: 36,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
    ),
  );
}
