import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

part 'reels_feed_notifier.freezed.dart';

@freezed
abstract class ReelsFeedState with _$ReelsFeedState {
  const ReelsFeedState._();

  const factory ReelsFeedState.initial() = _Initial;
  const factory ReelsFeedState.loadInProgress() = _LoadInProgress;
  const factory ReelsFeedState.loadSuccess(List<Reel> reels) = _LoadSuccess;
  const factory ReelsFeedState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class ReelsFeedNotifier extends StateNotifier<ReelsFeedState> {
  ReelsFeedNotifier(this._repository) : super(const ReelsFeedState.initial()) {
    unawaited(fetchFeed());
  }

  final ReelsRepository _repository;

  Future<void> fetchFeed({int limit = 20, String? cursor}) async {
    state = const ReelsFeedState.loadInProgress();
    final either = await _repository.getReelsFeed(limit: limit, cursor: cursor);
    state = either.fold(
      ReelsFeedState.loadFailure,
      ReelsFeedState.loadSuccess,
    );
  }
}
