import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

part 'reel_import_notifier.freezed.dart';

@freezed
abstract class ReelImportState with _$ReelImportState {
  const ReelImportState._();

  const factory ReelImportState.initial() = _ReelImportInitial;
  const factory ReelImportState.loadInProgress() = _ReelImportLoadInProgress;
  const factory ReelImportState.loadSuccess(
    List<ImportableReel> reels,
  ) = _ReelImportLoadSuccess;
  const factory ReelImportState.loadFailure(NetworkExceptions failure) =
      _ReelImportLoadFailure;
}

@freezed
abstract class ImportHistoryState with _$ImportHistoryState {
  const ImportHistoryState._();

  const factory ImportHistoryState.initial() = _ImportHistoryInitial;
  const factory ImportHistoryState.loadInProgress() =
      _ImportHistoryLoadInProgress;
  const factory ImportHistoryState.loadSuccess(
    List<ImportedReel> reels,
  ) = _ImportHistoryLoadSuccess;
  const factory ImportHistoryState.loadFailure(NetworkExceptions failure) =
      _ImportHistoryLoadFailure;
}

@freezed
abstract class ProductSearchState with _$ProductSearchState {
  const ProductSearchState._();

  const factory ProductSearchState.initial() = _ProductSearchInitial;
  const factory ProductSearchState.loadInProgress() =
      _ProductSearchLoadInProgress;
  const factory ProductSearchState.loadSuccess(
    List<TaggedProductForImport> products,
  ) = _ProductSearchLoadSuccess;
  const factory ProductSearchState.loadFailure(NetworkExceptions failure) =
      _ProductSearchLoadFailure;
}

class ReelImportNotifier extends StateNotifier<ReelImportState> {
  ReelImportNotifier(this._repository) : super(const ReelImportState.initial());

  final ReelImportRepository _repository;

  Future<void> load(SocialPlatform platform) async {
    state = const ReelImportState.loadInProgress();
    final either = await _repository.getImportableReels(platform);
    state = either.fold(
      ReelImportState.loadFailure,
      ReelImportState.loadSuccess,
    );
  }

  Future<void> importReel(ImportableReel reel) async {
    final either = await _repository.importReel(reel);
    either.fold((_) => null, (_) => null);
  }
}

class ImportHistoryNotifier extends StateNotifier<ImportHistoryState> {
  ImportHistoryNotifier(this._repository)
    : super(const ImportHistoryState.initial()) {
    unawaited(load());
  }

  final ReelImportRepository _repository;

  Future<void> load({int pageSize = 20, String? cursor}) async {
    state = const ImportHistoryState.loadInProgress();
    final either = await _repository.getImportHistory(
      pageSize: pageSize,
      cursor: cursor,
    );
    state = either.fold(
      ImportHistoryState.loadFailure,
      ImportHistoryState.loadSuccess,
    );
  }
}

class ProductSearchNotifier extends StateNotifier<ProductSearchState> {
  ProductSearchNotifier(this._repository)
    : super(const ProductSearchState.initial());

  final ReelImportRepository _repository;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const ProductSearchState.loadSuccess([]);
      return;
    }
    state = const ProductSearchState.loadInProgress();
    final either = await _repository.searchProducts(query.trim());
    state = either.fold(
      ProductSearchState.loadFailure,
      ProductSearchState.loadSuccess,
    );
  }
}

// ── Submit state (plain sealed — no codegen required) ────────────────────────

sealed class ReelSubmitState {}

class ReelSubmitIdle extends ReelSubmitState {}

class ReelSubmitInProgress extends ReelSubmitState {}

class ReelSubmitSuccess extends ReelSubmitState {
  ReelSubmitSuccess(this.reelId);

  /// The backend-generated reel UUID (not the external platform post ID).
  /// May be null if the reel was already imported previously (409 conflict),
  /// since that response doesn't carry the existing reel's ID.
  final String? reelId;
}

class ReelSubmitFailure extends ReelSubmitState {
  ReelSubmitFailure(this.message);
  final String message;
}

class ReelSubmitNotifier extends StateNotifier<ReelSubmitState> {
  ReelSubmitNotifier(this._repository) : super(ReelSubmitIdle());

  final ReelImportRepository _repository;

  Future<void> submit(
    ImportableReel reel,
    List<TaggedProductForImport> taggedProducts,
  ) async {
    state = ReelSubmitInProgress();

    final importResult = await _repository.importReel(reel);
    if (importResult.isLeft()) {
      final failure = importResult.getLeft().toNullable()!;
      // 409 means this reel was already imported — treat as success
      final alreadyImported = failure.maybeWhen(
        conflict: () => true,
        orElse: () => false,
      );
      if (alreadyImported) {
        state = ReelSubmitSuccess(null);
        return;
      }
      state = ReelSubmitFailure(NetworkExceptions.getMessage(failure));
      return;
    }
    final importedReel = importResult.getRight().toNullable()!;

    for (final product in taggedProducts) {
      final tagResult = await _repository.tagProduct(
        reelId: importedReel.id,
        productId: product.productId,
      );
      if (tagResult.isLeft()) {
        final failure = tagResult.getLeft().toNullable()!;
        state = ReelSubmitFailure(NetworkExceptions.getMessage(failure));
        return;
      }
    }

    final publishResult = await _repository.publishReel(reelId: importedReel.id);
    if (publishResult.isLeft()) {
      final failure = publishResult.getLeft().toNullable()!;
      state = ReelSubmitFailure(NetworkExceptions.getMessage(failure));
      return;
    }

    state = ReelSubmitSuccess(importedReel.id);
  }
}
