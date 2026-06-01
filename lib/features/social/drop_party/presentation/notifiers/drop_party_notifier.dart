import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/repositories/drop_party_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'drop_party_notifier.freezed.dart';

@freezed
abstract class DropPartiesState with _$DropPartiesState {
  const DropPartiesState._();

  const factory DropPartiesState.initial() = _DropPartiesInitial;
  const factory DropPartiesState.loadInProgress() = _DropPartiesLoadInProgress;
  const factory DropPartiesState.loadSuccess(List<DropParty> parties) =
      _DropPartiesLoadSuccess;
  const factory DropPartiesState.loadFailure(NetworkExceptions failure) =
      _DropPartiesLoadFailure;
}

@freezed
abstract class DropPartyDetailState with _$DropPartyDetailState {
  const DropPartyDetailState._();

  const factory DropPartyDetailState.initial() = _DropPartyDetailInitial;
  const factory DropPartyDetailState.loadInProgress() =
      _DropPartyDetailLoadInProgress;
  const factory DropPartyDetailState.loadSuccess(DropParty party) =
      _DropPartyDetailLoadSuccess;
  const factory DropPartyDetailState.loadFailure(NetworkExceptions failure) =
      _DropPartyDetailLoadFailure;
}

class DropPartyNotifier extends StateNotifier<DropPartiesState> {
  DropPartyNotifier(this._repository)
      : super(const DropPartiesState.initial()) {
    unawaited(loadAll());
  }

  final DropPartyRepository _repository;

  Future<void> loadAll() async {
    state = const DropPartiesState.loadInProgress();
    final either = await _repository.getActiveDropParties();
    state = either.fold(
      DropPartiesState.loadFailure,
      DropPartiesState.loadSuccess,
    );
  }

  Future<Either<NetworkExceptions, DropParty>> create({
    required String title,
    required String description,
    required String productId,
    required Money dropPrice,
    required int maxParticipants,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final either = await _repository.createDropParty(
      title: title,
      description: description,
      productId: productId,
      dropPrice: dropPrice,
      maxParticipants: maxParticipants,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    either.fold(
      (_) {},
      (_) => unawaited(loadAll()),
    );
    return either;
  }

  Future<Either<NetworkExceptions, DropParty>> join(String partyId) async {
    final either = await _repository.joinDropParty(partyId);
    either.fold(
      (_) {},
      (_) => unawaited(loadAll()),
    );
    return either;
  }

  Future<Either<NetworkExceptions, Unit>> invite(String partyId, List<String> userIds) async {
    return _repository.inviteToParty(partyId, userIds);
  }

  Future<Either<NetworkExceptions, DropParty>> scanQr(String qrCode) async {
    final either = await _repository.scanInviteQr(qrCode);
    either.fold(
      (_) {},
      (_) => unawaited(loadAll()),
    );
    return either;
  }
}

class DropPartyDetailNotifier extends StateNotifier<DropPartyDetailState> {
  DropPartyDetailNotifier(this._repository, String partyId)
      : super(const DropPartyDetailState.initial()) {
    unawaited(loadParty(partyId));
  }

  final DropPartyRepository _repository;

  Future<void> loadParty(String partyId) async {
    state = const DropPartyDetailState.loadInProgress();
    final either = await _repository.getDropParty(partyId);
    state = either.fold(
      DropPartyDetailState.loadFailure,
      DropPartyDetailState.loadSuccess,
    );
  }

  Future<Either<NetworkExceptions, DropParty>> join(String partyId) async {
    final either = await _repository.joinDropParty(partyId);
    either.fold(
      (_) {},
      (party) => state = DropPartyDetailState.loadSuccess(party),
    );
    return either;
  }

  Future<Either<NetworkExceptions, Unit>> invite(String partyId, List<String> userIds) async {
    return _repository.inviteToParty(partyId, userIds);
  }
}
