import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class FeedRepository {
  Future<Either<NetworkExceptions, PagedResult<FeedPost>>> getFeed({
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, FeedPost>> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
  });

  Future<Either<NetworkExceptions, Unit>> likePost(String postId);

  Future<Either<NetworkExceptions, Unit>> unlikePost(String postId);

  Future<Either<NetworkExceptions, FeedComment>> commentOnPost(
    String postId,
    String content,
  );

  Future<Either<NetworkExceptions, PagedResult<FeedComment>>> getComments(
    String postId, {
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, Unit>> sharePost(String postId);
}
