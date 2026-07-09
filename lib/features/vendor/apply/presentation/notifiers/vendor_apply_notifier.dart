import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/repositories/vendor_repository.dart';

part 'vendor_apply_notifier.freezed.dart';

@freezed
abstract class ApplicationState with _$ApplicationState {
  const ApplicationState._();

  const factory ApplicationState.initial() = _AppInitial;
  const factory ApplicationState.loadInProgress() = _AppLoadInProgress;
  const factory ApplicationState.loadSuccess(VendorApplication application) = _AppLoadSuccess;
  const factory ApplicationState.loadFailure(NetworkExceptions failure) = _AppLoadFailure;
}

@freezed
abstract class SubmitState with _$SubmitState {
  const SubmitState._();

  const factory SubmitState.initial() = _SubmitInitial;
  const factory SubmitState.submitting() = _Submitting;
  const factory SubmitState.success(VendorApplication application) = _SubmitSuccess;
  const factory SubmitState.failure(NetworkExceptions failure) = _SubmitFailure;
}

@freezed
abstract class KYCDocumentsState with _$KYCDocumentsState {
  const KYCDocumentsState._();

  const factory KYCDocumentsState.initial() = _KycDocsInitial;
  const factory KYCDocumentsState.loadInProgress() = _KycDocsLoadInProgress;
  const factory KYCDocumentsState.loadSuccess(List<KYCDocument> documents) = _KycDocsLoadSuccess;
  const factory KYCDocumentsState.loadFailure(NetworkExceptions failure) = _KycDocsLoadFailure;
}

class VendorApplyNotifier extends StateNotifier<ApplicationState> {
  VendorApplyNotifier(this._repository)
    : super(const ApplicationState.initial());

  final VendorRepository _repository;

  SubmitState _submitState = const SubmitState.initial();
  SubmitState get submitState => _submitState;

  KYCDocumentsState _kycDocsState = const KYCDocumentsState.initial();
  KYCDocumentsState get kycDocsState => _kycDocsState;

  void _updateSubmitState(SubmitState s) {
    _submitState = s;
  }

  void _updateKycDocsState(KYCDocumentsState s) {
    _kycDocsState = s;
  }

  Future<void> checkStatus(String accountId, {bool force = false}) async {
    if (!force) {
      final alreadyLoaded = state.maybeWhen(
        loadSuccess: (_) => true,
        loadInProgress: () => true,
        orElse: () => false,
      );
      if (alreadyLoaded) return;
    }

    state = const ApplicationState.loadInProgress();
    final either = await _repository.getApplicationStatus();
    state = either.fold(
      (f) => ApplicationState.loadFailure(f),
      (a) => ApplicationState.loadSuccess(a),
    );
    state.maybeWhen(
      loadSuccess: (_) => _loadKYCDocuments(accountId),
      orElse: () {},
    );
  }

  Future<void> submit(VendorApplicationForm form, String accountId) async {
    _updateSubmitState(const SubmitState.submitting());
    state = const ApplicationState.loadInProgress();
    final either = await _repository.submitApplication(form);
    either.fold(
      (failure) {
        _updateSubmitState(SubmitState.failure(failure));
        state = ApplicationState.loadFailure(failure);
      },
      (application) {
        _updateSubmitState(SubmitState.success(application));
        state = ApplicationState.loadSuccess(application);
        _loadKYCDocuments(accountId);
      },
    );
  }

  Future<void> uploadDoc(
    String filePath,
    KYCDocumentType type,
    String accountId,
  ) async {
    final either = await _repository.uploadKYCDocument(
      filePath,
      type,
      accountId: accountId,
    );
    either.fold(
      (_) {},
      (_) => _loadKYCDocuments(accountId),
    );
  }

  /// Resolves the account's active KYC session (if any documents have ever
  /// been uploaded) and loads its documents; an account with no session
  /// yet trivially has no documents.
  Future<void> _loadKYCDocuments(String accountId) async {
    _updateKycDocsState(const KYCDocumentsState.loadInProgress());
    final sessionEither = await _repository.getActiveKycSessionId(
      accountId: accountId,
    );
    await sessionEither.fold(
      (failure) async =>
          _updateKycDocsState(KYCDocumentsState.loadFailure(failure)),
      (sessionId) async {
        if (sessionId == null) {
          _updateKycDocsState(const KYCDocumentsState.loadSuccess([]));
          return;
        }
        final either = await _repository.getKYCDocuments(
          accountId: accountId,
          sessionId: sessionId,
        );
        _updateKycDocsState(either.fold(
          KYCDocumentsState.loadFailure,
          KYCDocumentsState.loadSuccess,
        ));
      },
    );
  }

  void resetSubmitState() {
    _updateSubmitState(const SubmitState.initial());
  }
}
