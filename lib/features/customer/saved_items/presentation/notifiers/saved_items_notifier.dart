import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/entities/saved_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/repositories/saved_items_repository.dart';

part 'saved_items_notifier.freezed.dart';

@freezed
abstract class SavedItemsState with _$SavedItemsState {
  const SavedItemsState._();

  const factory SavedItemsState.initial() = _SavedInitial;
  const factory SavedItemsState.loadInProgress() = _SavedLoadInProgress;
  const factory SavedItemsState.loadSuccess({
    required List<SavedItem> items,
    required bool hasMore,
    String? nextCursor,
  }) = _SavedLoadSuccess;
  const factory SavedItemsState.loadFailure(NetworkExceptions failure) = _SavedLoadFailure;
}

class SavedItemsNotifier extends StateNotifier<SavedItemsState> {
  SavedItemsNotifier(this._repository)
      : super(const SavedItemsState.initial()) {
    unawaited(load());
  }

  final SavedItemsRepository _repository;

  String? _nextCursor;

  Future<void> load({int limit = 20}) async {
    _nextCursor = null;
    state = const SavedItemsState.loadInProgress();
    await _fetchPage(limit: limit);
  }

  Future<void> loadMore({int limit = 20}) async {
    if (_nextCursor == null) return;
    await _fetchPage(limit: limit, append: true);
  }

  Future<void> _fetchPage({int limit = 20, bool append = false}) async {
    final either = await _repository.getSavedItems(limit: limit, cursor: _nextCursor);

    either.fold(
      (failure) {
        state = SavedItemsState.loadFailure(failure);
      },
      (paged) {
        _nextCursor = paged.nextCursor;
        final items = append
            ? [
                ...state.maybeWhen(
                  loadSuccess: (items, _, __) => items,
                  orElse: () => <SavedItem>[],
                ),
                ...paged.items,
              ]
            : paged.items;
        state = SavedItemsState.loadSuccess(
          items: items,
          hasMore: paged.hasMore,
          nextCursor: paged.nextCursor,
        );
      },
    );
  }

  Future<void> removeItem(String savedItemId) async {
    final currentItems = state.maybeWhen(
      loadSuccess: (items, _, __) => items,
      orElse: () => <SavedItem>[],
    );

    state = SavedItemsState.loadSuccess(
      items: currentItems.where((i) => i.id != savedItemId).toList(),
      hasMore: _nextCursor != null,
      nextCursor: _nextCursor,
    );

    final either = await _repository.removeItem(savedItemId);
    either.fold(
      (_) {}, // ignore failure — item is already removed from UI
      (_) {},
    );
  }
}
