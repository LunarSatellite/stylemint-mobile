import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/kyc_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/repositories/customer_kyc_repository.dart';

part 'customer_kyc_notifier.freezed.dart';

/// Where a submission has got to. The screen names each step, because
/// uploading three photos on a slow connection takes long enough that a bare
/// spinner reads as a hang.
enum KycSubmitPhase { idle, startingSession, uploading, submitting, submitted }

@freezed
abstract class CustomerKycState with _$CustomerKycState {
  const CustomerKycState._();

  const factory CustomerKycState({
    @Default(true) bool loading,
    CustomerKyc? kyc,
    EmiFailure? loadFailure,
    @Default(KycSubmitPhase.idle) KycSubmitPhase phase,
    EmiFailure? submitFailure,
    @Default(0) int uploadedCount,
    @Default(0) int uploadTotal,
  }) = _CustomerKycState;

  /// The KYC endpoints answered 404 — the backend is not deployed yet. The
  /// screens say verification is not open rather than showing an error.
  bool get isUnavailable => loadFailure?.isNotFound ?? false;

  bool get isBusy =>
      phase == KycSubmitPhase.startingSession ||
      phase == KycSubmitPhase.uploading ||
      phase == KycSubmitPhase.submitting;

  /// The sentence for the last failed submission, if any.
  String? get submitError {
    final failure = submitFailure;
    return failure == null ? null : kycErrorMessage(failure);
  }

  /// Photo kinds already on the server in the session the buyer can still
  /// add to. A decided session's photos do not count: a resubmission starts
  /// a new session and needs its own.
  Set<KycDocumentKind> get uploadedKinds {
    final current = kyc;
    if (current == null || !current.status.isNotStarted) return const {};
    return {for (final document in current.documents) document.kind};
  }
}

/// Loads the buyer's KYC record and runs a submission: start (or resume) a
/// session, upload each photo, then submit the details.
class CustomerKycNotifier extends StateNotifier<CustomerKycState> {
  CustomerKycNotifier(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const CustomerKycState());

  final CustomerKycRepository _repository;
  final DateTime Function() _now;

  Future<void> load() async {
    state = state.copyWith(loading: true, loadFailure: null);
    final result = await _repository.getKyc();
    if (!mounted) return;
    state = result.fold(
      (failure) => state.copyWith(loading: false, loadFailure: failure),
      (kyc) => state.copyWith(loading: false, kyc: kyc, loadFailure: null),
    );
  }

  void clearSubmitError() {
    if (state.submitFailure != null) {
      state = state.copyWith(submitFailure: null);
    }
  }

  /// Sends [details] with the photos in [captures]. True once the server has
  /// the submission (status `Submitted`).
  ///
  /// The rules the server enforces — 18 or older, every required photo — are
  /// checked first, with the server's own codes, so a buyer hears about a
  /// missing selfie before three photos go up rather than after.
  Future<bool> submit({
    required KycDetails details,
    required Map<KycDocumentKind, File> captures,
  }) async {
    if (state.isBusy) return false;
    state = state.copyWith(submitFailure: null);

    if (details.fullName.trim().isEmpty ||
        details.documentNumber.trim().isEmpty ||
        details.addressId.isEmpty) {
      return _fail(const EmiFailure.local(KycLocalCode.detailsIncomplete));
    }
    if (!isAtLeast18(details.dateOfBirth, _now())) {
      return _fail(const EmiFailure.local(KycErrorCode.underage));
    }
    final required = details.documentType.requiredKinds;
    final missingBefore = _missing(required, captures, state.uploadedKinds);
    if (missingBefore.isNotEmpty)
      return _fail(_documentsMissing(missingBefore));

    state = state.copyWith(phase: KycSubmitPhase.startingSession);
    final started = await _repository.startSession();
    if (!mounted) return false;
    final session = started.fold<CustomerKyc?>((_) => null, (kyc) => kyc);
    final sessionId = session?.sessionId;
    if (session == null || sessionId == null) {
      return _fail(
        started.fold(
          (failure) => failure,
          (_) => const EmiFailure(EmiFailureKind.unknown),
        ),
      );
    }
    state = state.copyWith(kyc: session);

    // The session the server handed back decides what is already there — it
    // may be a fresh one after a rejection, holding nothing.
    final onServer = state.uploadedKinds;
    final missingNow = _missing(required, captures, onServer);
    if (missingNow.isNotEmpty) return _fail(_documentsMissing(missingNow));

    final toUpload = [
      for (final kind in required)
        if (captures[kind] case final File file) (kind, file),
    ];
    state = state.copyWith(
      phase: KycSubmitPhase.uploading,
      uploadedCount: 0,
      uploadTotal: toUpload.length,
    );
    for (final (kind, file) in toUpload) {
      final uploaded = await _repository.uploadDocument(
        sessionId: sessionId,
        kind: kind,
        file: file,
      );
      if (!mounted) return false;
      final failure = uploaded.fold<EmiFailure?>((f) => f, (_) => null);
      if (failure != null) return _fail(failure);
      state = state.copyWith(uploadedCount: state.uploadedCount + 1);
    }

    state = state.copyWith(phase: KycSubmitPhase.submitting);
    final submitted = await _repository.submit(
      sessionId: sessionId,
      details: details,
    );
    if (!mounted) return false;
    return submitted.fold(_fail, (kyc) {
      state = state.copyWith(
        phase: KycSubmitPhase.submitted,
        kyc: kyc,
        submitFailure: null,
      );
      return true;
    });
  }

  static List<KycDocumentKind> _missing(
    List<KycDocumentKind> required,
    Map<KycDocumentKind, File> captures,
    Set<KycDocumentKind> onServer,
  ) => [
    for (final kind in required)
      if (!captures.containsKey(kind) && !onServer.contains(kind)) kind,
  ];

  static EmiFailure _documentsMissing(List<KycDocumentKind> kinds) =>
      EmiFailure.local(
        KycErrorCode.documentsMissing,
        missing: [for (final kind in kinds) kind.wire],
      );

  bool _fail(EmiFailure failure) {
    state = state.copyWith(phase: KycSubmitPhase.idle, submitFailure: failure);
    return false;
  }
}
