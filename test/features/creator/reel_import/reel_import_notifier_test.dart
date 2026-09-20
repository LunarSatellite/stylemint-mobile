import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/content_freshness.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

class _FakeRepository implements ReelImportRepository {
  _FakeRepository({this.pages, this.gates = const {}});

  /// Consumed in order, one per getImportableReels call.
  List<NetworkEither<ImportableReelsResult>>? pages;

  /// When a call index has a gate, that call waits for it before answering.
  final Map<int, Completer<void>> gates;

  final List<String?> cursors = [];
  final List<bool> refreshes = [];
  final List<SocialPlatform> platforms = [];
  int pageCalls = 0;

  @override
  Future<NetworkEither<ImportableReelsResult>> getImportableReels(
    SocialPlatform platform, {
    String? cursor,
    bool refresh = false,
  }) async {
    final index = pageCalls++;
    cursors.add(cursor);
    refreshes.add(refresh);
    platforms.add(platform);
    final page = pages != null && index < pages!.length
        ? pages![index]
        : networkRight(
            ImportableReelsResult(reels: [_reel('r$index')], nextCursor: null),
          );
    final gate = gates[index];
    if (gate != null) await gate.future;
    return page;
  }

  @override
  Future<NetworkEither<ImportedReel>> importReel(
    ImportableReel reel, {
    String? caption,
  }) async => networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<List<TaggedProductForImport>>> searchProducts(
    String query,
  ) async => networkRight(const []);

  @override
  Future<NetworkEither<List<TaggedProductForImport>>> getSuggestedProducts({
    required SocialPlatform platform,
    required String externalId,
  }) async => networkRight(const []);

  @override
  Future<NetworkEither<Unit>> publishReel({required String reelId}) async =>
      networkRight(unit);

  @override
  Future<NetworkEither<Unit>> tagProduct({
    required String reelId,
    required String productId,
  }) async => networkRight(unit);

  @override
  Future<NetworkEither<List<ImportedReel>>> getImportHistory({
    int pageSize = 20,
    String? cursor,
  }) async => networkRight(const []);

  @override
  Future<NetworkEither<BulkImportResult>> importBulk(
    List<ImportableReel> reels,
  ) async => networkRight(
    BulkImportResult(
      successCount: reels.length,
      failureCount: 0,
      allSucceeded: true,
    ),
  );

  @override
  Future<NetworkEither<ReelIntent>> launchReelIntent(
    SocialPlatform platform,
  ) async => networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<ReelIntent>> completeReelIntent({
    required String intentId,
    required String resultingReelId,
  }) async => networkLeft(const NetworkExceptions.unexpectedError());
}

ImportableReel _reel(String id) => ImportableReel(
  id: id,
  platform: SocialPlatform.instagram,
  platformPostId: id,
  sourceUrl: 'https://example.com/$id',
  thumbnailUrl: '',
  caption: '',
  createdAt: DateTime.utc(2026),
  videoDuration: 15,
);

typedef _Success = ({
  List<ImportableReel> reels,
  bool hasMore,
  ContentFreshness freshness,
  DateTime? blockedUntil,
  NetworkExceptions? refreshFailure,
});

_Success? _success(ReelImportState state) => state.maybeWhen(
  loadSuccess: (reels, hasMore, _, freshness, blockedUntil, refreshFailure) => (
    reels: reels,
    hasMore: hasMore,
    freshness: freshness,
    blockedUntil: blockedUntil,
    refreshFailure: refreshFailure,
  ),
  orElse: () => null,
);

List<String> _ids(ReelImportState state) =>
    _success(state)?.reels.map((r) => r.id).toList() ?? const ['<none>'];

final _now = DateTime.utc(2026, 9, 14, 15);

ContentFreshness _rateLimitedUntil(DateTime retryAfter) => ContentFreshness(
  servedFromCache: true,
  fetchedUtc: _now.subtract(const Duration(minutes: 12)),
  providerStatus: ContentProviderStatus(
    code: 'RATE_LIMITED',
    message: 'Instagram is limiting requests right now.',
    retryAfterUtc: retryAfter,
  ),
);

void main() {
  group('ReelImportNotifier', () {
    test(
      'load populates reels and reports no more pages when cursor is null',
      () async {
        final notifier = ReelImportNotifier(_FakeRepository());

        await notifier.load(SocialPlatform.instagram);

        final success = _success(notifier.state)!;
        expect(success.reels, hasLength(1));
        expect(success.hasMore, isFalse);
      },
    );

    test('a non-null cursor marks more pages available', () async {
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(reels: [_reel('a')], nextCursor: 'c1'),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);

      expect(_success(notifier.state)!.hasMore, isTrue);
    });

    test('loadMore appends the next page and forwards the cursor', () async {
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(reels: [_reel('a')], nextCursor: 'c1'),
          ),
          networkRight(
            ImportableReelsResult(reels: [_reel('b')], nextCursor: null),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);
      await notifier.loadMore();

      expect(repo.cursors, [null, 'c1']);
      expect(_ids(notifier.state), ['a', 'b']);
      expect(_success(notifier.state)!.hasMore, isFalse);
    });

    test('loadMore is a no-op when there is no next page', () async {
      final repo = _FakeRepository();
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);
      await notifier.loadMore();

      expect(repo.pageCalls, 1, reason: 'nextCursor was null, so no fetch');
    });

    test('loadMore before any load does nothing', () async {
      final repo = _FakeRepository();
      final notifier = ReelImportNotifier(repo);

      await notifier.loadMore();

      expect(repo.pageCalls, 0);
    });

    test('a failed loadMore keeps the already-loaded reels', () async {
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(reels: [_reel('a')], nextCursor: 'c1'),
          ),
          networkLeft(const NetworkExceptions.noInternetConnection()),
        ],
      );
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);
      await notifier.loadMore();

      expect(
        _ids(notifier.state),
        ['a'],
        reason: 'a failed page must not wipe what is already shown',
      );
      expect(_success(notifier.state)!.freshness, const ContentFreshness());
    });

    test('a failed first load surfaces the message', () async {
      final repo = _FakeRepository(
        pages: [networkLeft(const NetworkExceptions.noInternetConnection())],
      );
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);

      expect(
        notifier.state.maybeWhen(
          loadFailure: NetworkExceptions.getMessage,
          orElse: () => null,
        ),
        'No internet connection.',
      );
    });

    test('reloading resets pagination rather than appending', () async {
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(reels: [_reel('a')], nextCursor: 'c1'),
          ),
          networkRight(
            ImportableReelsResult(reels: [_reel('b')], nextCursor: null),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);
      await notifier.load(SocialPlatform.instagram);

      expect(repo.cursors, [null, null], reason: 'second load starts fresh');
      expect(_ids(notifier.state), ['b']);
    });

    test('a slow response for a replaced platform is dropped', () async {
      final gate = Completer<void>();
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(reels: [_reel('ig')], nextCursor: null),
          ),
          networkRight(
            ImportableReelsResult(reels: [_reel('tt')], nextCursor: null),
          ),
        ],
        gates: {0: gate},
      );
      final notifier = ReelImportNotifier(repo);

      final slow = notifier.load(SocialPlatform.instagram);
      await notifier.load(SocialPlatform.tiktok);
      gate.complete();
      await slow;

      expect(_ids(notifier.state), ['tt']);
    });
  });

  group('ReelImportNotifier freshness', () {
    test('load carries the page freshness into the success state', () async {
      final freshness = _rateLimitedUntil(_now.add(const Duration(hours: 1)));
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(
              reels: [_reel('a')],
              nextCursor: null,
              freshness: freshness,
            ),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);

      expect(repo.refreshes, [false]);
      expect(_success(notifier.state)!.freshness, freshness);
    });

    test('loadMore continues saved posts with an sm1 cursor', () async {
      const saved = ContentFreshness(servedFromCache: true);
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(
              reels: [_reel('a')],
              nextCursor: 'sm1.eyJrIjoiYSJ9',
              freshness: saved,
            ),
          ),
          networkRight(
            ImportableReelsResult(
              reels: [_reel('b')],
              nextCursor: null,
              freshness: saved,
            ),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);
      await notifier.loadMore();

      expect(repo.cursors, [null, 'sm1.eyJrIjoiYSJ9']);
      expect(repo.refreshes, [false, false]);
      final success = _success(notifier.state)!;
      expect(success.reels.map((r) => r.id), ['a', 'b']);
      expect(success.hasMore, isFalse);
      expect(success.freshness.servedFromCache, isTrue);
    });

    test('a throttled loadMore keeps the list and records why', () async {
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(reels: [_reel('a')], nextCursor: 'live-2'),
          ),
          networkLeft(
            const NetworkExceptions.validation(
              code: 'RATE_LIMITED',
              message: 'Instagram is limiting requests right now.',
            ),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);
      await notifier.loadMore();

      final success = _success(notifier.state)!;
      expect(success.reels.map((r) => r.id), ['a']);
      expect(success.hasMore, isTrue, reason: 'the page can be retried');
      expect(
        success.freshness.providerStatus?.issue,
        ContentProviderIssue.rateLimited,
      );
    });

    test('refresh asks for a live page and replaces the list', () async {
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(
              reels: [_reel('saved')],
              nextCursor: 'sm1.x',
              freshness: const ContentFreshness(servedFromCache: true),
            ),
          ),
          networkRight(
            ImportableReelsResult(
              reels: [_reel('live')],
              nextCursor: 'provider-2',
              freshness: ContentFreshness(fetchedUtc: _now),
            ),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo, clock: () => _now);

      await notifier.load(SocialPlatform.instagram);
      await notifier.refresh();

      expect(repo.refreshes, [false, true]);
      expect(repo.cursors, [null, null]);
      final success = _success(notifier.state)!;
      expect(success.reels.map((r) => r.id), ['live']);
      expect(success.hasMore, isTrue);
      expect(success.freshness.servedFromCache, isFalse);
      expect(success.blockedUntil, isNull);

      await notifier.loadMore();
      expect(repo.cursors.last, 'provider-2');
    });

    test('refresh is skipped while retryAfterUtc is still ahead', () async {
      final retryAfter = _now.add(const Duration(minutes: 30));
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(
              reels: [_reel('saved')],
              nextCursor: null,
              freshness: _rateLimitedUntil(retryAfter),
            ),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo, clock: () => _now);

      await notifier.load(SocialPlatform.instagram);
      await notifier.refresh();

      expect(repo.pageCalls, 1, reason: 'no call before retryAfterUtc');
      final success = _success(notifier.state)!;
      expect(success.reels.map((r) => r.id), ['saved']);
      expect(success.blockedUntil, retryAfter);
      expect(success.freshness, _rateLimitedUntil(retryAfter));
    });

    test('refresh goes ahead once retryAfterUtc has passed', () async {
      var now = _now;
      final retryAfter = _now.add(const Duration(minutes: 30));
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(
              reels: [_reel('saved')],
              nextCursor: null,
              freshness: _rateLimitedUntil(retryAfter),
            ),
          ),
          networkRight(
            ImportableReelsResult(reels: [_reel('live')], nextCursor: null),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo, clock: () => now);

      await notifier.load(SocialPlatform.instagram);
      await notifier.refresh();
      expect(_success(notifier.state)!.blockedUntil, retryAfter);

      now = retryAfter.add(const Duration(seconds: 1));
      await notifier.refresh();

      expect(repo.refreshes, [false, true]);
      final success = _success(notifier.state)!;
      expect(success.reels.map((r) => r.id), ['live']);
      expect(success.blockedUntil, isNull, reason: 'notice clears on retry');
      expect(success.freshness.providerStatus, isNull);
    });

    test('a failed refresh keeps the list and reports the failure', () async {
      const failure = NetworkExceptions.validation(
        code: 'PROVIDER_UNAVAILABLE',
      );
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(reels: [_reel('a')], nextCursor: null),
          ),
          networkLeft(failure),
        ],
      );
      final notifier = ReelImportNotifier(repo, clock: () => _now);

      await notifier.load(SocialPlatform.instagram);
      await notifier.refresh();

      final success = _success(notifier.state)!;
      expect(success.reels.map((r) => r.id), ['a']);
      expect(success.refreshFailure, failure);
      expect(
        success.freshness.providerStatus?.issue,
        ContentProviderIssue.unavailable,
      );
    });

    test('a refresh that finds no connection shows not connected', () async {
      final repo = _FakeRepository(
        pages: [
          networkRight(
            ImportableReelsResult(reels: [_reel('a')], nextCursor: null),
          ),
          networkLeft(const NetworkExceptions.notFound()),
        ],
      );
      final notifier = ReelImportNotifier(repo, clock: () => _now);

      await notifier.load(SocialPlatform.instagram);
      await notifier.refresh();

      expect(
        notifier.state.maybeWhen(
          loadFailure: (f) => f.isNotFound,
          orElse: () => false,
        ),
        isTrue,
      );
    });

    test('refresh with nothing shown loads with refresh', () async {
      final repo = _FakeRepository(
        pages: [
          networkLeft(
            const NetworkExceptions.validation(code: 'PROVIDER_UNAVAILABLE'),
          ),
          networkRight(
            ImportableReelsResult(reels: [_reel('a')], nextCursor: null),
          ),
        ],
      );
      final notifier = ReelImportNotifier(repo, clock: () => _now);

      await notifier.load(SocialPlatform.instagram);
      await notifier.refresh();

      expect(repo.refreshes, [false, true]);
      expect(_ids(notifier.state), ['a']);
    });

    test('refresh before any load does nothing', () async {
      final repo = _FakeRepository();
      final notifier = ReelImportNotifier(repo, clock: () => _now);

      await notifier.refresh();

      expect(repo.pageCalls, 0);
    });
  });
}
