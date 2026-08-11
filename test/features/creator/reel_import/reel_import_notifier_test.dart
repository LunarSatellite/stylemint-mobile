import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

class _FakeRepository implements ReelImportRepository {
  _FakeRepository({this.pages});

  /// Consumed in order, one per getImportableReels call.
  List<NetworkEither<ImportableReelsResult>>? pages;

  final List<String?> cursors = [];
  int pageCalls = 0;

  @override
  Future<NetworkEither<ImportableReelsResult>> getImportableReels(
    SocialPlatform platform, {
    String? cursor,
  }) async {
    cursors.add(cursor);
    final page = pages != null && pageCalls < pages!.length
        ? pages![pageCalls]
        : networkRight(
            ImportableReelsResult(reels: [_reel('r$pageCalls')], nextCursor: null),
          );
    pageCalls++;
    return page;
  }

  @override
  Future<NetworkEither<ImportedReel>> importReel(ImportableReel reel) async =>
      networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<List<TaggedProductForImport>>> searchProducts(
    String query,
  ) async =>
      networkRight(const []);

  @override
  Future<NetworkEither<List<TaggedProductForImport>>> getSuggestedProducts({
    required SocialPlatform platform,
    required String externalId,
  }) async =>
      networkRight(const []);

  @override
  Future<NetworkEither<Unit>> publishReel({required String reelId}) async =>
      networkRight(unit);

  @override
  Future<NetworkEither<Unit>> tagProduct({
    required String reelId,
    required String productId,
  }) async =>
      networkRight(unit);

  @override
  Future<NetworkEither<List<ImportedReel>>> getImportHistory({
    int pageSize = 20,
    String? cursor,
  }) async =>
      networkRight(const []);
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

void main() {
  group('ReelImportNotifier', () {
    test('load populates reels and reports no more pages when cursor is null',
        () async {
      final notifier = ReelImportNotifier(_FakeRepository());

      await notifier.load(SocialPlatform.instagram);

      expect(
        notifier.state.maybeWhen(
          loadSuccess: (reels, hasMore, _) => '${reels.length}:$hasMore',
          orElse: () => 'none',
        ),
        '1:false',
      );
    });

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

      expect(
        notifier.state.maybeWhen(
          loadSuccess: (_, hasMore, _) => hasMore,
          orElse: () => false,
        ),
        isTrue,
      );
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
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (reels, hasMore, _) => '${reels.length}:$hasMore',
          orElse: () => 'none',
        ),
        '2:false',
      );
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
        notifier.state.maybeWhen(
          loadSuccess: (reels, _, _) => reels.length,
          orElse: () => -1,
        ),
        1,
        reason: 'a failed page must not wipe what is already shown',
      );
    });

    test('a failed first load surfaces the message', () async {
      final repo = _FakeRepository(
        pages: [networkLeft(const NetworkExceptions.noInternetConnection())],
      );
      final notifier = ReelImportNotifier(repo);

      await notifier.load(SocialPlatform.instagram);

      expect(
        notifier.state.maybeWhen(
          loadFailure: (f) => NetworkExceptions.getMessage(f),
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
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (reels, _, _) => reels.length,
          orElse: () => -1,
        ),
        1,
      );
    });
  });
}
