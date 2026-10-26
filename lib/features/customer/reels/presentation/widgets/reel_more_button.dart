import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_item_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "More" on a reel: the same actions sheet as a Discover card — "Not
/// interested" (`POST api/v1/customer/feed/not-interested`, which the
/// personal feed ranker always respects, AI features contract v1.0 §2.1)
/// and "Report reel".
///
/// The reel disappears from the feed at once (the feed screen filters what
/// the viewer hid) and comes back on Undo or when the server refuses.
class ReelMoreButton extends ConsumerWidget {
  const ReelMoreButton({required this.reel, super.key});

  static const Key buttonKey = Key('reel-more-button');

  final Reel reel;

  /// What the sheet calls the reel: its creator, else its caption.
  static String itemLabel(Reel reel) {
    final creator = reel.creatorName.trim();
    if (creator.isNotEmpty) return 'Reel by $creator';
    final caption = reel.caption.trim();
    return caption.isEmpty ? 'This reel' : caption;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reel.id.isEmpty) return const SizedBox.shrink();
    return IconButton(
      key: buttonKey,
      tooltip: 'More options',
      onPressed: () => unawaited(
        showDiscoverItemActions(
          context,
          ref,
          target: NotInterestedTarget(NotInterestedKind.reel, reel.id),
          itemLabel: itemLabel(reel),
        ),
      ),
      style: IconButton.styleFrom(
        backgroundColor: DesignTokens.baseBlack.withValues(alpha: 0.35),
        fixedSize: const Size.square(DesignTokens.minTouchTarget),
      ),
      icon: const Icon(
        Icons.more_horiz_rounded,
        color: DesignTokens.textWhite,
      ),
    );
  }
}

/// Whether the viewer hid [reel] — the reel itself, or its creator.
extension NotInterestedReels on Set<NotInterestedTarget> {
  bool hidesFeedReel(Reel reel) =>
      contains(NotInterestedTarget(NotInterestedKind.reel, reel.id)) ||
      (reel.creatorId.isNotEmpty &&
          contains(
            NotInterestedTarget(NotInterestedKind.creator, reel.creatorId),
          ));
}
