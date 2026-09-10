import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/models/feed_post_dto.dart';

void main() {
  test('adapts the canonical backend post shape', () {
    final dto = FeedPostDto.fromPostJson({
      'id': 'post-id',
      'authorAccountId': 'author-id',
      'body': 'A production-ready look',
      'reactionCount': 7,
      'commentCount': 3,
      'shareCount': 2,
      'createdUtc': '2026-09-11T04:30:00Z',
    });

    expect(dto.id, 'post-id');
    expect(dto.userId, 'author-id');
    expect(dto.userName, 'StyleMint user');
    expect(dto.userAvatarUrl, isEmpty);
    expect(dto.content, 'A production-ready look');
    expect(dto.likeCount, 7);
    expect(dto.commentCount, 3);
    expect(dto.shareCount, 2);
    expect(dto.createdAt, DateTime.utc(2026, 9, 11, 4, 30));
    expect(dto.images, isEmpty);
    expect(dto.taggedProducts, isEmpty);
  });
}
