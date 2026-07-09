import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/ticket.dart';

part 'ticket_dto.freezed.dart';
part 'ticket_dto.g.dart';

/// Mirrors `SupportTicketSummaryDto`/`SupportTicketDto` — `state` and
/// `category` are the backend's int-valued enums (1-based), not strings.
@freezed
abstract class TicketDto with _$TicketDto {
  const factory TicketDto({
    required String id,
    required String ticketNumber,
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
    subject: subject,
    status: _statusFromWire(state),
    createdAt: openedUtc,
    lastUpdated: lastAgentReplyUtc ?? openedUtc,
    // Backend list/detail projections don't carry a preview snippet.
    lastMessagePreview: null,
  );

  static TicketStatus _statusFromWire(int state) => switch (state) {
    2 => TicketStatus.inProgress,
    3 => TicketStatus.resolved,
    _ => TicketStatus.open,
  };
}

@freezed
abstract class SupportCategoryDto with _$SupportCategoryDto {
  const factory SupportCategoryDto({
    required String id,
    required String title,
    required String iconName,
    @Default('') String description,
  }) = _SupportCategoryDto;

  const SupportCategoryDto._();

  factory SupportCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$SupportCategoryDtoFromJson(json);

  SupportCategory toDomain() => SupportCategory(
    id: id,
    title: title,
    iconName: iconName,
    description: description,
  );
}
