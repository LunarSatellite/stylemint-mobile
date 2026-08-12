import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/identity_document.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_documents_repository.dart';

class CreatorDocumentsState {
  const CreatorDocumentsState({
    this.documents = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.lastUploadedFilename,
  });

  final List<IdentityDocument> documents;
  final bool isLoading;
  final bool isUploading;
  final bool isSubmitting;
  final String? errorMessage;

  /// Set after a successful upload so the screen can confirm which file
  /// landed, then cleared by the next action.
  final String? lastUploadedFilename;

  bool get isBusy => isLoading || isUploading || isSubmitting;

  /// A creator cannot submit until at least one document is attached; the
  /// backend rejects an empty session anyway.
  bool get canSubmit => documents.isNotEmpty && !isBusy;

  List<IdentityDocument> get rejected =>
      documents.where((d) => d.isRejected).toList(growable: false);

  CreatorDocumentsState copyWith({
    List<IdentityDocument>? documents,
    bool? isLoading,
    bool? isUploading,
    bool? isSubmitting,
    String? errorMessage,
    String? lastUploadedFilename,
    bool clearError = false,
    bool clearLastUploaded = false,
  }) =>
      CreatorDocumentsState(
        documents: documents ?? this.documents,
        isLoading: isLoading ?? this.isLoading,
        isUploading: isUploading ?? this.isUploading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        lastUploadedFilename: clearLastUploaded
            ? null
            : (lastUploadedFilename ?? this.lastUploadedFilename),
      );
}

/// Drives the identity-document step of the creator apply flow.
class CreatorDocumentsNotifier extends StateNotifier<CreatorDocumentsState> {
  CreatorDocumentsNotifier(this._repository)
      : super(const CreatorDocumentsState());

  final CreatorDocumentsRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.listSubmittedDocuments();
    if (!mounted) return;
    state = result.fold(
      (failure) => state.copyWith(
        isLoading: false,
        errorMessage: NetworkExceptions.getMessage(failure),
      ),
      (documents) => state.copyWith(isLoading: false, documents: documents),
    );
  }

  /// Returns whether the upload succeeded so the screen can advance only on
  /// success.
  Future<bool> upload({
    required File file,
    required IdentityDocumentType type,
    IdentityDocumentSide side = IdentityDocumentSide.notApplicable,
  }) async {
    if (state.isUploading) return false;
    state = state.copyWith(
      isUploading: true,
      clearError: true,
      clearLastUploaded: true,
    );

    final result = await _repository.uploadIdentityDocument(
      file: file,
      type: type,
      side: side,
    );
    if (!mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isUploading: false,
          errorMessage: NetworkExceptions.getMessage(failure),
        );
        return false;
      },
      (document) {
        state = state.copyWith(
          isUploading: false,
          documents: [...state.documents, document],
          lastUploadedFilename:
              document.originalFilename ?? file.uri.pathSegments.last,
        );
        return true;
      },
    );
  }

  Future<bool> submitForReview() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await _repository.submitForReview();
    if (!mounted) return false;

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: NetworkExceptions.getMessage(failure),
        );
        return false;
      },
      (_) {
        state = state.copyWith(isSubmitting: false);
        return true;
      },
    );
  }
}
