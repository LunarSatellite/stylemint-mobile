import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';

enum TicketStatus { open, inProgress, resolved, closed }

class Ticket {
  const Ticket({
    required this.id,
    required this.ticketNumber,
    required this.category,
    required this.subject,
    required this.status,
    required this.createdAt,
    this.lastAgentReplyAt,
  });

  final String id;
  final String ticketNumber;
  final SupportTicketCategory category;
  final String subject;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime? lastAgentReplyAt;

  Ticket copyWith({
    String? id,
    String? ticketNumber,
    SupportTicketCategory? category,
    String? subject,
    TicketStatus? status,
    DateTime? createdAt,
    DateTime? lastAgentReplyAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastAgentReplyAt: lastAgentReplyAt ?? this.lastAgentReplyAt,
    );
  }
}
