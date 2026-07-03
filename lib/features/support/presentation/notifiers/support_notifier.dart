import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/repositories/support_repository.dart';

part 'support_notifier.freezed.dart';

// ── Tickets list ──────────────────────────────────────────────────────────────

@freezed
abstract class TicketsState with _$TicketsState {
  const TicketsState._();

  const factory TicketsState.initial() = _TicketsInitial;
  const factory TicketsState.loadInProgress() = _TicketsLoadInProgress;
  const factory TicketsState.loadSuccess(List<Ticket> tickets) =
      _TicketsLoadSuccess;
  const factory TicketsState.loadFailure(NetworkExceptions failure) =
      _TicketsLoadFailure;
}

class SupportNotifier extends StateNotifier<TicketsState> {
  SupportNotifier(this._repository) : super(const TicketsState.initial());

  final SupportRepository _repository;

  Future<void> loadTickets({int skip = 0, int take = 20}) async {
    state = const TicketsState.loadInProgress();
    final either =
        await _repository.getTickets(skip: skip, take: take);
    state = either.fold(
      TicketsState.loadFailure,
      TicketsState.loadSuccess,
    );
  }
}

// ── Create ticket ─────────────────────────────────────────────────────────────

@freezed
abstract class CreateTicketState with _$CreateTicketState {
  const CreateTicketState._();

  const factory CreateTicketState.initial() = _CreateInitial;
  const factory CreateTicketState.submitting() = _CreateSubmitting;
  const factory CreateTicketState.success() = _CreateSuccess;
  const factory CreateTicketState.failure(NetworkExceptions failure) =
      _CreateFailure;
}

class CreateTicketNotifier extends StateNotifier<CreateTicketState> {
  CreateTicketNotifier(this._repository)
      : super(const CreateTicketState.initial());

  final SupportRepository _repository;

  Future<void> submit({
    required SupportTicketCategory category,
    String? body,
    List<String> attachmentUrls = const [],
    String? orderId,
    String? subOrderId,
    String? returnRequestId,
  }) async {
    state = const CreateTicketState.submitting();
    final either = await _repository.createTicket(
      category: category,
      subject: category.label,
      body: body,
      attachmentUrls: attachmentUrls,
      orderId: orderId,
      subOrderId: subOrderId,
      returnRequestId: returnRequestId,
    );
    state = either.fold(
      CreateTicketState.failure,
      (_) => const CreateTicketState.success(),
    );
  }

  void reset() => state = const CreateTicketState.initial();
}

// ── Reply to ticket ───────────────────────────────────────────────────────────

@freezed
abstract class ReplyTicketState with _$ReplyTicketState {
  const ReplyTicketState._();

  const factory ReplyTicketState.initial() = _ReplyInitial;
  const factory ReplyTicketState.submitting() = _ReplySubmitting;
  const factory ReplyTicketState.success() = _ReplySuccess;
  const factory ReplyTicketState.failure(NetworkExceptions failure) =
      _ReplyFailure;
}

class ReplyTicketNotifier extends StateNotifier<ReplyTicketState> {
  ReplyTicketNotifier(this._repository, this._ticketNumber)
      : super(const ReplyTicketState.initial());

  final SupportRepository _repository;
  final String _ticketNumber;

  Future<void> submit({
    required String body,
    List<String> attachmentUrls = const [],
  }) async {
    state = const ReplyTicketState.submitting();
    final either = await _repository.replyToTicket(
      ticketNumber: _ticketNumber,
      body: body,
      attachmentUrls: attachmentUrls,
    );
    state = either.fold(
      ReplyTicketState.failure,
      (_) => const ReplyTicketState.success(),
    );
  }

  void reset() => state = const ReplyTicketState.initial();
}
