import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/datasources/feed_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/models/feed_post_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/repositories/feed_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/feed_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

import 'social_feed_fakes.dart' show FakeFeedRepository;

// Likes on the friend feed / Community home: the request the server accepts,
// the viewer's own like read back after a refresh, and the optimistic heart
// that must neither lie about a failed like nor be undone by a refresh.

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(dio: Dio());

  String? postUri;
  dynamic postData;
  Options? postOptions;
  String? deleteUri;
  dynamic deleteData;

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    postOptions = options;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> authDelete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    deleteUri = uri;
    deleteData = data;
    return null;
  }
}

/// A feed whose server state ([posts]) and timing (the gates) each test sets.
/// Extends the shared fake so the rest of [FeedRepository] stays covered.
class _ScriptedFeedRepository extends FakeFeedRepository {
  _ScriptedFeedRepository(List<FeedPost> page) : super(posts: page);

  /// When set, getFeed answers only once this completes.
  Completer<void>? feedGate;

  /// When set, like/unlike answer with this instead of [reactionResult].
  Completer<Either<NetworkExceptions, Unit>>? reactionGate;

  Either<NetworkExceptions, Unit> reactionResult = right(unit);

  /// Snapshots [posts] when the request is made, as a server would.
  @override
  Future<Either<NetworkExceptions, PagedResult<FeedPost>>> getFeed({
    int limit = 20,
    String? cursor,
  }) async {
    final snapshot = posts;
    final gate = feedGate;
    if (gate != null) await gate.future;
    return right(
      PagedResult<FeedPost>(
        items: snapshot,
        totalCount: snapshot.length,
        pageSize: limit,
        hasMore: false,
      ),
    );
  }

  @override
  Future<Either<NetworkExceptions, Unit>> likePost(String postId) async {
    likedIds.add(postId);
    final gate = reactionGate;
    return gate != null ? gate.future : reactionResult;
  }

  @override
  Future<Either<NetworkExceptions, Unit>> unlikePost(String postId) async {
    unlikedIds.add(postId);
    final gate = reactionGate;
    return gate != null ? gate.future : reactionResult;
  }
}

FeedPost _post({bool isLiked = false, int likeCount = 12}) => FeedPost(
  id: 'post-1',
  userId: 'author-1',
  userName: 'Asha Gurung',
  userAvatarUrl: '',
  content: 'Loving this jacket',
  images: const [],
  taggedProducts: const [],
  likeCount: likeCount,
  commentCount: 0,
  shareCount: 0,
  isLiked: isLiked,
  createdAt: DateTime.utc(2026, 10, 7),
);

Future<FeedNotifier> _loadedFeed(_ScriptedFeedRepository repository) async {
  final notifier = FeedNotifier(repository);
  await pumpEventQueue();
  return notifier;
}

FeedPost _shown(FeedNotifier notifier) => notifier.state.maybeWhen(
  loadSuccess: (posts, _, _) => posts.single,
  orElse: () => throw StateError('feed is not loaded'),
);

void main() {
  group('FeedRemoteDataSource', () {
    test('a like posts the Like reaction type in the body', () async {
      final api = _RecordingApiClient();

      await FeedRemoteDataSource(apiClient: api).likePost('post-1', 'key-1');

      expect(api.postUri, '/v1/reactions/posts/post-1');
      expect(api.postData, {'type': 1});
      expect(api.postOptions?.headers?['Idempotency-Key'], 'key-1');
    });

    test('an unlike deletes the reaction', () async {
      final api = _RecordingApiClient();

      await FeedRemoteDataSource(apiClient: api).unlikePost('post-1', 'key-2');

      expect(api.deleteUri, '/v1/reactions/posts/post-1');
    });
  });

  group('FeedPostDto.fromPostJson', () {
    Map<String, dynamic> json(Map<String, dynamic> extra) => {
      'id': 'post-1',
      'authorAccountId': 'author-1',
      'body': 'Loving this jacket',
      'reactionCount': 5,
      'createdUtc': '2026-10-07T00:00:00Z',
      ...extra,
    };

    test("reads the viewer's own like from isLiked", () {
      final dto = FeedPostDto.fromPostJson(json({'isLiked': true}));

      expect(dto.isLiked, isTrue);
      expect(dto.likeCount, 5);
    });

    test('treats any viewer reaction as liked', () {
      final dto = FeedPostDto.fromPostJson(json({'viewerReaction': 2}));

      expect(dto.isLiked, isTrue);
    });

    test('is unliked when the viewer has not reacted', () {
      final dto = FeedPostDto.fromPostJson(
        json({'isLiked': false, 'viewerReaction': null}),
      );

      expect(dto.isLiked, isFalse);
    });
  });

  group('FeedNotifier likes', () {
    test('a like shows at once and is sent to the server', () async {
      final repository = _ScriptedFeedRepository([_post()]);
      final notifier = await _loadedFeed(repository);

      final result = await notifier.likePost('post-1');

      expect(result.isRight(), isTrue);
      expect(repository.likedIds, ['post-1']);
      expect(_shown(notifier).isLiked, isTrue);
      expect(_shown(notifier).likeCount, 13);
    });

    test('a refused like is undone and reported', () async {
      final repository = _ScriptedFeedRepository([_post()])
        ..reactionResult = left(const NetworkExceptions.unexpectedError());
      final notifier = await _loadedFeed(repository);

      final result = await notifier.likePost('post-1');

      expect(result.isLeft(), isTrue);
      expect(_shown(notifier).isLiked, isFalse);
      expect(_shown(notifier).likeCount, 12);
    });

    test('a refused unlike puts the like back', () async {
      final repository = _ScriptedFeedRepository([
        _post(isLiked: true, likeCount: 13),
      ])..reactionResult = left(const NetworkExceptions.unexpectedError());
      final notifier = await _loadedFeed(repository);

      final result = await notifier.unlikePost('post-1');

      expect(result.isLeft(), isTrue);
      expect(repository.unlikedIds, ['post-1']);
      expect(_shown(notifier).isLiked, isTrue);
      expect(_shown(notifier).likeCount, 13);
    });

    test('a refresh landing while the like is in flight keeps it', () async {
      final repository = _ScriptedFeedRepository([_post()]);
      final notifier = await _loadedFeed(repository);
      repository.reactionGate = Completer();

      final like = notifier.likePost('post-1');
      await notifier.refresh();

      // The server has not stored the like yet, so the page says unliked.
      expect(_shown(notifier).isLiked, isTrue);
      expect(_shown(notifier).likeCount, 13);

      repository.reactionGate!.complete(right(unit));
      await like;
      expect(_shown(notifier).isLiked, isTrue);
      expect(_shown(notifier).likeCount, 13);
    });

    test(
      'a refresh requested before the like was stored cannot undo it',
      () async {
        final repository = _ScriptedFeedRepository([_post()]);
        final notifier = await _loadedFeed(repository);
        repository.feedGate = Completer();

        final refresh = notifier.refresh(); // snapshots the unliked post
        await notifier.likePost('post-1'); // stored before the page lands
        repository.feedGate!.complete();
        await refresh;

        expect(_shown(notifier).isLiked, isTrue);
        expect(_shown(notifier).likeCount, 13);
      },
    );

    test(
      'a refresh requested after the like was stored is the truth',
      () async {
        final repository = _ScriptedFeedRepository([_post()]);
        final notifier = await _loadedFeed(repository);
        await notifier.likePost('post-1');

        // The server counted it once — no second +1 from the old tap.
        repository.posts = [_post(isLiked: true, likeCount: 13)];
        await notifier.refresh();
        expect(_shown(notifier).isLiked, isTrue);
        expect(_shown(notifier).likeCount, 13);

        // Later changes elsewhere (another device unliked) win again.
        repository.posts = [_post()];
        await notifier.refresh();
        expect(_shown(notifier).isLiked, isFalse);
        expect(_shown(notifier).likeCount, 12);
      },
    );

    test('a second tap while the first is in flight is not sent', () async {
      final repository = _ScriptedFeedRepository([_post()]);
      final notifier = await _loadedFeed(repository);
      repository.reactionGate = Completer();

      final like = notifier.likePost('post-1');
      final unlike = await notifier.unlikePost('post-1');

      expect(unlike.isRight(), isTrue);
      expect(repository.unlikedIds, isEmpty);
      expect(_shown(notifier).isLiked, isTrue);

      repository.reactionGate!.complete(right(unit));
      await like;
      expect(repository.likedIds, ['post-1']);
    });

    test('a like is matched by post id after the list shifts', () async {
      final other = _post().copyWith(id: 'post-0', likeCount: 1);
      final repository = _ScriptedFeedRepository([_post()]);
      final notifier = await _loadedFeed(repository);
      repository.reactionGate = Completer();

      final like = notifier.likePost('post-1');
      repository.posts = [other, _post()];
      await notifier.refresh();
      repository.reactionGate!.complete(
        left(const NetworkExceptions.unexpectedError()),
      );
      await like;

      final posts = notifier.state.maybeWhen(
        loadSuccess: (posts, _, _) => posts,
        orElse: () => const <FeedPost>[],
      );
      expect(posts.map((p) => (p.id, p.isLiked, p.likeCount)), [
        ('post-0', false, 1),
        ('post-1', false, 12),
      ]);
    });
  });
}
