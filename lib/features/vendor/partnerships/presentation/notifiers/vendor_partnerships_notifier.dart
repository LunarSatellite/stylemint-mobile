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

  /// Returns the created brief (with its real id) on success, or null on
  /// failure — callers need the id to navigate to the detail screen and
  /// to chain the follow-up [updateCampaign] call that sets commission/
  /// budget (the draft endpoint only accepts title/goal/currency).
  Future<CampaignBrief?> createCampaign(CampaignBrief brief) async {
    final either = await _repository.createCampaign(brief);
    unawaited(loadCampaigns());
    return either.fold((_) => null, (created) => created);
  }

  Future<bool> updateCampaign(String id, CampaignBrief brief) async {
    final either = await _repository.updateCampaign(id, brief);
    unawaited(loadCampaigns());
    return either.isRight();
  }
}

@freezed
abstract class CampaignDetailState with _$CampaignDetailState {
  const CampaignDetailState._();

  const factory CampaignDetailState.initial() = _CampaignDetailInitial;
  const factory CampaignDetailState.loadInProgress() =
      _CampaignDetailLoadInProgress;
  const factory CampaignDetailState.loadSuccess(CampaignBrief brief) =
      _CampaignDetailLoadSuccess;
  const factory CampaignDetailState.loadFailure(NetworkExceptions failure) =
      _CampaignDetailLoadFailure;
  const factory CampaignDetailState.actionInProgress(CampaignBrief brief) =
      _CampaignDetailActionInProgress;
  const factory CampaignDetailState.actionFailure(
    CampaignBrief brief,
    NetworkExceptions failure,
  ) = _CampaignDetailActionFailure;

  /// Emitted once after a successful fork — `brief` is the NEW draft
  /// (`version + 1`), distinct from the source brief being viewed.
  const factory CampaignDetailState.forked(CampaignBrief brief) =
      _CampaignDetailForked;
}

/// Drives the lifecycle actions on a single brief: lock (Vendor §3.1),
/// fork, retire, and recompute-roi. List/create/update stay on
/// [VendorPartnershipsNotifier]; this notifier is scoped to one brief id.
class CampaignDetailNotifier extends StateNotifier<CampaignDetailState> {
  CampaignDetailNotifier(this._repository, this.briefId)
    : super(const CampaignDetailState.initial()) {
    unawaited(load());
  }

  final VendorPartnershipsRepository _repository;
  final String briefId;

  Future<void> load() async {
    state = const CampaignDetailState.loadInProgress();
    final result = await _repository.getCampaign(briefId);
    state = result.fold(
      CampaignDetailState.loadFailure,
      CampaignDetailState.loadSuccess,
    );
  }

  Future<void> lock() =>
      _mutate((b) => _repository.lockCampaign(b.id));

  Future<void> retire() =>
      _mutate((b) => _repository.retireCampaign(b.id));

  Future<void> recomputeRoi() async {
    final current = _currentBrief;
    if (current == null) return;
    state = CampaignDetailState.actionInProgress(current);
    final result = await _repository.recomputeRoi(current.id);
    state = result.fold(
      (f) => CampaignDetailState.actionFailure(current, f),
      (roi) => CampaignDetailState.loadSuccess(
        current.copyWith(roiProjection: roi),
      ),
    );
  }

  /// On success the returned state carries the NEW forked draft — the
  /// screen should navigate to it, not keep showing the source brief.
  Future<void> fork() async {
    final current = _currentBrief;
    if (current == null) return;
    state = CampaignDetailState.actionInProgress(current);
    final result = await _repository.forkCampaign(current.id);
    state = result.fold(
      (f) => CampaignDetailState.actionFailure(current, f),
      CampaignDetailState.forked,
    );
  }

  CampaignBrief? get _currentBrief => state.maybeWhen(
    loadSuccess: (b) => b,
    actionFailure: (b, _) => b,
    forked: (b) => b,
    orElse: () => null,
  );

  Future<void> _mutate(
    Future<Either<NetworkExceptions, CampaignBrief>> Function(CampaignBrief)
    action,
  ) async {
    final current = _currentBrief;
    if (current == null) return;
    state = CampaignDetailState.actionInProgress(current);
    final result = await action(current);
    state = result.fold(
      (f) => CampaignDetailState.actionFailure(current, f),
      CampaignDetailState.loadSuccess,
    );
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
