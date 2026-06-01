import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/repositories/social_connect_repository.dart';

part 'social_connect_notifier.freezed.dart';

@freezed
abstract class SocialConnectState with _$SocialConnectState {
  const SocialConnectState._();

  const factory SocialConnectState.initial() = _SocialConnectInitial;
  const factory SocialConnectState.loadInProgress() =
      _SocialConnectLoadInProgress;
  const factory SocialConnectState.loadSuccess(
    List<SocialAccount> accounts,
  ) = _SocialConnectLoadSuccess;
  const factory SocialConnectState.loadFailure(NetworkExceptions failure) =
      _SocialConnectLoadFailure;
}

class SocialConnectNotifier extends StateNotifier<SocialConnectState> {
  SocialConnectNotifier(this._repository)
    : super(const SocialConnectState.initial()) {
    unawaited(load());
  }

  final SocialConnectRepository _repository;

  Future<void> load() async {
    state = const SocialConnectState.loadInProgress();
    final either = await _repository.getConnectedAccounts();
    state = either.fold(
      SocialConnectState.loadFailure,
      SocialConnectState.loadSuccess,
    );
  }

  Future<void> connect(SocialPlatform platform, String authCode) async {
    final either = await _repository.connectPlatform(
      platform,
      authCode,
      'stylemint://callback',
    );
    either.fold(
      (_) => null,
      (_) => unawaited(load()),
    );
  }

  Future<void> disconnect(String accountId) async {
    final either = await _repository.disconnectPlatform(accountId);
    either.fold(
      (_) => null,
      (_) => unawaited(load()),
    );
  }
}
