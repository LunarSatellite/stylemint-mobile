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
    required String subject,
    required String status,
    required DateTime createdAt,
    required DateTime lastUpdated,
    String? lastMessagePreview,
  }) = _TicketDto;

  const TicketDto._();

  factory TicketDto.fromJson(Map<String, dynamic> json) =>
      _$TicketDtoFromJson(json);

  Ticket toDomain() => Ticket(
    id: id,
    ticketNumber: ticketNumber,
    subject: subject,
    status: _parseStatus(status),
    createdAt: createdAt,
    lastUpdated: lastUpdated,
    lastMessagePreview: lastMessagePreview,
  );

  static TicketStatus _parseStatus(String s) => switch (s) {
    'in_progress' => TicketStatus.inProgress,
    'resolved' => TicketStatus.resolved,
    'closed' => TicketStatus.closed,
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
