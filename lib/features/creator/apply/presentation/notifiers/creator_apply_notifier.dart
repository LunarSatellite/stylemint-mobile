import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_repository.dart';

part 'creator_apply_notifier.freezed.dart';

@freezed
abstract class ApplicationStatusState with _$ApplicationStatusState {
  const ApplicationStatusState._();

  const factory ApplicationStatusState.initial() = _AppStatusInitial;

  const factory ApplicationStatusState.loadInProgress() =
      _AppStatusLoadInProgress;

  const factory ApplicationStatusState.loadSuccess(
    CreatorApplication application,
  ) = _AppStatusLoadSuccess;

  const factory ApplicationStatusState.loadFailure(NetworkExceptions failure) =
      _AppStatusLoadFailure;
}

@freezed
abstract class SubmitApplicationState with _$SubmitApplicationState {
  const SubmitApplicationState._();

  const factory SubmitApplicationState.initial() = _SubmitInitial;

  const factory SubmitApplicationState.submitting() = _Submitting;

  const factory SubmitApplicationState.success(CreatorApplication application) =
      _SubmitSuccess;

  const factory SubmitApplicationState.failure(NetworkExceptions failure) =
      _SubmitFailure;
}

class CreatorApplyNotifier extends StateNotifier<ApplicationStatusState> {
  CreatorApplyNotifier(this._repository)
    : super(const ApplicationStatusState.initial());

  final CreatorRepository _repository;

  SubmitApplicationState _submitState = const SubmitApplicationState.initial();

  SubmitApplicationState get submitState => _submitState;

  void _updateSubmitState(SubmitApplicationState s) {
    _submitState = s;
  }

  Future<void> checkStatus() async {
    state = const ApplicationStatusState.loadInProgress();
    final either = await _repository.getApplicationStatus();
    state = either.fold(
      ApplicationStatusState.loadFailure,
      ApplicationStatusState.loadSuccess,
    );
  }

  Future<void> submit(CreatorApplicationForm form) async {
    _updateSubmitState(const SubmitApplicationState.submitting());
    final either = await _repository.submitApplication(form);
    either.fold(
      (failure) {
        _updateSubmitState(SubmitApplicationState.failure(failure));
        state = ApplicationStatusState.loadFailure(failure);
      },
      (application) {
        _updateSubmitState(SubmitApplicationState.success(application));
        state = ApplicationStatusState.loadSuccess(application);
      },
    );
  }

  void resetSubmitState() {
    _updateSubmitState(const SubmitApplicationState.initial());
  }
}
