import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/repositories/creator_profile_repository.dart';

part 'creator_profile_notifier.freezed.dart';

// ── Load profile ──────────────────────────────────────────────────────────────

@freezed
abstract class CreatorProfileState with _$CreatorProfileState {
  const CreatorProfileState._();

  const factory CreatorProfileState.initial() = _CpInitial;
  const factory CreatorProfileState.loadInProgress() = _CpLoadInProgress;
  const factory CreatorProfileState.loadSuccess(CreatorProfile profile) =
      _CpLoadSuccess;
  const factory CreatorProfileState.loadFailure(NetworkExceptions failure) =
      _CpLoadFailure;
}

class CreatorProfileNotifier extends StateNotifier<CreatorProfileState> {
  CreatorProfileNotifier(this._repository, this._accountId)
      : super(const CreatorProfileState.initial()) {
    unawaited(load());
  }

  final CreatorProfileRepository _repository;
  final String _accountId;

  Future<void> load() async {
    state = const CreatorProfileState.loadInProgress();
    final either = await _repository.getCreatorProfile(_accountId);
    state = either.fold(
      CreatorProfileState.loadFailure,
      CreatorProfileState.loadSuccess,
    );
  }
}

// ── Update profile ────────────────────────────────────────────────────────────

@freezed
abstract class UpdateCreatorProfileState with _$UpdateCreatorProfileState {
  const UpdateCreatorProfileState._();

  const factory UpdateCreatorProfileState.initial() = _UpdateInitial;
  const factory UpdateCreatorProfileState.submitting() = _UpdateSubmitting;
  const factory UpdateCreatorProfileState.success(CreatorProfile profile) =
      _UpdateSuccess;
  const factory UpdateCreatorProfileState.failure(NetworkExceptions failure) =
      _UpdateFailure;
}

class UpdateCreatorProfileNotifier
    extends StateNotifier<UpdateCreatorProfileState> {
  UpdateCreatorProfileNotifier(this._repository)
      : super(const UpdateCreatorProfileState.initial());

  final CreatorProfileRepository _repository;

  Future<void> submit({
    required String accountId,
    required String rowVersion,
    String? displayName,
    String? bio,
    String? avatarUrl,
    List<String>? tags,
    List<String>? niches,
  }) async {
    state = const UpdateCreatorProfileState.submitting();
    final either = await _repository.updateCreatorProfile(
      accountId: accountId,
      rowVersion: rowVersion,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      tags: tags,
      niches: niches,
    );
    // Guard against the user navigating back while the request was in-flight.
    // autoDispose disposes this notifier when the screen leaves the tree, so
    // writing state on a disposed notifier would throw.
    if (mounted) {
      state = either.fold(
        UpdateCreatorProfileState.failure,
        UpdateCreatorProfileState.success,
      );
    }
  }
}
