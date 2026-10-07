import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class FeedRepository {
  Future<Either<NetworkExceptions, PagedResult<FeedPost>>> getFeed({
    int limit,
    String? cursor,
  });

  /// [media] are files already staged with [uploadPostMedia]: up to
  /// [PostMediaLimits.maxPhotos] photos, or one video on its own.
  Future<Either<NetworkExceptions, FeedPost>> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
    List<UploadedPostMedia>? media,
  });

  /// Stages one picked photo/video for a post and returns its URL. Each call
  /// is one upload attempt with its own Idempotency-Key, so a retry after a
  /// failure is a fresh upload. [onProgress] reports bytes sent.
  Future<Either<NetworkExceptions, UploadedPostMedia>> uploadPostMedia({
    required String path,
    required PostMediaKind kind,
    void Function(int sent, int total)? onProgress,
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
