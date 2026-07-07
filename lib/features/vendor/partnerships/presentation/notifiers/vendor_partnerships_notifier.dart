import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/repositories/vendor_partnerships_repository.dart';

part 'vendor_partnerships_notifier.freezed.dart';

@freezed
abstract class CampaignsState with _$CampaignsState {
  const CampaignsState._();

  const factory CampaignsState.initial() = _CampaignsInitial;
  const factory CampaignsState.loadInProgress() = _CampaignsLoadInProgress;
  const factory CampaignsState.loadSuccess({
    required List<CampaignBrief> campaigns,
  }) = _CampaignsLoadSuccess;
  const factory CampaignsState.loadFailure(NetworkExceptions failure) =
      _CampaignsLoadFailure;
}

@freezed
abstract class CreatorSearchState with _$CreatorSearchState {
  const CreatorSearchState._();

  const factory CreatorSearchState.initial() = _CreatorSearchInitial;
  const factory CreatorSearchState.loadInProgress() =
      _CreatorSearchLoadInProgress;
  const factory CreatorSearchState.loadSuccess({
    required List<CreatorInvite> creators,
  }) = _CreatorSearchLoadSuccess;
  const factory CreatorSearchState.loadFailure(NetworkExceptions failure) =
      _CreatorSearchLoadFailure;
}

@freezed
abstract class InviteState with _$InviteState {
  const InviteState._();

  const factory InviteState.initial() = _InviteInitial;
  const factory InviteState.submitting() = _InviteSubmitting;
  const factory InviteState.success() = _InviteSuccess;
  const factory InviteState.failure(NetworkExceptions failure) = _InviteFailure;
}

class VendorPartnershipsNotifier extends StateNotifier<CampaignsState> {
  VendorPartnershipsNotifier(this._repository)
    : super(const CampaignsState.initial()) {
    unawaited(loadCampaigns());
  }

  final VendorPartnershipsRepository _repository;

  Future<void> loadCampaigns() async {
    state = const CampaignsState.loadInProgress();
    final result = await _repository.getCampaigns();
    state = result.fold(
      CampaignsState.loadFailure,
      (campaigns) => CampaignsState.loadSuccess(campaigns: campaigns),
    );
  }

  Future<void> createCampaign(CampaignBrief brief) async {
    await _repository.createCampaign(brief);
    unawaited(loadCampaigns());
  }

  Future<void> updateCampaign(String id, CampaignBrief brief) async {
    await _repository.updateCampaign(id, brief);
    unawaited(loadCampaigns());
  }
}

class CreatorSearchNotifier extends StateNotifier<CreatorSearchState> {
  CreatorSearchNotifier(this._repository)
    : super(const CreatorSearchState.initial());

  final VendorPartnershipsRepository _repository;

  Future<void> searchCreators({
    String? query,
    String? niche,
  }) async {
    state = const CreatorSearchState.loadInProgress();
    final result = await _repository.searchCreators(
      query: query,
      niche: niche,
    );
    state = result.fold(
      CreatorSearchState.loadFailure,
      (creators) => CreatorSearchState.loadSuccess(creators: creators),
    );
  }
}

class InviteCreatorNotifier extends StateNotifier<InviteState> {
  InviteCreatorNotifier(this._repository) : super(const InviteState.initial());

  final VendorPartnershipsRepository _repository;

  Future<void> invite({
    required String creatorProfileId,
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? brandBriefId,
    String? message,
  }) async {
    state = const InviteState.submitting();
    final result = await _repository.inviteCreator(
      creatorProfileId: creatorProfileId,
      commissionMinPercent: commissionMinPercent,
      commissionMaxPercent: commissionMaxPercent,
      brandBriefId: brandBriefId,
      message: message,
    );
    state = result.fold(
      InviteState.failure,
      (_) => const InviteState.success(),
    );
  }

  void reset() {
    state = const InviteState.initial();
  }
}

@freezed
abstract class PartnershipsState with _$PartnershipsState {
  const PartnershipsState._();

  const factory PartnershipsState.initial() = _PartnershipsInitial;
  const factory PartnershipsState.loadInProgress() =
      _PartnershipsLoadInProgress;
  const factory PartnershipsState.loadSuccess(
    List<VendorPartnership> partnerships, {
    required bool hasMore,
  }) = _PartnershipsLoadSuccess;
  const factory PartnershipsState.loadFailure(NetworkExceptions failure) =
      _PartnershipsLoadFailure;
  const factory PartnershipsState.actionInProgress(
    List<VendorPartnership> partnerships,
  ) = _PartnershipsActionInProgress;
  const factory PartnershipsState.actionFailure(
    List<VendorPartnership> partnerships,
    NetworkExceptions failure,
  ) = _PartnershipsActionFailure;
}

class PartnershipsListNotifier extends StateNotifier<PartnershipsState> {
  PartnershipsListNotifier(this._repository)
    : super(const PartnershipsState.initial()) {
    unawaited(load());
  }

  final VendorPartnershipsRepository _repository;
  String? _nextCursor;

  Future<void> load({List<PartnershipState>? states}) async {
    state = const PartnershipsState.loadInProgress();
    final result = await _repository.getPartnerships(states: states);
    state = result.fold(PartnershipsState.loadFailure, (paged) {
      _nextCursor = paged.nextCursor;
      return PartnershipsState.loadSuccess(
        paged.items,
        hasMore: paged.hasMore,
      );
    });
  }

  Future<bool> _mutate(
    List<VendorPartnership> current,
    Future<Either<NetworkExceptions, Unit>> Function() action,
  ) async {
    state = PartnershipsState.actionInProgress(current);
    final result = await action();
    final ok = result.fold((f) {
      state = PartnershipsState.actionFailure(current, f);
      return false;
    }, (_) => true);
    await load();
    return ok;
  }

  Future<bool> acceptRequest(String id) => state.maybeWhen(
    loadSuccess: (partnerships, _) =>
        _mutate(partnerships, () => _repository.acceptRequest(id)),
    orElse: () async => false,
  );

  Future<bool> declineRequest(String id) => state.maybeWhen(
    loadSuccess: (partnerships, _) =>
        _mutate(partnerships, () => _repository.declineRequest(id)),
    orElse: () async => false,
  );

  Future<bool> pause(String id, {String? reason}) => state.maybeWhen(
    loadSuccess: (partnerships, _) =>
        _mutate(partnerships, () => _repository.pause(id, reason: reason)),
    orElse: () async => false,
  );

  Future<bool> resume(String id) => state.maybeWhen(
    loadSuccess: (partnerships, _) =>
        _mutate(partnerships, () => _repository.resume(id)),
    orElse: () async => false,
  );

  Future<bool> end(String id, {String? reason}) => state.maybeWhen(
    loadSuccess: (partnerships, _) =>
        _mutate(partnerships, () => _repository.end(id, reason: reason)),
    orElse: () async => false,
  );

  Future<bool> adjustCommission(
    String id, {
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? reason,
  }) => state.maybeWhen(
    loadSuccess: (partnerships, _) => _mutate(
      partnerships,
      () => _repository.adjustCommission(
        id,
        commissionMinPercent: commissionMinPercent,
        commissionMaxPercent: commissionMaxPercent,
        reason: reason,
      ),
    ),
    orElse: () async => false,
  );
}
