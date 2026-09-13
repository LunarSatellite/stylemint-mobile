import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_pool.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_play_indicator.dart';

/// What a reel page draws for an embedded reel.
///
/// The poster stays up until the player has something to show, so a swipe
/// never reveals a blank or loading player. If the embed fails for good the
/// page shows [fallback], a hand-off to the platform, instead.
class EmbedReelSurface extends StatelessWidget {
  const EmbedReelSurface({
    required this.pool,
    required this.request,
    required this.poster,
    required this.fallback,
    this.ownsPlayer = false,
    this.showPauseIndicator = true,
    super.key,
  });

  final EmbedPlayerPool pool;
  final EmbedRequest request;
  final Widget poster;
  final Widget fallback;

  /// Draw the pool's first slot here. Used outside a feed, where the page
  /// has a single player of its own rather than a shared layer beneath it.
  final bool ownsPlayer;

  /// Show the play mark while the viewer has the reel paused.
  final bool showPauseIndicator;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: pool,
      builder: (context, _) {
        final slot = pool.slotFor(request.key);
        final onStage = slot != null && pool.activeKey == request.key;
        if (onStage && pool.hasGivenUp(request.key)) return fallback;
        // The poster stays up until the video is actually moving, so the
        // platform's loading and cued screens are never seen.
        final showsFrames = onStage && slot.hasStarted;
        final own = pool.slots.isEmpty ? null : pool.slots.first;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (ownsPlayer && own != null)
              EmbedSlotView(
                key: ValueKey('own-embed-${own.generation}'),
                slot: own,
              ),
            if (!showsFrames) poster,
            if (showsFrames && showPauseIndicator && pool.userPaused)
              const Center(child: ReelPlayIndicator()),
          ],
        );
      },
    );
  }
}
