import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/repositories/vendor_partnerships_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

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
  const factory CreatorSearchState.loadInProgress() = _CreatorSearchLoadInProgress;
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
    List<String>? categories,
  }) async {
    state = const CreatorSearchState.loadInProgress();
    final result = await _repository.searchCreators(
      query: query,
      categories: categories,
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

  Future<void> invite(String campaignId, String creatorId) async {
    state = const InviteState.submitting();
    final result = await _repository.inviteCreator(campaignId, creatorId);
    state = result.fold(InviteState.failure, (_) => const InviteState.success());
  }

  void reset() {
    state = const InviteState.initial();
  }
}
