import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/domain/entities/vendor_activity_entry.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/domain/repositories/vendor_activity_repository.dart';

part 'vendor_activity_notifier.freezed.dart';

@freezed
abstract class VendorActivityState with _$VendorActivityState {
  const factory VendorActivityState.initial() = _Initial;
  const factory VendorActivityState.loadInProgress() = _LoadInProgress;
  const factory VendorActivityState.loadSuccess(List<VendorActivityEntry> entries) =
      _LoadSuccess;
  const factory VendorActivityState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class VendorActivityNotifier extends StateNotifier<VendorActivityState> {
  VendorActivityNotifier(this._repository, {this.pageSize = 25})
    : super(const VendorActivityState.initial()) {
    unawaited(load());
  }

  final VendorActivityRepository _repository;
  final int pageSize;

  Future<void> load() async {
    state = const VendorActivityState.loadInProgress();
    final either = await _repository.getActivity(pageSize: pageSize);
    state = either.fold(
      VendorActivityState.loadFailure,
      VendorActivityState.loadSuccess,
    );
  }
}
