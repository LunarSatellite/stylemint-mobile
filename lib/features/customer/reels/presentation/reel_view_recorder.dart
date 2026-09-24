import 'dart:async';

import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

/// A watch shorter than this was a swipe past, not a view.
///
/// Matches the feed's own skip threshold: the same gesture should not be a
/// "skip" to the ranker and a "view" to the creator's stats.
const Duration reelViewThreshold = Duration(milliseconds: 1500);

/// The share of a reel's length that has to play before the view counts as
/// completed, matching what the endpoint's contract describes as the usual
/// client definition.
const double reelCompletionFraction = 0.9;

/// Whether a watch of [dwell] on a reel of [durationSeconds] counts as
/// completed.
///
/// An unknown length cannot be completed: without a duration there is no
/// "end" to have reached, and inventing one would inflate the completion rate
/// creators are judged on. A reel reporting zero length is treated the same.
bool reelViewCompleted(Duration dwell, int? durationSeconds) {
  if (durationSeconds == null || durationSeconds <= 0) return false;
  final needed = durationSeconds * reelCompletionFraction;
  return dwell.inMilliseconds >= needed * 1000;
}

/// Posts a view for each reel the viewer actually watched.
///
/// Fire-and-forget, like [FeedSignalRecorder]: a failed view must never
/// interrupt scrolling or surface an error. Guests record nothing — the
/// endpoint is authenticated — and the failure is swallowed here rather than
/// checked for, because the feed does not otherwise care who is signed in.
///
/// Each reel counts once per recorder, and a recorder lives as long as the
/// screen: scrolling back up a feed does not count a reel twice, but opening
/// the feed again tomorrow does. A reel first seen briefly and later watched
/// to the end is upgraded once — the completed view is worth sending even
/// though the plain view already went.
class ReelViewRecorder {
  ReelViewRecorder(this._repository);

  final ReelsRepository _repository;

  final Set<String> _viewed = <String>{};
  final Set<String> _completed = <String>{};

  /// Call when a reel leaves the screen, with how long it was on it.
  void recordDwell(Reel reel, Duration dwell) {
    if (reel.id.isEmpty || dwell < reelViewThreshold) return;
    final completed = reelViewCompleted(dwell, reel.durationSeconds);

    if (completed) {
      if (!_completed.add(reel.id)) return;
      _viewed.add(reel.id);
    } else if (!_viewed.add(reel.id)) {
      return;
    }

    _send(reel.id, completed: completed);
  }

  void _send(String reelId, {required bool completed}) {
    try {
      unawaited(
        _repository
            .recordView(reelId, completed: completed)
            .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
    } on Object catch (_) {
      // Best effort only.
    }
  }
}
