import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/reel_product_tag.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/repositories/creator_reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/notifiers/creator_reel_actions_notifier.dart';

class _FakeRepository implements CreatorReelsRepository {
  _FakeRepository({this.unitResult, this.tagResult});

  NetworkEither<Unit>? unitResult;
  NetworkEither<ReelProductTag>? tagResult;

  final List<String> calls = [];

  @override
  Future<NetworkEither<Unit>> publishReel(String reelId) async {
    calls.add('publish:$reelId');
    return unitResult ?? networkRight(unit);
  }

  @override
  Future<NetworkEither<Unit>> unpublishReel(String reelId) async {
    calls.add('unpublish:$reelId');
    return unitResult ?? networkRight(unit);
  }

  @override
  Future<NetworkEither<Unit>> untagProduct(
    String reelId,
    String taggedProductId,
  ) async {
    calls.add('untag:$reelId:$taggedProductId');
    return unitResult ?? networkRight(unit);
  }

  @override
  Future<NetworkEither<ReelProductTag>> tagProduct(
    String reelId, {
    required String productId,
    required double overlayPositionX,
    required double overlayPositionY,
  }) async {
    calls.add('tag:$reelId:$productId:$overlayPositionX,$overlayPositionY');
    return tagResult ?? networkRight(_tag());
  }

  @override
  Future<NetworkEither<CreatorReelDetail>> getReelDetail(String reelId) async =>
      networkLeft(const NetworkExceptions.unexpectedError());

  @override
  Future<NetworkEither<List<CreatorReelSummary>>> listCreatorReels({
    String sortBy = 'publishedAt',
    String order = 'desc',
    int limit = 6,
  }) async =>
      networkRight(const <CreatorReelSummary>[]);

  @override
  Future<NetworkEither<List<ReelProductTag>>> listTaggedProducts(
    String reelId,
  ) async =>
      networkRight(const <ReelProductTag>[]);
}

ReelProductTag _tag() => const ReelProductTag(
      id: 'tag-1',
      reelId: 'reel-1',
      productId: 'prod-1',
      commissionPercent: 10,
      priceLabel: 'Rs 1200',
      commissionPerSaleLabel: 'Rs 120',
      overlayPositionX: 0.5,
      overlayPositionY: 0.5,
    );

void main() {
  group('CreatorReelActionsNotifier', () {
    test('starts idle', () {
      final notifier = CreatorReelActionsNotifier(_FakeRepository());
      expect(notifier.state, isA<CreatorReelActionIdle>());
    });

    test('publish succeeds and reports a success message', () async {
      final repo = _FakeRepository();
      final notifier = CreatorReelActionsNotifier(repo);

      final ok = await notifier.publish('reel-1');

      expect(ok, isTrue);
      expect(repo.calls.single, 'publish:reel-1');
      expect(notifier.state, isA<CreatorReelActionSucceeded>());
      expect(
        (notifier.state as CreatorReelActionSucceeded).message,
        'Reel published.',
      );
    });

    test('unpublish routes to the unpublish call', () async {
      final repo = _FakeRepository();
      final notifier = CreatorReelActionsNotifier(repo);

      await notifier.unpublish('reel-1');

      expect(repo.calls.single, 'unpublish:reel-1');
    });

    test('failure returns false and surfaces the repository message',
        () async {
      final repo = _FakeRepository(
        unitResult: networkLeft(const NetworkExceptions.noInternetConnection()),
      );
      final notifier = CreatorReelActionsNotifier(repo);

      final ok = await notifier.publish('reel-1');

      expect(ok, isFalse);
      expect(notifier.state, isA<CreatorReelActionFailed>());
      expect(
        (notifier.state as CreatorReelActionFailed).message,
        'No internet connection.',
      );
    });

    test('tagProduct defaults the overlay to the centre of the frame',
        () async {
      final repo = _FakeRepository();
      final notifier = CreatorReelActionsNotifier(repo);

      await notifier.tagProduct('reel-1', productId: 'prod-1');

      expect(repo.calls.single, 'tag:reel-1:prod-1:0.5,0.5');
    });

    test('untagProduct passes the tag id, not the product id', () async {
      final repo = _FakeRepository();
      final notifier = CreatorReelActionsNotifier(repo);

      await notifier.untagProduct('reel-1', 'tag-1');

      expect(repo.calls.single, 'untag:reel-1:tag-1');
    });

    test('a second action while one is in flight is refused', () async {
      final repo = _FakeRepository();
      final notifier = CreatorReelActionsNotifier(repo);

      final first = notifier.publish('reel-1');
      final second = await notifier.publish('reel-1');

      expect(second, isFalse, reason: 'the in-flight guard should reject it');
      await first;
      expect(repo.calls, hasLength(1));
    });

    test('reset returns the notifier to idle so a snackbar does not replay',
        () async {
      final notifier = CreatorReelActionsNotifier(_FakeRepository());

      await notifier.publish('reel-1');
      expect(notifier.state, isA<CreatorReelActionSucceeded>());

      notifier.reset();
      expect(notifier.state, isA<CreatorReelActionIdle>());
    });
  });
}
