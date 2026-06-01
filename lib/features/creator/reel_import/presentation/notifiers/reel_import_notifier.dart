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
  const factory ImportHistoryState.loadInProgress() = _ImportHistoryLoadInProgress;
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
  const factory ProductSearchState.loadInProgress() = _ProductSearchLoadInProgress;
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

  Future<void> importReel(
    String platformPostId,
    String caption,
    List<String> taggedProductIds,
  ) async {
    final either = await _repository.importReel(
      platformPostId,
      caption,
      taggedProductIds,
    );
    either.fold((_) => null, (_) => null);
  }
}

class ImportHistoryNotifier extends StateNotifier<ImportHistoryState> {
  ImportHistoryNotifier(this._repository)
    : super(const ImportHistoryState.initial()) {
    unawaited(load());
  }

  final ReelImportRepository _repository;

  Future<void> load({int limit = 20, String? cursor}) async {
    state = const ImportHistoryState.loadInProgress();
    final either = await _repository.getImportHistory(
      limit: limit,
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
    if (query.isEmpty) {
      state = const ProductSearchState.initial();
      return;
    }
    state = const ProductSearchState.loadInProgress();
    final either = await _repository.searchProducts(query);
    state = either.fold(
      ProductSearchState.loadFailure,
      ProductSearchState.loadSuccess,
    );
  }
}
