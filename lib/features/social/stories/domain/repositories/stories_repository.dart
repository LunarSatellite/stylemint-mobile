import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';

abstract interface class StoriesRepository {
  Future<Either<NetworkExceptions, List<StoryGroup>>> getStoryGroups();

  Future<Either<NetworkExceptions, List<Story>>> getStories(String userId);

  Future<Either<NetworkExceptions, Story>> createStory({
    required String mediaFile,
    String? caption,
    List<String>? taggedProductIds,
  });

  Future<Either<NetworkExceptions, Unit>> viewStory(String storyId);

  Future<Either<NetworkExceptions, Unit>> deleteStory(String storyId);
}
