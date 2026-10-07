import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/repositories/stories_repository.dart';

part 'stories_notifier.freezed.dart';

@freezed
sealed class StoriesState with _$StoriesState {
  const StoriesState._();

  const factory StoriesState.initial() = _StoriesInitial;
  const factory StoriesState.loadInProgress() = _StoriesLoadInProgress;
  const factory StoriesState.loadSuccess(List<StoryGroup> groups) =
      _StoriesLoadSuccess;
  const factory StoriesState.loadFailure(NetworkExceptions failure) =
      _StoriesLoadFailure;
}

/// The signed-in viewer's name and photo, as the stories notifier needs them.
typedef StoryViewerIdentity = ({String displayName, String avatarUrl});

class StoriesNotifier extends StateNotifier<StoriesState> {
  /// [readViewer] returns the signed-in viewer at call time; it fills the
  /// author on a story the viewer just posted (see [createStory]).
  StoriesNotifier(
    this._repository, {
    StoryViewerIdentity? Function()? readViewer,
  }) : _readViewer = readViewer ?? _noViewer,
       super(const StoriesState.initial()) {
    unawaited(loadStoryGroups());
  }

  final StoriesRepository _repository;
  final StoryViewerIdentity? Function() _readViewer;

  static StoryViewerIdentity? _noViewer() => null;

  List<StoryGroup>? get _loadedGroups =>
      state.maybeWhen(loadSuccess: (groups) => groups, orElse: () => null);

  /// Loads the tray. Once it has loaded, a reload keeps the current groups on
  /// screen — and keeps them if the reload fails — so the tray over a reel
  /// never blinks out while it refreshes after a post or a pull-to-refresh.
  Future<void> loadStoryGroups() async {
    final current = _loadedGroups;
    if (current == null) state = const StoriesState.loadInProgress();
    final either = await _repository.getStoryGroups();
    if (!mounted) return;
    either.fold(
      (failure) {
        if (current == null) state = StoriesState.loadFailure(failure);
      },
      (groups) => state = StoriesState.loadSuccess(groups),
    );
  }

  Future<Either<NetworkExceptions, List<Story>>> loadStories(
    String userId,
  ) async {
    return _repository.getStories(userId);
  }

  /// Marks a story seen. The ring greys out straight away; the server call is
  /// fire-and-forget (it is idempotent, and silent for the author's own).
  Future<void> viewStory(String storyId) async {
    final groups = _loadedGroups;
    if (groups != null) {
      state = StoriesState.loadSuccess(
        groups
            .map((group) {
              if (!group.stories.any((s) => s.id == storyId && !s.hasWatched)) {
                return group;
              }
              final stories = group.stories
                  .map((s) => s.id == storyId ? s.copyWith(hasWatched: true) : s)
                  .toList(growable: false);
              return group.copyWith(
                stories: stories,
                hasUnwatched: stories.any((s) => !s.hasWatched),
              );
            })
            .toList(growable: false),
      );
    }
    await _repository.viewStory(storyId);
  }

  Future<Either<NetworkExceptions, Story>> createStory({
    required String mediaFile,
    String? caption,
    List<String>? taggedProductIds,
  }) async {
    final either = (await _repository.createStory(
      mediaFile: mediaFile,
      caption: caption,
      taggedProductIds: taggedProductIds,
    )).map(_asViewersStory);
    either.map((_) {
      unawaited(loadStoryGroups());
    });
    return either;
  }

  /// The create response is the viewer's own story. If it came without the
  /// author's name or photo, take them from the signed-in viewer rather than
  /// hand back a "StyleMint user" story.
  Story _asViewersStory(Story story) {
    final viewer = _readViewer();
    if (viewer == null) return story;
    final name = story.userName.trim();
    final hasName = name.isNotEmpty && name != unknownStoryAuthorName;
    return story.copyWith(
      userName: hasName || viewer.displayName.trim().isEmpty
          ? null
          : viewer.displayName.trim(),
      userAvatarUrl:
          story.userAvatarUrl.trim().isNotEmpty || viewer.avatarUrl.isEmpty
          ? null
          : viewer.avatarUrl,
    );
  }

  /// Deletes one of the caller's stories. On success it leaves the tray at
  /// once (an author with none left drops out of it), then the tray reloads.
  Future<Either<NetworkExceptions, Unit>> deleteStory(String storyId) async {
    final either = await _repository.deleteStory(storyId);
    if (either.isRight() && mounted) {
      final groups = _loadedGroups;
      if (groups != null) {
        state = StoriesState.loadSuccess(
          groups
              .map(
                (group) => group.copyWith(
                  stories: group.stories
                      .where((s) => s.id != storyId)
                      .toList(growable: false),
                ),
              )
              .where((group) => group.stories.isNotEmpty)
              .toList(growable: false),
        );
      }
      unawaited(loadStoryGroups());
    }
    return either;
  }
}
