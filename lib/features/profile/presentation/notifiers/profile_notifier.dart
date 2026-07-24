import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/user_profile.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/repositories/profile_repository.dart';

part 'profile_notifier.freezed.dart';

@freezed
abstract class ProfileState with _$ProfileState {
  const ProfileState._();

  const factory ProfileState.initial() = _Initial;
  const factory ProfileState.loadInProgress() = _LoadInProgress;
  const factory ProfileState.loadSuccess(ProfileSummary summary) = _LoadSuccess;
  const factory ProfileState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repository) : super(const ProfileState.initial()) {
    unawaited(fetchProfile());
  }

  final ProfileRepository _repository;

  Future<void> fetchProfile() async {
    state = const ProfileState.loadInProgress();
    final either = await _repository.getProfileSummary();
    state = either.fold(
      ProfileState.loadFailure,
      ProfileState.loadSuccess,
    );

    // Non-fatal enrichment — the base summary already rendered; the counts
    // (saved/following/orders) each come from their own real endpoint, not
    // the account endpoint, so they arrive slightly after the rest of the
    // header. Left as 0 on failure rather than blocking profile display.
    final summary = state.maybeWhen(loadSuccess: (s) => s, orElse: () => null);
    if (summary == null) return;
    final statsEither = await _repository.getProfileStats(summary);
    statsEither.fold(
      (_) {},
      (updated) => state = ProfileState.loadSuccess(updated),
    );
  }
}

@freezed
abstract class EditProfileState with _$EditProfileState {
  const EditProfileState._();

  const factory EditProfileState.initial() = _EditInitial;
  const factory EditProfileState.loadInProgress() = _EditLoadInProgress;
  const factory EditProfileState.loadSuccess(UserProfile profile) = _EditLoadSuccess;
  const factory EditProfileState.loadFailure(NetworkExceptions failure) = _EditLoadFailure;
  const factory EditProfileState.saving() = _EditSaving;
  const factory EditProfileState.saveSuccess(UserProfile profile) = _EditSaveSuccess;
  const factory EditProfileState.saveFailure(NetworkExceptions failure) = _EditSaveFailure;
}

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  EditProfileNotifier(this._repository) : super(const EditProfileState.initial()) {
    unawaited(loadProfile());
  }

  final ProfileRepository _repository;

  Future<void> loadProfile() async {
    state = const EditProfileState.loadInProgress();
    final either = await _repository.getFullProfile();
    state = either.fold(
      EditProfileState.loadFailure,
      EditProfileState.loadSuccess,
    );
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    final current = state.maybeWhen(
      loadSuccess: (p) => p,
      saveSuccess: (p) => p,
      orElse: () => null,
    );
    state = const EditProfileState.saving();
    final either = await _repository.updateProfile(
      displayName: displayName ?? current?.displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      gender: gender,
      dateOfBirth: dateOfBirth,
      rowVersion: current?.rowVersion ?? '',
    );
    state = either.fold(
      EditProfileState.saveFailure,
      EditProfileState.saveSuccess,
    );
  }
}

@freezed
abstract class FollowingState with _$FollowingState {
  const FollowingState._();

  const factory FollowingState.initial() = _FollowingInitial;
  const factory FollowingState.loadInProgress() = _FollowingLoadInProgress;
  const factory FollowingState.loadSuccess(List<FollowingUser> users) = _FollowingLoadSuccess;
  const factory FollowingState.loadFailure(NetworkExceptions failure) = _FollowingLoadFailure;
}

class FollowingNotifier extends StateNotifier<FollowingState> {
  FollowingNotifier(this._repository) : super(const FollowingState.initial()) {
    unawaited(load());
  }

  final ProfileRepository _repository;
  String? _search;

  Future<void> load({String? search, String? cursor}) async {
    _search = search;
    state = const FollowingState.loadInProgress();
    final either = await _repository.getFollowing(
      search: _search,
      cursor: cursor,
    );
    state = either.fold(
      FollowingState.loadFailure,
      (result) => FollowingState.loadSuccess(result.items),
    );
  }

  Future<void> unfollow(String userId) async {
    final either = await _repository.unfollowUser(userId);
    either.fold(
      (_) => null,
      (_) => load(), // reload after successful unfollow
    );
  }
}
