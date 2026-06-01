import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/repositories/support_repository.dart';

part 'support_notifier.freezed.dart';

@freezed
abstract class TicketsState with _$TicketsState {
  const TicketsState._();

  const factory TicketsState.initial() = _TicketsInitial;
  const factory TicketsState.loadInProgress() = _TicketsLoadInProgress;
  const factory TicketsState.loadSuccess(List<Ticket> tickets) = _TicketsLoadSuccess;
  const factory TicketsState.loadFailure(NetworkExceptions failure) = _TicketsLoadFailure;
}

@freezed
abstract class CategoriesState with _$CategoriesState {
  const CategoriesState._();

  const factory CategoriesState.initial() = _CatInitial;
  const factory CategoriesState.loadInProgress() = _CatLoadInProgress;
  const factory CategoriesState.loadSuccess(List<SupportCategory> categories) = _CatLoadSuccess;
  const factory CategoriesState.loadFailure(NetworkExceptions failure) = _CatLoadFailure;
}

@freezed
abstract class CreateTicketState with _$CreateTicketState {
  const CreateTicketState._();

  const factory CreateTicketState.initial() = _CreateInitial;
  const factory CreateTicketState.submitting() = _CreateSubmitting;
  const factory CreateTicketState.success(Ticket ticket) = _CreateSuccess;
  const factory CreateTicketState.failure(NetworkExceptions failure) = _CreateFailure;
}

class SupportNotifier extends StateNotifier<TicketsState> {
  SupportNotifier(this._repository) : super(const TicketsState.initial());

  final SupportRepository _repository;

  Future<void> loadTickets() async {
    state = const TicketsState.loadInProgress();
    final either = await _repository.getTickets();
    state = either.fold(
      TicketsState.loadFailure,
      TicketsState.loadSuccess,
    );
  }

  Future<void> createTicket({
    required String subject,
    required String message,
    String? categoryId,
  }) async {
    final either = await _repository.createTicket(
      subject: subject,
      message: message,
      categoryId: categoryId,
    );
    either.fold(
      (_) => null,
      (_) => loadTickets(),
    );
  }
}

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  CategoriesNotifier(this._repository) : super(const CategoriesState.initial()) {
    unawaited(load());
  }

  final SupportRepository _repository;

  Future<void> load() async {
    state = const CategoriesState.loadInProgress();
    final either = await _repository.getSupportCategories();
    state = either.fold(
      CategoriesState.loadFailure,
      CategoriesState.loadSuccess,
    );
  }
}

class CreateTicketNotifier extends StateNotifier<CreateTicketState> {
  CreateTicketNotifier(this._repository) : super(const CreateTicketState.initial());

  final SupportRepository _repository;

  Future<void> submit({
    required String subject,
    required String message,
    String? categoryId,
  }) async {
    state = const CreateTicketState.submitting();
    final either = await _repository.createTicket(
      subject: subject,
      message: message,
      categoryId: categoryId,
    );
    state = either.fold(
      CreateTicketState.failure,
      CreateTicketState.success,
    );
  }
}
