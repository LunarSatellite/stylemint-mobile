import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/entities/friend.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/repositories/friends_repository.dart';

part 'friends_notifier.freezed.dart';

// --- Friends list state --------------------------------------------------------

@freezed
abstract class FriendsListState with _$FriendsListState {
  const factory FriendsListState.initial() = _FriendsListInitial;
  const factory FriendsListState.loadInProgress() = _FriendsListLoadInProgress;
  const factory FriendsListState.loadSuccess({
    required List<Friend> friends,
    @Default(false) bool hasMore,
    String? nextCursor,
  }) = _FriendsListLoadSuccess;
  const factory FriendsListState.loadFailure(NetworkExceptions failure) =
      _FriendsListLoadFailure;
}

// --- Requests state ------------------------------------------------------------

@freezed
abstract class RequestsListState with _$RequestsListState {
  const factory RequestsListState.initial() = _RequestsListInitial;
  const factory RequestsListState.loadInProgress() = _RequestsListLoadInProgress;
  const factory RequestsListState.loadSuccess(List<FriendRequest> requests) =
      _RequestsListLoadSuccess;
  const factory RequestsListState.loadFailure(NetworkExceptions failure) =
      _RequestsListLoadFailure;
}

// --- Import state --------------------------------------------------------------

@freezed
abstract class ImportContactsState with _$ImportContactsState {
  const factory ImportContactsState.initial() = _ImportInitial;
  const factory ImportContactsState.loadInProgress() = _ImportLoadInProgress;
  const factory ImportContactsState.loadSuccess(List<Friend> matchedFriends) =
      _ImportLoadSuccess;
  const factory ImportContactsState.loadFailure(NetworkExceptions failure) =
      _ImportLoadFailure;
}

// --- Wrapper state -------------------------------------------------------------

@freezed
abstract class FriendsViewState with _$FriendsViewState {
  const factory FriendsViewState({
    @Default(FriendsListState.initial()) FriendsListState friendsState,
    @Default(RequestsListState.initial()) RequestsListState requestsState,
    @Default(ImportContactsState.initial()) ImportContactsState importState,
  }) = _FriendsViewState;
}

class FriendsNotifier extends StateNotifier<FriendsViewState> {
  FriendsNotifier(this._repository) : super(const FriendsViewState()) {
    unawaited(loadFriends());
  }

  final FriendsRepository _repository;

  Future<void> loadFriends({String? search, int limit = 20, String? cursor}) async {
    state = state.copyWith(
      friendsState: const FriendsListState.loadInProgress(),
    );
    final either = await _repository.getFriends(
      search: search,
      limit: limit,
      cursor: cursor,
    );
    state = state.copyWith(
      friendsState: either.fold(
        FriendsListState.loadFailure,
        (result) => FriendsListState.loadSuccess(
          friends: result.items,
          hasMore: result.hasMore,
          nextCursor: result.nextCursor,
        ),
      ),
    );
  }

  Future<void> loadRequests() async {
    state = state.copyWith(
      requestsState: const RequestsListState.loadInProgress(),
    );
    final either = await _repository.getFriendRequests();
    state = state.copyWith(
      requestsState: either.fold(
        RequestsListState.loadFailure,
        RequestsListState.loadSuccess,
      ),
    );
  }

  Future<void> sendRequest(String userId) async {
    await _repository.sendFriendRequest(userId);
  }

  Future<void> accept(String requestId) async {
    await _repository.acceptRequest(requestId);
    await loadRequests();
    await loadFriends();
  }

  Future<void> decline(String requestId) async {
    await _repository.declineRequest(requestId);
    await loadRequests();
  }

  Future<void> unfriend(String userId) async {
    await _repository.unfriend(userId);
    await loadFriends();
  }

  Future<void> importContacts(List<String> contacts) async {
    state = state.copyWith(
      importState: const ImportContactsState.loadInProgress(),
    );
    final either = await _repository.importContacts(contacts);
    state = state.copyWith(
      importState: either.fold(
        ImportContactsState.loadFailure,
        ImportContactsState.loadSuccess,
      ),
    );
  }
}
