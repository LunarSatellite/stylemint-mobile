import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/repositories/reel_studio_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

part 'reel_studio_notifier.freezed.dart';

@freezed
abstract class ReelStudioState with _$ReelStudioState {
  const ReelStudioState._();

  const factory ReelStudioState.initial() = _ReelStudioInitial;
  const factory ReelStudioState.loadInProgress() = _ReelStudioLoadInProgress;
  const factory ReelStudioState.loadSuccess({
    required List<ReelRecipe> recipes,
    required List<ReelDraft> drafts,
  }) = _ReelStudioLoadSuccess;
  const factory ReelStudioState.loadFailure(NetworkExceptions failure) =
      _ReelStudioLoadFailure;
}

@freezed
abstract class CreateDraftState with _$CreateDraftState {
  const CreateDraftState._();

  const factory CreateDraftState.editing({
    @Default('') String caption,
    @Default(<String>[]) List<String> hashtags,
    @Default(<String>[]) List<String> taggedProductIds,
    @Default(SocialPlatform.instagram) SocialPlatform platform,
  }) = _CreateDraftEditing;
  const factory CreateDraftState.saving() = _CreateDraftSaving;
  const factory CreateDraftState.saved(ReelDraft draft) = _CreateDraftSaved;
  const factory CreateDraftState.saveFailure(NetworkExceptions failure) =
      _CreateDraftSaveFailure;
}

class ReelStudioNotifier extends StateNotifier<ReelStudioState> {
  ReelStudioNotifier(this._repository)
    : super(const ReelStudioState.initial()) {
    unawaited(load());
  }

  final ReelStudioRepository _repository;

  Future<void> load() async {
    state = const ReelStudioState.loadInProgress();
    final recipesEither = await _repository.getRecipes();
    final draftsEither = await _repository.getDrafts();

    state = recipesEither.fold(
      (f) => ReelStudioState.loadFailure(f),
      (recipes) => draftsEither.fold(
        (f) => ReelStudioState.loadFailure(f),
        (drafts) => ReelStudioState.loadSuccess(
          recipes: recipes,
          drafts: drafts,
        ),
      ),
    );
  }

  Future<void> deleteDraft(String draftId) async {
    await _repository.deleteDraft(draftId);
    unawaited(load());
  }

  Future<ReelDraft?> requestCoaching(String draftId) async {
    final either = await _repository.requestCoaching(draftId);
    return either.fold((_) => null, (draft) {
      unawaited(load());
      return draft;
    });
  }
}

class CreateDraftNotifier extends StateNotifier<CreateDraftState> {
  CreateDraftNotifier(this._repository)
    : super(const CreateDraftState.editing());

  final ReelStudioRepository _repository;

  void setCaption(String caption) {
    state = state.maybeWhen(
      editing:
          (_, hashtags, taggedProductIds, platform) =>
              CreateDraftState.editing(
                caption: caption,
                hashtags: hashtags,
                taggedProductIds: taggedProductIds,
                platform: platform,
              ),
      orElse: () => state,
    );
  }

  void setHashtags(List<String> hashtags) {
    state = state.maybeWhen(
      editing:
          (caption, _, taggedProductIds, platform) =>
              CreateDraftState.editing(
                caption: caption,
                hashtags: hashtags,
                taggedProductIds: taggedProductIds,
                platform: platform,
              ),
      orElse: () => state,
    );
  }

  void setTaggedProductIds(List<String> ids) {
    state = state.maybeWhen(
      editing:
          (caption, hashtags, _, platform) =>
              CreateDraftState.editing(
                caption: caption,
                hashtags: hashtags,
                taggedProductIds: ids,
                platform: platform,
              ),
      orElse: () => state,
    );
  }

  void setPlatform(SocialPlatform platform) {
    state = state.maybeWhen(
      editing:
          (caption, hashtags, taggedProductIds, _) =>
              CreateDraftState.editing(
                caption: caption,
                hashtags: hashtags,
                taggedProductIds: taggedProductIds,
                platform: platform,
              ),
      orElse: () => state,
    );
  }

  Future<void> save() async {
    state = state.maybeWhen(
      editing: (caption, hashtags, taggedProductIds, platform) {
        state = const CreateDraftState.saving();
        _performSave(caption, hashtags, taggedProductIds, platform);
        return state;
      },
      orElse: () => state,
    );
  }

  Future<void> _performSave(
    String caption,
    List<String> hashtags,
    List<String> taggedProductIds,
    SocialPlatform platform,
  ) async {
    final either = await _repository.createDraft(
      caption: caption,
      hashtags: hashtags,
      taggedProductIds: taggedProductIds,
      platform: platform,
    );
    state = either.fold(
      CreateDraftState.saveFailure,
      CreateDraftState.saved,
    );
  }
}
