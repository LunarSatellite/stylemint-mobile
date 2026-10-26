import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/entities/ai_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_landing_notifier.dart';

import '../../../ai_rails/fake_ai_rails_repository.dart';
import '../../fake_reels_repository.dart';

/// The reel page's AI rails (AI features contract v1.0 §3 "People also
/// watched", §4.3 "Similar reels") sit between the landed reel and its
/// related reels, labelled — and a server without them pages as before.
class _Reels implements ReelsRepository {
  final relatedCalls = <String?>[];

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async =>
      right(fakeReel('landed'));

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getRelatedReels(
    String reelId, {
    int limit = 10,
    String? cursor,
  }) async {
    relatedCalls.add(cursor);
    return right(
      ReelsFeedPage(
        reels: [fakeReel('rel-1'), fakeReel('cf-1')],
        nextCursor: null,
      ),
    );
  }

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getReelsFeed({
    int limit = 20,
    String? cursor,
  }) async => right(const ReelsFeedPage(reels: [], nextCursor: null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Reel> _reels(ReelLandingState state) => switch (state) {
  ReelLandingReady(:final reels) => reels,
  _ => const [],
};

Future<void> _drain(ReelLandingNotifier notifier) async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
    await notifier.fetchNextPage();
  }
}

void main() {
  test('also-watched, then similar by meaning, then related — each AI reel '
      'labelled with its rail, no reel twice', () async {
    final rails = FakeAiRailsRepository(
      alsoWatchedReels: [fakeReel('cf-1'), fakeReel('landed')],
      similar: ReelMatches(
        aiApplied: true,
        items: [
          MatchedReel(reel: fakeReel('sim-1'), kind: ReelMatchKind.meaning),
          MatchedReel(reel: fakeReel('cf-1'), kind: ReelMatchKind.meaning),
        ],
      ),
    );
    final notifier = ReelLandingNotifier(
      _Reels(),
      reelId: 'landed',
      rails: rails,
    );
    addTearDown(notifier.dispose);
    await _drain(notifier);

    final reels = _reels(notifier.state);
    expect([for (final r in reels) r.id], [
      'landed',
      'cf-1',
      'sim-1',
      'rel-1',
    ]);
    expect(reels[0].railLabel, isNull);
    expect(reels[1].railLabel, ReelLandingNotifier.alsoWatchedLabel);
    expect(reels[2].railLabel, ReelLandingNotifier.similarLabel);
    expect(reels[3].railLabel, isNull);
  });

  test('similar reels are skipped when meaning matching did not run', () async {
    final notifier = ReelLandingNotifier(
      _Reels(),
      reelId: 'landed',
      rails: FakeAiRailsRepository(
        similar: ReelMatches(
          aiApplied: false,
          items: [
            MatchedReel(reel: fakeReel('sim-1'), kind: ReelMatchKind.meaning),
          ],
        ),
      ),
    );
    addTearDown(notifier.dispose);
    await _drain(notifier);

    expect(
      [for (final r in _reels(notifier.state)) r.id],
      ['landed', 'rel-1', 'cf-1'],
    );
  });

  test('both rails not deployed (404): the related reels follow the landed '
      'reel exactly as before', () async {
    final reels = _Reels();
    final rails = FakeAiRailsRepository();
    final notifier = ReelLandingNotifier(
      reels,
      reelId: 'landed',
      rails: rails,
    );
    addTearDown(notifier.dispose);
    await _drain(notifier);

    expect(rails.calls, ['alsoWatched:landed', 'similar:landed']);
    expect(reels.relatedCalls, isNotEmpty);
    final shown = _reels(notifier.state);
    expect([for (final r in shown) r.id], ['landed', 'rel-1', 'cf-1']);
    expect(shown.every((r) => r.railLabel == null), isTrue);
  });
}
