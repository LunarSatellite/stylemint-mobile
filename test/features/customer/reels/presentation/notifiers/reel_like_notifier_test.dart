import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_like_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_like_notifier.dart';

typedef _LikeAnswer = Either<NetworkExceptions, ReelLikeResult>;

class _FakeReelsRepository implements ReelsRepository {
  final likeCalls = <String>[];
  final unlikeCalls = <String>[];

  /// When set, requests wait for this instead of answering at once.
  Completer<_LikeAnswer>? pending;

  /// The answer for a request that asked for [liked].
  _LikeAnswer Function(bool liked) respond = (liked) =>
      right(ReelLikeResult(liked: liked));

  Future<_LikeAnswer> _answer(bool liked) =>
      pending?.future ?? Future.value(respond(liked));

  @override
  Future<_LikeAnswer> likeReel(String reelId) {
    likeCalls.add(reelId);
    return _answer(true);
  }

  @override
  Future<_LikeAnswer> unlikeReel(String reelId) {
    unlikeCalls.add(reelId);
    return _answer(false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _unseeded = ReelLikeState(liked: false, count: 0);

void main() {
  late _FakeReelsRepository repository;
  late ReelLikeNotifier notifier;

  setUp(() {
    repository = _FakeReelsRepository();
    notifier = ReelLikeNotifier(repository);
    addTearDown(notifier.dispose);
  });

  test('a like shows at once, then takes the server count', () async {
    final pending = repository.pending = Completer<_LikeAnswer>();
    notifier.seed('reel-1', liked: false, count: 128);

    final toggled = notifier.toggle('reel-1', fallback: _unseeded);

    expect(notifier.state['reel-1'], const ReelLikeState(liked: true, count: 129));
    pending.complete(right(const ReelLikeResult(liked: true, likeCount: 140)));
    expect(await toggled, isNull);
    expect(notifier.state['reel-1'], const ReelLikeState(liked: true, count: 140));
    expect(repository.likeCalls, ['reel-1']);
    expect(repository.unlikeCalls, isEmpty);
  });

  test('a failed like rolls back and reports the failure', () async {
    repository.respond = (_) => left(const NetworkExceptions.server('boom'));
    notifier.seed('reel-1', liked: false, count: 5);

    final failure = await notifier.toggle('reel-1', fallback: _unseeded);

    expect(failure, isNotNull);
    expect(notifier.state['reel-1'], const ReelLikeState(liked: false, count: 5));
  });

  test('an unlike removes the like and keeps the optimistic count when the '
      'server sends none', () async {
    notifier.seed('reel-1', liked: true, count: 10);

    final failure = await notifier.toggle('reel-1', fallback: _unseeded);

    expect(failure, isNull);
    expect(repository.unlikeCalls, ['reel-1']);
    expect(notifier.state['reel-1'], const ReelLikeState(liked: false, count: 9));
  });

  test('a failed unlike restores the like', () async {
    repository.respond = (_) => left(const NetworkExceptions.noInternetConnection());
    notifier.seed('reel-1', liked: true, count: 1);

    await notifier.toggle('reel-1', fallback: _unseeded);

    expect(notifier.state['reel-1'], const ReelLikeState(liked: true, count: 1));
  });

  test('starts from the fallback when the reel was never seeded', () async {
    await notifier.toggle(
      'reel-2',
      fallback: const ReelLikeState(liked: false, count: 3),
    );

    expect(notifier.state['reel-2'], const ReelLikeState(liked: true, count: 4));
  });

  test('a server snapshot never overrides the viewer\'s toggle', () async {
    notifier.seed('reel-1', liked: false, count: 7);
    await notifier.toggle('reel-1', fallback: _unseeded);

    notifier.seed('reel-1', liked: false, count: 7);

    expect(notifier.state['reel-1'], const ReelLikeState(liked: true, count: 8));
  });

  test('a fresher snapshot updates a reel the viewer has not touched', () {
    notifier
      ..seed('reel-1', liked: false, count: 7)
      ..seed('reel-1', liked: true, count: 9);

    expect(notifier.state['reel-1'], const ReelLikeState(liked: true, count: 9));
  });

  test('ignores a tap while the previous request is still running', () async {
    final pending = repository.pending = Completer<_LikeAnswer>();
    notifier.seed('reel-1', liked: false, count: 1);

    final first = notifier.toggle('reel-1', fallback: _unseeded);
    final second = await notifier.toggle('reel-1', fallback: _unseeded);
    pending.complete(right(const ReelLikeResult(liked: true, likeCount: 2)));
    await first;

    expect(second, isNull);
    expect(repository.likeCalls, ['reel-1']);
    expect(notifier.state['reel-1'], const ReelLikeState(liked: true, count: 2));
  });

  test('never counts below zero', () async {
    notifier.seed('reel-1', liked: true, count: 0);

    await notifier.toggle('reel-1', fallback: _unseeded);

    expect(notifier.state['reel-1'], const ReelLikeState(liked: false, count: 0));
  });
}
