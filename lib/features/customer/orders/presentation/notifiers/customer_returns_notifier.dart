import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';

part 'customer_returns_notifier.freezed.dart';

@freezed
abstract class MyReturnsState with _$MyReturnsState {
  const MyReturnsState._();

  const factory MyReturnsState.initial() = _ReturnsInitial;
  const factory MyReturnsState.loadInProgress() = _ReturnsLoadInProgress;

  /// [isLoadingMore] and [loadMoreFailure] describe the next page only; the
  /// rows already loaded stay visible either way.
  const factory MyReturnsState.loadSuccess(
    List<CustomerReturn> returns, {
    String? nextCursor,
    @Default(false) bool isLoadingMore,
    NetworkExceptions? loadMoreFailure,
  }) = _ReturnsLoadSuccess;
  const factory MyReturnsState.loadFailure(NetworkExceptions failure) =
      _ReturnsLoadFailure;
}

/// "My returns" — the buyer's return requests, newest first, cursor-paged.
class MyReturnsNotifier extends StateNotifier<MyReturnsState> {
  MyReturnsNotifier(this._repository, {this.pageSize = 20})
    : super(const MyReturnsState.initial()) {
    unawaited(load());
  }

  final OrdersRepository _repository;
  final int pageSize;

  Future<void> load() async {
    state = const MyReturnsState.loadInProgress();
    await _loadFirstPage();
  }

  /// Pull-to-refresh: keeps the rows on screen while the first page reloads.
  Future<void> refresh() => _loadFirstPage(keepOnFailure: true);

  Future<void> loadMore() async {
    final current = state;
    if (current is! _ReturnsLoadSuccess) return;
    final cursor = current.nextCursor;
    if (cursor == null || current.isLoadingMore) return;

    state = current.copyWith(isLoadingMore: true, loadMoreFailure: null);
    final either = await _repository.getMyReturns(
      cursor: cursor,
      pageSize: pageSize,
    );
    if (!mounted) return;
    state = either.fold(
      (failure) =>
          current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
      (page) => MyReturnsState.loadSuccess(
        [...current.returns, ...page.items],
        nextCursor: page.hasMore ? page.nextCursor : null,
      ),
    );
  }

  Future<void> _loadFirstPage({bool keepOnFailure = false}) async {
    final previous = state;
    final either = await _repository.getMyReturns(pageSize: pageSize);
    if (!mounted) return;
    either.fold(
      (failure) {
        if (keepOnFailure && previous is _ReturnsLoadSuccess) return;
        state = MyReturnsState.loadFailure(failure);
      },
      (page) => state = MyReturnsState.loadSuccess(
        page.items,
        nextCursor: page.hasMore ? page.nextCursor : null,
      ),
    );
  }
}

@freezed
abstract class ReturnDetailState with _$ReturnDetailState {
  const ReturnDetailState._();

  const factory ReturnDetailState.initial() = _ReturnDetailInitial;
  const factory ReturnDetailState.loadInProgress() =
      _ReturnDetailLoadInProgress;
  const factory ReturnDetailState.loadSuccess(CustomerReturn customerReturn) =
      _ReturnDetailLoadSuccess;
  const factory ReturnDetailState.loadFailure(NetworkExceptions failure) =
      _ReturnDetailLoadFailure;
}

/// One return request, keyed by id.
class ReturnDetailNotifier extends StateNotifier<ReturnDetailState> {
  ReturnDetailNotifier(this._repository, this.returnId)
    : super(const ReturnDetailState.initial()) {
    unawaited(load());
  }

  final OrdersRepository _repository;
  final String returnId;

  Future<void> load() async {
    state = const ReturnDetailState.loadInProgress();
    final either = await _repository.getReturn(returnId);
    if (!mounted) return;
    state = either.fold(
      ReturnDetailState.loadFailure,
      ReturnDetailState.loadSuccess,
    );
  }

  /// Pull-to-refresh; a failed refresh keeps the return on screen.
  Future<void> refresh() async {
    final hasData = state.maybeWhen(
      loadSuccess: (_) => true,
      orElse: () => false,
    );
    if (!hasData) return load();
    final either = await _repository.getReturn(returnId);
    if (!mounted) return;
    either.fold((_) {}, (r) => state = ReturnDetailState.loadSuccess(r));
  }
}
