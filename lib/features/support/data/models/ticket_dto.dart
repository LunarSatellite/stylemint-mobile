import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';

part 'ticket_dto.freezed.dart';
part 'ticket_dto.g.dart';

@freezed
abstract class TicketDto with _$TicketDto {
  const factory TicketDto({
    required String id,
    required String ticketNumber,
    required int category,
    required String subject,
    required int state,
    required DateTime openedUtc,
    DateTime? lastAgentReplyUtc,
  }) = _TicketDto;

  const TicketDto._();

  factory TicketDto.fromJson(Map<String, dynamic> json) =>
      _$TicketDtoFromJson(json);

  Ticket toDomain() => Ticket(
        id: id,
        ticketNumber: ticketNumber,
        category: _parseCategory(category),
        subject: subject,
        status: _parseState(state),
        createdAt: openedUtc,
        lastAgentReplyAt: lastAgentReplyUtc,
      );

  static SupportTicketCategory _parseCategory(int v) {
    return SupportTicketCategory.values.firstWhere(
      (c) => c.value == v,
      orElse: () => SupportTicketCategory.general,
    );
  }

  static TicketStatus _parseState(int s) => switch (s) {
        1 => TicketStatus.inProgress,
        2 => TicketStatus.resolved,
        3 => TicketStatus.closed,
        _ => TicketStatus.open,
      };
}
