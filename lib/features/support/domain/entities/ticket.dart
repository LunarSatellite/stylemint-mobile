/// 3-state projection the backend exposes — internal WaitingOnUser/Closed
/// states are rolled into inProgress/resolved server-side (skill §2.3).
enum TicketStatus { open, inProgress, resolved }

/// Mirrors the backend's `SupportCategory` enum (int-valued, 1-8).
enum TicketCategory {
  ordersAndShipping,
  returnsAndRefunds,
  accountAndSettings,
  paymentAndBilling,
  safetyAndPrivacy,
  forCreators,
  forVendors,
  deliveryAndCouriers,
}

extension TicketCategoryWireValue on TicketCategory {
  int get wireValue => TicketCategory.values.indexOf(this) + 1;
}

class Ticket {
  const Ticket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.lastUpdated,
    required this.lastMessagePreview,
  });

  final String id;
  final String ticketNumber;
  final String subject;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String? lastMessagePreview;

  Ticket copyWith({
    String? id,
    String? ticketNumber,
    String? subject,
    TicketStatus? status,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? lastMessagePreview,
  }) {
    return Ticket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
