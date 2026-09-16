import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

/// A reel with nothing to play: no platform and no media URL, which is the
/// resolver's external-only path — a poster and a short note, no WebView and
/// no video engine. Enough for the surfaces that only open the window; what
/// plays inside the rectangle is `reel_window_test.dart`'s business.
Reel fakeReel(String reelId) => Reel(
  id: reelId,
  sourceUrl: '',
  thumbnailUrl: '',
  creatorId: 'a-1',
  creatorName: 'priya',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: const [],
  likeCount: 0,
  commentCount: 0,
  shareCount: 0,
  createdAt: DateTime(2026, 9, 15),
);

/// The repository the reel window resolves playback through. Any surface
/// whose cards open the window needs it overridden, or the window reaches
/// for the network from a widget test.
class FakeReelsRepository implements ReelsRepository {
  /// Every reel id a window asked for.
  final List<String> requested = [];

  /// Empty rather than absent: a screen that also shows the reels feed (Home
  /// in Reels mode) asks for it, and `noSuchMethod` would throw.
  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getReelsFeed({
    int limit = 20,
    String? cursor,
  }) async => right(const ReelsFeedPage(reels: [], nextCursor: null));

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async {
    requested.add(reelId);
    return right(fakeReel(reelId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
