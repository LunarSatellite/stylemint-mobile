import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/repositories/stories_repository.dart';

/// In-memory [StoriesRepository] that records what the UI asked of it.
class FakeStoriesRepository implements StoriesRepository {
  FakeStoriesRepository({List<StoryGroup> groups = const []})
    : groupsResult = right(groups);

  Either<NetworkExceptions, List<StoryGroup>> groupsResult;
  Either<NetworkExceptions, Story>? createResult;
  Either<NetworkExceptions, Unit> deleteResult = right(unit);

  int groupCalls = 0;
  final List<({String mediaFile, String? caption})> created = [];
  final List<String> viewed = [];
  final List<String> deleted = [];

  @override
  Future<Either<NetworkExceptions, List<StoryGroup>>> getStoryGroups() async {
    groupCalls++;
    return groupsResult;
  }

  @override
  Future<Either<NetworkExceptions, List<Story>>> getStories(
    String userId,
  ) async => groupsResult.map(
    (groups) => groups
        .where((g) => g.userId == userId)
        .expand((g) => g.stories)
        .toList(),
  );

  @override
  Future<Either<NetworkExceptions, Story>> createStory({
    required String mediaFile,
    String? caption,
    List<String>? taggedProductIds,
  }) async {
    created.add((mediaFile: mediaFile, caption: caption));
    return createResult ?? right(fakeStory('new', userId: 'me', caption: caption));
  }

  @override
  Future<Either<NetworkExceptions, Unit>> viewStory(String storyId) async {
    viewed.add(storyId);
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> deleteStory(String storyId) async {
    deleted.add(storyId);
    return deleteResult;
  }
}

/// A story that is still up (posted 12 hours ago). No media URL, so nothing
/// touches the network — the viewer treats it as media that failed to load.
Story fakeStory(
  String id, {
  required String userId,
  String? caption,
  bool watched = false,
  int views = 0,
}) => Story(
  id: id,
  userId: userId,
  userName: 'Friend $userId',
  userAvatarUrl: '',
  mediaUrl: '',
  mediaType: 'image',
  caption: caption,
  taggedProductIds: const [],
  expiresAt: DateTime.now().toUtc().add(const Duration(hours: 12)),
  viewCount: views,
  hasWatched: watched,
);

StoryGroup fakeGroup(String userId, List<Story> stories) => StoryGroup(
  userId: userId,
  userName: 'Friend $userId',
  userAvatarUrl: '',
  stories: stories,
  hasUnwatched: stories.any((s) => !s.hasWatched),
);
