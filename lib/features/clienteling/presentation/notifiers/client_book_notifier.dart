import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/repositories/clienteling_repository.dart';

part 'client_book_notifier.freezed.dart';

@freezed
abstract class ClientBookState with _$ClientBookState {
  const factory ClientBookState.initial() = ClientBookInitial;
  const factory ClientBookState.loadInProgress() = ClientBookLoadInProgress;

  /// An empty [clients] list means this account has been assigned no clients —
  /// which is also what a shopper who is not a store associate sees.
  const factory ClientBookState.loadSuccess({
    required List<ClientAssignment> clients,
    String? nextCursor,
    @Default(false) bool isLoadingMore,
  }) = ClientBookLoadSuccess;

  const factory ClientBookState.loadFailure(NetworkExceptions failure) =
      ClientBookLoadFailure;
}

/// Drives `GET /v1/clienteling/associate/clients`.
class ClientBookNotifier extends StateNotifier<ClientBookState> {
  ClientBookNotifier(this._repository, {this.pageSize = 20})
    : super(const ClientBookState.initial()) {
    unawaited(load());
  }

  final AssociateClientelingRepository _repository;
  final int pageSize;

  Future<void> load() async {
    state = const ClientBookState.loadInProgress();
    final either = await _repository.listMyClients(pageSize: pageSize);
    if (!mounted) return;
    state = either.fold(
      ClientBookState.loadFailure,
      (page) => ClientBookState.loadSuccess(
        clients: page.items,
        nextCursor: page.nextCursor,
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ClientBookLoadSuccess) return;
    final cursor = current.nextCursor;
    if (cursor == null || cursor.isEmpty || current.isLoadingMore) return;

    state = current.copyWith(isLoadingMore: true);
    final either = await _repository.listMyClients(
      cursor: cursor,
      pageSize: pageSize,
    );
    if (!mounted) return;
    state = either.fold(
      // A failed page-2 keeps page 1 on screen rather than replacing the
      // whole list with an error.
      (_) => current.copyWith(isLoadingMore: false),
      (page) => ClientBookState.loadSuccess(
        clients: [...current.clients, ...page.items],
        nextCursor: page.nextCursor,
      ),
    );
  }
}
