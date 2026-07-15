import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/domain/entities/creator_activity_entry.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/domain/repositories/creator_activity_repository.dart';

part 'creator_activity_notifier.freezed.dart';

@freezed
abstract class CreatorActivityState with _$CreatorActivityState {
  const factory CreatorActivityState.initial() = _Initial;
  const factory CreatorActivityState.loadInProgress() = _LoadInProgress;
  const factory CreatorActivityState.loadSuccess(
    List<CreatorActivityEntry> entries,
  ) = _LoadSuccess;
  const factory CreatorActivityState.loadFailure(
    NetworkExceptions failure,
  ) = _LoadFailure;
}

class CreatorActivityNotifier extends StateNotifier<CreatorActivityState> {
  CreatorActivityNotifier(this._repository, {this.pageSize = 25})
      : super(const CreatorActivityState.initial()) {
    unawaited(load());
  }

  final CreatorActivityRepository _repository;
  final int pageSize;

  Future<void> load() async {
    state = const CreatorActivityState.loadInProgress();
    final either = await _repository.getActivity(pageSize: pageSize);
    state = either.fold(
      CreatorActivityState.loadFailure,
      CreatorActivityState.loadSuccess,
    );
  }
}
