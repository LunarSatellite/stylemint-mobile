import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/entities/tip.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/repositories/tips_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'tips_notifier.freezed.dart';

@freezed
abstract class TipHistoryState with _$TipHistoryState {
  const TipHistoryState._();

  const factory TipHistoryState.initial() = _TipHistoryInitial;
  const factory TipHistoryState.loadInProgress() = _TipHistoryLoadInProgress;
  const factory TipHistoryState.loadSuccess(List<Tip> tips) =
      _TipHistoryLoadSuccess;
  const factory TipHistoryState.loadFailure(NetworkExceptions failure) =
      _TipHistoryLoadFailure;
}

@freezed
abstract class TipBalanceState with _$TipBalanceState {
  const TipBalanceState._();

  const factory TipBalanceState.initial() = _TipBalanceInitial;
  const factory TipBalanceState.loadInProgress() = _TipBalanceLoadInProgress;
  const factory TipBalanceState.loadSuccess(TipBalance balance) =
      _TipBalanceLoadSuccess;
  const factory TipBalanceState.loadFailure(NetworkExceptions failure) =
      _TipBalanceLoadFailure;
}

@freezed
abstract class TipSendState with _$TipSendState {
  const TipSendState._();

  const factory TipSendState.initial() = _TipSendInitial;
  const factory TipSendState.loadInProgress() = _TipSendLoadInProgress;
  const factory TipSendState.loadSuccess(Tip tip) = _TipSendLoadSuccess;
  const factory TipSendState.loadFailure(NetworkExceptions failure) =
      _TipSendLoadFailure;
}

class TipsNotifier extends StateNotifier<TipHistoryState> {
  TipsNotifier(this._repository) : super(const TipHistoryState.initial()) {
    unawaited(loadHistory(type: 'sent'));
  }

  final TipsRepository _repository;

  Future<void> loadHistory({required String type}) async {
    state = const TipHistoryState.loadInProgress();
    final either = await _repository.getTipHistory(type: type);
    state = either.fold(
      TipHistoryState.loadFailure,
      TipHistoryState.loadSuccess,
    );
  }

  Future<Either<NetworkExceptions, Tip>> sendTip({
    required String creatorId,
    required Money amount,
    String? message,
    String? reelId,
  }) async {
    final either = await _repository.sendTip(
      creatorId: creatorId,
      amount: amount,
      message: message,
      reelId: reelId,
    );
    either.fold(
      (_) {},
      (_) => unawaited(loadHistory(type: 'sent')),
    );
    return either;
  }
}

class TipBalanceNotifier extends StateNotifier<TipBalanceState> {
  TipBalanceNotifier(this._repository)
      : super(const TipBalanceState.initial()) {
    unawaited(loadBalance());
  }

  final TipsRepository _repository;

  Future<void> loadBalance() async {
    state = const TipBalanceState.loadInProgress();
    final either = await _repository.getBalance();
    state = either.fold(
      TipBalanceState.loadFailure,
      TipBalanceState.loadSuccess,
    );
  }
}
