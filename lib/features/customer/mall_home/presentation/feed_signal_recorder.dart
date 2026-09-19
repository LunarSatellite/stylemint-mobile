import 'dart:async';

import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/storefront_personalizer.dart';

/// What a reel's dwell time means, or null when it means nothing.
///
/// A reel swiped away inside [reelSkipThreshold] was rejected on sight; one
/// held past [reelWatchThreshold] was actually watched. The gap between the
/// two is deliberate and is reported as neither: most swipes land there, and
/// guessing at them would teach the feed noise.
FeedSignalAction? reelDwellSignal(Duration dwell) {
  if (dwell < reelSkipThreshold) return FeedSignalAction.skipped;
  if (dwell >= reelWatchThreshold) return FeedSignalAction.watched;
  return null;
}

const Duration reelSkipThreshold = Duration(milliseconds: 1500);
const Duration reelWatchThreshold = Duration(seconds: 5);

/// Sends adaptive-storefront signals from the screens where they happen.
///
/// Every method is fire-and-forget: it never blocks a tap, never throws and
/// never shows an error. The same signal for the same entity is sent once per
/// recorder, so a reel re-watched on the way back up the feed, or a product
/// page rebuilt, does not count twice.
class FeedSignalRecorder {
  FeedSignalRecorder(this._personalizer);

  final StorefrontPersonalizer _personalizer;

  final Set<String> _sent = <String>{};

  /// A reel held the viewer past the watch threshold.
  void reelWatched(String reelId) =>
      _send(reelId, FeedSignalEntity.reel, FeedSignalAction.watched);

  /// A reel was swiped away almost at once.
  void reelSkipped(String reelId) =>
      _send(reelId, FeedSignalEntity.reel, FeedSignalAction.skipped);

  /// A reel left the screen after [dwell]. Sends watched, skipped or — for
  /// the ordinary middle of a swipe — nothing at all.
  void reelDwell(String reelId, Duration dwell) {
    final action = reelDwellSignal(dwell);
    if (action == null) return;
    _send(reelId, FeedSignalEntity.reel, action);
  }

  /// A product details page was opened.
  void productViewed(String productId) =>
      _send(productId, FeedSignalEntity.product, FeedSignalAction.viewedDetail);

  /// A search was submitted against a known category.
  void searched(String categoryId) =>
      _send(categoryId, FeedSignalEntity.search, FeedSignalAction.searched);

  /// An order was placed for a product.
  void bought(String productId) =>
      _send(productId, FeedSignalEntity.product, FeedSignalAction.bought);

  void _send(String id, FeedSignalEntity entity, FeedSignalAction action) {
    final entityId = id.trim();
    if (entityId.isEmpty) return;
    if (!_sent.add('${entity.wire}:${action.wire}:$entityId')) return;
    try {
      unawaited(
        _personalizer
            .track(
              FeedSignal(entityId: entityId, entity: entity, action: action),
            )
            .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
    } on Object catch (_) {
      // Best effort only.
    }
  }
}
