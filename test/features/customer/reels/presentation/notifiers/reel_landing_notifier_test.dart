import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_landing_notifier.dart';

typedef _Page = Either<NetworkExceptions, ReelsFeedPage>;

Reel _reel(String id) => Reel(
  id: id,
  sourceUrl: 'https://www.instagram.com/reel/$id/',
  thumbnailUrl: '',
  creatorId: 'creator-$id',
  creatorName: 'Creator $id',
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

_Page _page(List<String> ids, {String? next}) => right(
  ReelsFeedPage(reels: [for (final id in ids) _reel(id)], nextCursor: next),
);

class _FakeReelsRepository implements ReelsRepository {
  Either<NetworkExceptions, Reel> detail = right(_reel('landed'));

  /// Pages by the cursor they answer; '' is the first page.
  final Map<String, _Page> related = {};
  final Map<String, _Page> feed = {};

  final relatedCalls = <String?>[];
  final feedCalls = <String?>[];

  /// When set, related pages wait for it.
  Completer<void>? relatedGate;

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async =>
      detail;

  @override
  Future<_Page> getRelatedReels(
    String reelId, {
    int limit = 10,
    String? cursor,
  }) async {
    relatedCalls.add(cursor);
    await relatedGate?.future;
    return related[cursor ?? ''] ?? _page(const []);
  }

  @override
  Future<_Page> getReelsFeed({int limit = 20, String? cursor}) async {
    feedCalls.add(cursor);
    return feed[cursor ?? ''] ?? _page(const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<String> _ids(ReelLandingState state) => switch (state) {
  ReelLandingReady(:final reels) => [for (final reel in reels) reel.id],
  _ => const [],
};

/// Lets every answer already due arrive.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeReelsRepository repository;

  ReelLandingNotifier land() {
    final notifier = ReelLandingNotifier(repository, reelId: 'landed');
    addTearDown(notifier.dispose);
    return notifier;
  }

  setUp(() => repository = _FakeReelsRepository());

  test('shows the landed reel as soon as it is fetched, then appends its '
      'related reels', () async {
    final gate = repository.relatedGate = Completer<void>();
    repository.related[''] = _page(['r1', 'r2']);

    final notifier = land();
    expect(notifier.state, isA<ReelLandingLoading>());
    await _settle();

    expect(_ids(notifier.state), ['landed'], reason: 'related still loading');
    expect(repository.relatedCalls, [null]);

    gate.complete();
    await _settle();
    expect(_ids(notifier.state), ['landed', 'r1', 'r2']);
  });

  test('never shows a reel twice, the landed reel included', () async {
    repository.related
      ..[''] = _page(['landed', 'r1', 'r1', 'r2'], next: 'c1')
      ..['c1'] = _page(['r2', 'r3']);

    final notifier = land();
    await _settle();
    expect(_ids(notifier.state), ['landed', 'r1', 'r2']);

    await notifier.fetchNextPage();
    expect(_ids(notifier.state), ['landed', 'r1', 'r2', 'r3']);
    expect(repository.relatedCalls, [null, 'c1']);
  });

  test('when related reels run out it carries on into the general feed, '
      'still without repeats, and stops at its end', () async {
    repository.related[''] = _page(['r1']);
    repository.feed
      ..[''] = _page(['r1', 'landed', 'f1'], next: 'f-2')
      ..['f-2'] = _page(['f2']);

    final notifier = land();
    await _settle();
    expect(_ids(notifier.state), ['landed', 'r1']);
    expect(repository.feedCalls, isEmpty);

    await notifier.fetchNextPage();
    expect(_ids(notifier.state), ['landed', 'r1', 'f1']);

    await notifier.fetchNextPage();
    expect(_ids(notifier.state), ['landed', 'r1', 'f1', 'f2']);

    await notifier.fetchNextPage();
    expect(repository.feedCalls, [null, 'f-2']);
    expect(repository.relatedCalls, [null]);
  });

  test('a page of reels already shown fetches the next one straight away',
      () async {
    repository.related
      ..[''] = _page(['landed'], next: 'c1')
      ..['c1'] = _page(['landed'], next: 'c2')
      ..['c2'] = _page(['r9']);

    final notifier = land();
    await _settle();

    expect(_ids(notifier.state), ['landed', 'r9']);
    expect(repository.relatedCalls, [null, 'c1', 'c2']);
  });

  test('a failed related page stops the paging quietly and keeps the landed '
      'reel', () async {
    repository.related[''] = left(const NetworkExceptions.server('boom'));

    final notifier = land();
    await _settle();
    expect(_ids(notifier.state), ['landed']);

    await notifier.fetchNextPage();
    expect(_ids(notifier.state), ['landed']);
    expect(repository.relatedCalls, [null]);
    expect(repository.feedCalls, isEmpty);
  });

  test('a reel that is gone fails as not found, and a retry can land it',
      () async {
    repository.detail = left(const NetworkExceptions.notFound());

    final notifier = land();
    await _settle();
    final state = notifier.state;
    expect(state, isA<ReelLandingFailure>());
    expect((state as ReelLandingFailure).failure.isNotFound, isTrue);
    expect(repository.relatedCalls, isEmpty);

    repository.detail = right(_reel('landed'));
    await notifier.load();
    await _settle();
    expect(_ids(notifier.state), ['landed']);
  });

  test('asks for one page at a time', () async {
    final gate = repository.relatedGate = Completer<void>();
    repository.related[''] = _page(['r1'], next: 'c1');

    final notifier = land();
    await _settle();
    unawaited(notifier.fetchNextPage());
    unawaited(notifier.fetchNextPage());
    expect(repository.relatedCalls, [null]);

    gate.complete();
    await _settle();
    expect(_ids(notifier.state), ['landed', 'r1']);
  });
}
