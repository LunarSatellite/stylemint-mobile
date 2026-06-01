import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';

part 'discover_notifier.freezed.dart';

@freezed
abstract class DiscoverState with _$DiscoverState {
  const DiscoverState._();

  const factory DiscoverState.initial() = _Initial;
  const factory DiscoverState.loadInProgress() = _LoadInProgress;
  const factory DiscoverState.loadSuccess(DiscoverData data) = _LoadSuccess;
  const factory DiscoverState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  DiscoverNotifier(this._repository) : super(const DiscoverState.initial()) {
    unawaited(fetchDiscover());
  }

  final DiscoveryRepository _repository;

  Future<void> fetchDiscover() async {
    state = const DiscoverState.loadInProgress();
    final either = await _repository.getDiscoverData();
    state = either.fold(
      DiscoverState.loadFailure,
      DiscoverState.loadSuccess,
    );
  }
}
