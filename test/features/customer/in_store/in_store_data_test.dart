import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/datasources/in_store_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/models/product_reel_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/repositories/in_store_repository_impl.dart';

import '../../codes/support/recording_api_client.dart';

/// A backend `ReelDto` as `GET /v1/public/reels/by-product/{id}` sends it.
Map<String, dynamic> _reelJson({String id = 'r-1'}) => <String, dynamic>{
  'id': id,
  'creatorAccountId': 'a-1',
  'sourcePlatform': 'YouTubeShorts',
  'sourceUrl': 'https://www.youtube.com/shorts/abc123',
  'externalId': 'abc123',
  'durationSeconds': 21,
  'caption': 'Linen for summer',
  'thumbnailCdnUrl': 'https://cdn.stylemint.app/thumbs/r-1.jpg',
  'videoCdnUrl': null,
  'state': 2,
  'likesSnapshot': 40,
  'styleMintLikeCount': 2,
  'likeCount': 42,
  'creatorDisplayName': 'Asha Rai',
  'creatorAvatarUrl': null,
};

class _MockRemote extends Mock implements InStoreRemoteDataSource {}

void main() {
  group('ProductReelDto', () {
    test('maps the public ReelDto', () {
      final reel = ProductReelDto.fromJson(_reelJson()).toDomain();

      expect(reel.id, 'r-1');
      expect(reel.permalink, 'https://www.youtube.com/shorts/abc123');
      expect(reel.platform, SocialPlatform.youtube);
      expect(reel.platformVideoId, 'abc123');
      expect(reel.thumbnailUrl, 'https://cdn.stylemint.app/thumbs/r-1.jpg');
      expect(reel.videoUrl, isNull);
      expect(reel.creatorName, 'Asha Rai');
      expect(reel.caption, 'Linen for summer');
      expect(reel.likeCount, 42);
    });

    test('accepts the feed card spellings too', () {
      final reel = ProductReelDto.fromJson(<String, dynamic>{
        'reelId': 'r-2',
        'sourcePlatform': 'Instagram',
        'externalUrl': 'https://www.instagram.com/reel/xyz/',
        'thumbnailUrl': 'https://cdn.stylemint.app/thumbs/r-2.jpg',
        'creatorHandle': 'mint.studio',
      }).toDomain();

      expect(reel.id, 'r-2');
      expect(reel.platform, SocialPlatform.instagram);
      expect(reel.permalink, 'https://www.instagram.com/reel/xyz/');
      expect(reel.thumbnailUrl, 'https://cdn.stylemint.app/thumbs/r-2.jpg');
      expect(reel.creatorName, 'mint.studio');
      expect(reel.likeCount, 0);
    });

    test('pages drop reels without an id', () {
      final reels = ProductReelDto.listFromPage(<String, dynamic>{
        'items': [
          _reelJson(),
          <String, dynamic>{'caption': 'no id'},
        ],
        'nextCursor': null,
      });

      expect(reels.single.id, 'r-1');
      expect(ProductReelDto.listFromPage(null), isEmpty);
    });
  });

  test('the datasource asks the public by-product endpoint', () async {
    final api = RecordingApiClient(
      (_) => <String, dynamic>{
        'items': [_reelJson(), _reelJson(id: 'r-2')],
        'totalCount': 2,
        'pageSize': 20,
      },
    );

    final reels = await InStoreRemoteDataSource(
      apiClient: api,
    ).getProductReels('p-1');

    expect(api.last.method, 'GET');
    expect(api.last.uri, '/v1/public/reels/by-product/p-1');
    expect(api.last.query, <String, dynamic>{'pageSize': 20});
    expect(reels.map((r) => r.id), ['r-1', 'r-2']);
  });

  group('InStoreRepositoryImpl', () {
    late _MockRemote remote;

    setUp(() => remote = _MockRemote());

    InStoreRepositoryImpl repo({bool connected = true}) =>
        InStoreRepositoryImpl(
          remoteDataSource: remote,
          networkInfo: FakeNetworkInfo(connected: connected),
        );

    test('maps reels to the domain', () async {
      when(
        () => remote.getProductReels('p-1'),
      ).thenAnswer((_) async => [ProductReelDto.fromJson(_reelJson())]);

      final result = await repo().getProductReels('p-1');

      expect(result.getRight().toNullable()!.single.creatorName, 'Asha Rai');
    });

    test('an unknown product is notFound; offline skips the API', () async {
      when(() => remote.getProductReels('gone')).thenThrow(dioError(404));

      expect(
        (await repo().getProductReels('gone')).getLeft().toNullable(),
        const NetworkExceptions.notFound(),
      );

      final offline = await repo(connected: false).getProductReels('p-1');
      expect(
        offline.getLeft().toNullable(),
        const NetworkExceptions.noInternetConnection(),
      );
      verifyNever(() => remote.getProductReels('p-1'));
    });
  });
}
