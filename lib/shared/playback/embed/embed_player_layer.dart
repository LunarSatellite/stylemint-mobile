import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_pool.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot_view.dart';

/// Hosts a pool's WebViews beneath a vertical reel feed.
///
/// Every slot stays mounted, but only the one holding the reel the feed came
/// to rest on is on stage, and it moves with the scroll so the video tracks
/// its page. Neighbouring pages show their posters while the user drags. On
/// the low-end test phone, moving more than one WebView per frame missed
/// about half the frame deadlines; moving one keeps the swipe smooth.
class EmbedPlayerLayer extends StatelessWidget {
  const EmbedPlayerLayer({
    required this.pool,
    required this.controller,
    required this.settledIndex,
    required this.indexOfKey,
    required this.playerRectAt,
    this.layoutChanges,
    super.key,
  });

  /// Notifies when a player rectangle may have changed shape, e.g. when a
  /// reel's video turns out to be wider than a Short.
  final Listenable? layoutChanges;

  final EmbedPlayerPool pool;
  final PageController controller;

  /// The page the feed last came to rest on.
  final int settledIndex;

  /// Page index of the reel with this embed key, if it is in the feed.
  final int? Function(String key) indexOfKey;

  /// The player's rectangle on page [index] of size [page].
  final Rect Function(int index, Size page) playerRectAt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final page = constraints.biggest;
        return ListenableBuilder(
          listenable: Listenable.merge([controller, pool, layoutChanges]),
          builder: (context, _) {
            final scroll =
                controller.hasClients && controller.position.haveDimensions
                ? controller.page ?? settledIndex.toDouble()
                : settledIndex.toDouble();
            // The reel on stage is drawn last, on top of a waiting one.
            final slots = [...pool.slots]
              ..sort((a, b) => (_onStage(a) ? 1 : 0) - (_onStage(b) ? 1 : 0));
            return Stack(
              children: [for (final slot in slots) _place(slot, page, scroll)],
            );
          },
        );
      },
    );
  }

  bool _onStage(EmbedSlot slot) {
    final key = slot.key;
    return key != null &&
        key == pool.activeKey &&
        indexOfKey(key) == settledIndex;
  }

  Widget _place(EmbedSlot slot, Size page, double scroll) {
    final key = slot.key;
    final index = key == null ? null : indexOfKey(key);
    final onStage = _onStage(slot);
    // A pre-rolling reel stays attached but still, hidden behind the reel on
    // stage: an off-screen WebView stops its media, which the pre-roll needs.
    // It never moves, so a swipe still moves only one WebView.
    final waiting = !onStage && index != null && slot.prerolls;
    final rect = playerRectAt(index ?? settledIndex, page);
    return Positioned.fromRect(
      key: ValueKey('embed-slot-${slot.index}-${slot.generation}'),
      rect: onStage
          ? rect.shift(Offset(0, (settledIndex - scroll) * page.height))
          : rect,
      child: Offstage(
        offstage: !onStage && !waiting,
        child: EmbedSlotView(slot: slot),
      ),
    );
  }
}
