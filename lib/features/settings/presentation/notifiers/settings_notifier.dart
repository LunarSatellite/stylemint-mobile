import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/deletion_request.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/settings_repository.dart';

part 'settings_notifier.freezed.dart';

@freezed
abstract class NotificationPrefsState with _$NotificationPrefsState {
  const NotificationPrefsState._();

  const factory NotificationPrefsState.initial() = _NpInitial;
  const factory NotificationPrefsState.loadInProgress() = _NpLoadInProgress;
  const factory NotificationPrefsState.loadSuccess(NotificationPreferences prefs) = _NpLoadSuccess;
  const factory NotificationPrefsState.loadFailure(NetworkExceptions failure) = _NpLoadFailure;
  const factory NotificationPrefsState.saveSuccess() = _NpSaveSuccess;
  const factory NotificationPrefsState.saveFailure(NetworkExceptions failure) = _NpSaveFailure;
}

class SettingsNotifier extends StateNotifier<NotificationPrefsState> {
  SettingsNotifier(this._repository) : super(const NotificationPrefsState.initial()) {
    unawaited(loadPrefs());
  }

  final SettingsRepository _repository;

  Future<void> loadPrefs() async {
    state = const NotificationPrefsState.loadInProgress();
    final either = await _repository.getNotificationPreferences();
    state = either.fold(
      NotificationPrefsState.loadFailure,
      NotificationPrefsState.loadSuccess,
    );
  }

  Future<void> savePrefs(NotificationPreferences prefs) async {
    state = NotificationPrefsState.loadSuccess(prefs);
    final either = await _repository.updateNotificationPreferences(prefs);
    state = either.fold(
      NotificationPrefsState.saveFailure,
      // Use the prefs we already have (which the user interacted with) rather
      // than round-tripping through toDomain() which would reset pushEnabled.
      (_) => NotificationPrefsState.loadSuccess(prefs),
    );
  }
}

@freezed
abstract class LanguageChangeState with _$LanguageChangeState {
  const LanguageChangeState._();

  const factory LanguageChangeState.initial() = _LangInitial;
  const factory LanguageChangeState.saving() = _LangSaving;
  const factory LanguageChangeState.success(String code) = _LangSuccess;
  const factory LanguageChangeState.failure(NetworkExceptions failure) = _LangFailure;
}

class LanguageChangeNotifier extends StateNotifier<LanguageChangeState> {
  LanguageChangeNotifier(this._repository) : super(const LanguageChangeState.initial());

  final SettingsRepository _repository;

  Future<void> changeLanguage(String languageCode) async {
    state = const LanguageChangeState.saving();
    final either = await _repository.setLanguage(languageCode);
    state = either.fold(
      LanguageChangeState.failure,
      (_) => LanguageChangeState.success(languageCode),
    );
  }
}

@freezed
abstract class DeleteAccountState with _$DeleteAccountState {
  const DeleteAccountState._();

  const factory DeleteAccountState.initial() = _DelInitial;
  const factory DeleteAccountState.inProgress() = _DelInProgress;
  const factory DeleteAccountState.success() = _DelSuccess;
  const factory DeleteAccountState.failure(NetworkExceptions failure) = _DelFailure;
}

class DeleteAccountNotifier extends StateNotifier<DeleteAccountState> {
  DeleteAccountNotifier(this._repository) : super(const DeleteAccountState.initial());

  final SettingsRepository _repository;

  Future<void> deleteAccount(String reason) async {
    state = const DeleteAccountState.inProgress();
    final either = await _repository.deleteAccount(const Uuid().v4(), reason);
    state = either.fold(
      DeleteAccountState.failure,
      (_) => const DeleteAccountState.success(),
    );
  }
}

@freezed
abstract class LogoutState with _$LogoutState {
  const LogoutState._();

  const factory LogoutState.initial() = _LogoutInitial;
  const factory LogoutState.inProgress() = _LogoutInProgress;
  const factory LogoutState.success() = _LogoutSuccess;
  const factory LogoutState.failure(NetworkExceptions failure) = _LogoutFailure;
}

class LogoutNotifier extends StateNotifier<LogoutState> {
  LogoutNotifier(this._repository) : super(const LogoutState.initial());

  final SettingsRepository _repository;

  Future<void> logout() async {
    state = const LogoutState.inProgress();
    final either = await _repository.logout();
    state = either.fold(
      LogoutState.failure,
      (_) => const LogoutState.success(),
    );
  }
}

// ── Pending Deletion ─────────────────────────────────────────────────────────

@freezed
abstract class PendingDeletionState with _$PendingDeletionState {
  const PendingDeletionState._();

  const factory PendingDeletionState.initial() = _PdInitial;
  const factory PendingDeletionState.loading() = _PdLoading;
  const factory PendingDeletionState.found(DeletionRequest request) = _PdFound;
  const factory PendingDeletionState.notFound() = _PdNotFound;
  const factory PendingDeletionState.cancelling() = _PdCancelling;
  const factory PendingDeletionState.cancelled() = _PdCancelled;
  const factory PendingDeletionState.failure(NetworkExceptions failure) = _PdFailure;
}

class PendingDeletionNotifier extends StateNotifier<PendingDeletionState> {
  PendingDeletionNotifier(this._repository)
      : super(const PendingDeletionState.initial());

  final SettingsRepository _repository;

  Future<void> load() async {
    state = const PendingDeletionState.loading();
    final either = await _repository.getPendingDeletion();
    state = either.fold(
      PendingDeletionState.failure,
      (r) => r == null
          ? const PendingDeletionState.notFound()
          : PendingDeletionState.found(r),
    );
  }

  Future<void> cancel(String requestId) async {
    state = const PendingDeletionState.cancelling();
    final either = await _repository.cancelDeletion(requestId);
    state = either.fold(
      PendingDeletionState.failure,
      (_) => const PendingDeletionState.cancelled(),
    );
  }
}

