import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/domain/entities/group.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/domain/repositories/groups_repository.dart';

part 'groups_notifier.freezed.dart';

// --- List state ----------------------------------------------------------------

@freezed
abstract class GroupsListState with _$GroupsListState {
  const factory GroupsListState.initial() = _GroupsListInitial;
  const factory GroupsListState.loadInProgress() = _GroupsListLoadInProgress;
  const factory GroupsListState.loadSuccess(List<StyleGroup> groups) =
      _GroupsListLoadSuccess;
  const factory GroupsListState.loadFailure(NetworkExceptions failure) =
      _GroupsListLoadFailure;
}

// --- Detail state --------------------------------------------------------------

@freezed
abstract class GroupDetailState with _$GroupDetailState {
  const factory GroupDetailState.initial() = _GroupDetailInitial;
  const factory GroupDetailState.loadInProgress() = _GroupDetailLoadInProgress;
  const factory GroupDetailState.loadSuccess({
    required StyleGroup group,
    required List<GroupPost> posts,
    @Default(false) bool hasMore,
    String? nextCursor,
  }) = _GroupDetailLoadSuccess;
  const factory GroupDetailState.loadFailure(NetworkExceptions failure) =
      _GroupDetailLoadFailure;
}

// --- Wrapper state -------------------------------------------------------------

@freezed
abstract class GroupsViewState with _$GroupsViewState {
  const factory GroupsViewState({
    @Default(GroupsListState.initial()) GroupsListState listState,
    @Default(GroupDetailState.initial()) GroupDetailState detailState,
  }) = _GroupsViewState;
}

class GroupsNotifier extends StateNotifier<GroupsViewState> {
  GroupsNotifier(this._repository)
    : super(const GroupsViewState()) {
    unawaited(loadGroups());
  }

  final GroupsRepository _repository;

  Future<void> loadGroups({String? category, String? search}) async {
    state = state.copyWith(listState: const GroupsListState.loadInProgress());
    final either = await _repository.getGroups(
      category: category,
      search: search,
    );
    state = state.copyWith(
      listState: either.fold(
        GroupsListState.loadFailure,
        GroupsListState.loadSuccess,
      ),
    );
  }

  Future<void> loadGroup(String groupId) async {
    state = state.copyWith(
      detailState: const GroupDetailState.loadInProgress(),
    );
    final either = await _repository.getGroupDetail(groupId);
    either.fold(
      (f) => state = state.copyWith(
        detailState: GroupDetailState.loadFailure(f),
      ),
      (group) async {
        final feedEither = await _repository.getGroupFeed(groupId);
        state = state.copyWith(
          detailState: feedEither.fold(
            (f) => GroupDetailState.loadSuccess(group: group, posts: const []),
            (result) => GroupDetailState.loadSuccess(
              group: group,
              posts: result.items,
              hasMore: result.hasMore,
              nextCursor: result.nextCursor,
            ),
          ),
        );
      },
    );
  }

  Future<void> join(String groupId) async {
    await _repository.joinGroup(groupId);
    await loadGroup(groupId);
    await loadGroups();
  }

  Future<void> leave(String groupId) async {
    await _repository.leaveGroup(groupId);
    await loadGroup(groupId);
    await loadGroups();
  }

  Future<void> loadFeed(String groupId, {int limit = 20, String? cursor}) async {
    final either = await _repository.getGroupFeed(
      groupId,
      limit: limit,
      cursor: cursor,
    );
    either.fold(
      (_) {},
      (result) {
        state.detailState.maybeWhen(
          loadSuccess: (group, _, __, ___) {
            state = state.copyWith(
              detailState: GroupDetailState.loadSuccess(
                group: group,
                posts: result.items,
                hasMore: result.hasMore,
                nextCursor: result.nextCursor,
              ),
            );
          },
          orElse: () {},
        );
      },
    );
  }

  Future<void> createPost({
    required String groupId,
    required String content,
    List<String>? images,
  }) async {
    final either = await _repository.createGroupPost(
      groupId: groupId,
      content: content,
      images: images,
    );
    either.fold(
      (_) {},
      (_) => loadFeed(groupId),
    );
  }
}
