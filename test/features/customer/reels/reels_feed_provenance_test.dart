import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/feed_provenance.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';

class _FeedApiClient extends ApiClient {
  _FeedApiClient(this.body) : super(dio: Dio());

  final Map<String, dynamic> body;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => body;
}

Map<String, dynamic> _item({
  required String id,
  required Object? slotKind,
  Object? score,
}) => {
  'kind': 'Reel',
  'slotKind': slotKind,
  'score': score,
  'reel': {'reelId': id, 'externalUrl': 'https://example.test/$id'},
};

void main() {
  test('slotKind and score are read off the feed item envelope', () async {
    final source = ReelsRemoteDataSource(
      apiClient: _FeedApiClient({
        'items': [
          _item(id: 'r1', slotKind: 'Popular', score: 9.5),
          _item(id: 'r2', slotKind: 'NewIn'),
          _item(id: 'r3', slotKind: 'Personalized', score: 0.42),
        ],
        'nextCursor': null,
      }),
    );

    final page = await source.getReelsFeed(limit: 10);

    expect(page.reels.map((r) => r.id), ['r1', 'r2', 'r3']);
    expect(page.reels[0].provenance?.kind, FeedSlotKind.popular);
    expect(page.reels[1].provenance?.kind, FeedSlotKind.newIn);
    expect(page.reels[2].provenance?.kind, FeedSlotKind.personalized);
  });

  test('an unscored item gets no rank, nor the last one', () async {
    final source = ReelsRemoteDataSource(
      apiClient: _FeedApiClient({
        'items': [
          _item(id: 'r1', slotKind: 'NewIn'),
          _item(id: 'r2', slotKind: 'Popular', score: 3),
          _item(id: 'r3', slotKind: 'Popular', score: 8),
        ],
      }),
    );

    final page = await source.getReelsFeed(limit: 10);

    expect(page.reels[0].provenance?.score, isNull);
    expect(page.reels[0].provenance?.rank, isNull);
    expect(page.reels[0].provenance?.rankLabel, isNull);
    expect(page.reels[1].provenance?.rank, 2);
    expect(page.reels[2].provenance?.rank, 1);
  });

  test('an unknown slot kind never becomes personalized', () async {
    final source = ReelsRemoteDataSource(
      apiClient: _FeedApiClient({
        'items': [
          _item(id: 'r1', slotKind: 'SponsoredPick'),
          _item(id: 'r2', slotKind: null),
        ],
      }),
    );

    final page = await source.getReelsFeed(limit: 10);

    for (final reel in page.reels) {
      expect(reel.provenance?.kind, FeedSlotKind.unknown);
      expect(reel.provenance?.kind.isPersonal, isFalse);
    }
  });

  test('a non-reel item is dropped without shifting provenance', () async {
    final source = ReelsRemoteDataSource(
      apiClient: _FeedApiClient({
        'items': [
          {'kind': 'Product', 'slotKind': 'Personalized', 'score': 0.9},
          _item(id: 'r1', slotKind: 'Popular', score: 4),
        ],
      }),
    );

    final page = await source.getReelsFeed(limit: 10);

    expect(page.reels, hasLength(1));
    expect(page.reels.single.id, 'r1');
    expect(page.reels.single.provenance?.kind, FeedSlotKind.popular);
    // The product's score did not leak onto the reel's rank.
    expect(page.reels.single.provenance?.rank, 1);
  });

  test('reel detail carries no provenance', () async {
    final source = ReelsRemoteDataSource(
      apiClient: _FeedApiClient({
        'id': 'r9',
        'sourceUrl': 'https://example.test/r9',
      }),
    );

    final reel = await source.getReelDetail('r9');

    expect(reel.provenance, isNull);
  });
}
