import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_balance.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/repositories/wallet_repository.dart';

part 'wallet_notifier.freezed.dart';

@freezed
abstract class WalletState with _$WalletState {
  const factory WalletState.initial() = _Initial;
  const factory WalletState.loading() = _Loading;
  const factory WalletState.loaded({
    required WalletBalance balance,
    required List<WalletTransaction> transactions,
    @Default(false) bool loadingMore,
    @Default(true) bool hasMore,
  }) = WalletLoaded;
  const factory WalletState.failure(NetworkExceptions failure) = _Failure;
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier(this._repository) : super(const WalletState.initial()) {
    unawaited(load());
  }

  final WalletRepository _repository;
  static const _pageSize = 20;

  Future<void> load() async {
    state = const WalletState.loading();
    final balanceResult = await _repository.getBalance();
    balanceResult.fold(
      (f) => state = WalletState.failure(f),
      (balance) async {
        final txResult = await _repository.getTransactions(
          balance.id,
          take: _pageSize,
        );
        state = txResult.fold(
          (f) => WalletState.failure(f),
          (txs) {
            final visible = txs.where((t) => t.isVisible).toList();
            return WalletState.loaded(
              balance: balance,
              transactions: visible,
              hasMore: txs.length >= _pageSize,
            );
          },
        );
      },
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! WalletLoaded || current.loadingMore || !current.hasMore) return;

    state = current.copyWith(loadingMore: true);
    final last = current.transactions.lastOrNull;
    final result = await _repository.getTransactions(
      current.balance.id,
      take: _pageSize,
      untilUtc: last?.occurredUtc,
    );
    result.fold(
      (_) => state = current.copyWith(loadingMore: false),
      (txs) {
        final visible = txs.where((t) => t.isVisible).toList();
        state = current.copyWith(
          transactions: [...current.transactions, ...visible],
          loadingMore: false,
          hasMore: txs.length >= _pageSize,
        );
      },
    );
  }
}
