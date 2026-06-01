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
  const factory StoriesState.loadFailure(NetworkExceptions failure) = _StoriesLoadFailure;
}

class StoriesNotifier extends StateNotifier<StoriesState> {
  StoriesNotifier(this._repository) : super(const StoriesState.initial()) {
    unawaited(loadStoryGroups());
  }

  final StoriesRepository _repository;

  Future<void> loadStoryGroups() async {
    state = const StoriesState.loadInProgress();
    final either = await _repository.getStoryGroups();
    state = either.fold(
      StoriesState.loadFailure,
      StoriesState.loadSuccess,
    );
  }

  Future<Either<NetworkExceptions, List<Story>>> loadStories(String userId) async {
    return _repository.getStories(userId);
  }

  Future<void> viewStory(String storyId) async {
    await _repository.viewStory(storyId);
  }

  Future<Either<NetworkExceptions, Story>> createStory({
    required String mediaFile,
    String? caption,
    List<String>? taggedProductIds,
  }) async {
    final either = await _repository.createStory(
      mediaFile: mediaFile,
      caption: caption,
      taggedProductIds: taggedProductIds,
    );
    either.map((_) {
      unawaited(loadStoryGroups());
    });
    return either;
  }

  Future<void> deleteStory(String storyId) async {
    await _repository.deleteStory(storyId);
    unawaited(loadStoryGroups());
  }
}
