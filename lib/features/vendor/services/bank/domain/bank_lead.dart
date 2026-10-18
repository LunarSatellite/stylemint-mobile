/// A bank's leads and branch appointments (service-banks contract v1, §2–3).
///
/// The buyer's contact details reach the bank only because the buyer ticked
/// consent on that one lead; after a withdrawal they are gone ([BankLead.contact]
/// is null). Bank notes never reach the buyer.
library;

/// `LeadKind`.
enum BankLeadKind {
  enquiry(1, 'Enquiry'),
  appointment(2, 'Appointment');

  const BankLeadKind(this.wire, this.label);
  final int wire;
  final String label;

  static BankLeadKind fromWire(int value) =>
      value == 2 ? appointment : enquiry;
}

/// `LeadStatus`. Forward only: New → Contacted → Qualified → Converted
/// (skipping forward is allowed); Closed from any open state, with a reason.
/// Converted and Closed are terminal.
enum BankLeadStatus {
  newLead(1, 'New'),
  contacted(2, 'Contacted'),
  qualified(3, 'Qualified'),
  converted(4, 'Converted'),
  closed(5, 'Closed');

  const BankLeadStatus(this.wire, this.label);
  final int wire;
  final String label;

  bool get isTerminal => this == converted || this == closed;
  bool get isOpen => !isTerminal;

  static BankLeadStatus fromWire(int value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return newLead;
  }

  /// Where a lead in this status may go next.
  List<BankLeadStatus> get nextStatuses {
    if (isTerminal) return const [];
    return [
      for (final s in const [contacted, qualified, converted])
        if (s.wire > wire) s,
      closed,
    ];
  }
}

/// `BankProductType`.
enum BankProductType {
  savings(1, 'Savings account'),
  current(2, 'Current account'),
  fixedDeposit(3, 'Fixed deposit'),
  loan(4, 'Loan'),
  creditCard(5, 'Credit card'),
  remittance(6, 'Remittance'),
  other(99, 'Other');

  const BankProductType(this.wire, this.label);
  final int wire;
  final String label;

  static BankProductType? fromWire(int value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// `PreferredContactMethod`.
enum BankContactMethod {
  phone(1, 'Phone'),
  email(2, 'Email'),
  either(3, 'Phone or email');

  const BankContactMethod(this.wire, this.label);
  final int wire;
  final String label;

  static BankContactMethod? fromWire(int value) {
    for (final m in values) {
      if (m.wire == value) return m;
    }
    return null;
  }
}

/// `AppointmentStatus`.
enum BankAppointmentStatus {
  booked(1, 'Booked'),
  cancelled(2, 'Cancelled'),
  completed(3, 'Completed'),
  noShow(4, 'No-show');

  const BankAppointmentStatus(this.wire, this.label);
  final int wire;
  final String label;

  static BankAppointmentStatus fromWire(int value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return booked;
  }
}

/// The buyer's consented contact details on one lead.
class BankLeadContact {
  const BankLeadContact({
    required this.name,
    this.phone,
    this.email,
    this.preferredMethod,
  });

  final String name;
  final String? phone;
  final String? email;
  final BankContactMethod? preferredMethod;
}

/// What the buyer agreed to, word for word, and when.
class BankLeadConsent {
  const BankLeadConsent({this.version, this.text, this.acceptedUtc});

  final String? version;
  final String? text;
  final DateTime? acceptedUtc;
}

class BankLeadAnswer {
  const BankLeadAnswer({
    required this.key,
    required this.label,
    required this.value,
  });

  final String key;
  final String label;
  final String value;
}

class BankAppointment {
  const BankAppointment({
    required this.id,
    required this.reference,
    required this.status,
    this.leadId,
    this.branchId,
    this.branchName,
    this.branchAddress,
    this.date,
    this.startTime,
    this.endTime,
    this.startUtc,
    this.endUtc,
    this.cancelledByBank = false,
    this.cancelledByBuyer = false,
    this.cancelReason,
    this.purpose,
    this.productType,
    this.productName,
    this.contact,
    this.createdUtc,
  });

  final String id;
  final String reference;
  final BankAppointmentStatus status;
  final String? leadId;
  final String? branchId;
  final String? branchName;
  final String? branchAddress;

  /// The Kathmandu calendar date of the visit.
  final DateTime? date;

  /// "10:00", Kathmandu local.
  final String? startTime;
  final String? endTime;
  final DateTime? startUtc;
  final DateTime? endUtc;
  final bool cancelledByBank;
  final bool cancelledByBuyer;
  final String? cancelReason;
  final String? purpose;
  final BankProductType? productType;
  final String? productName;

  /// Consented details; null after the buyer withdrew.
  final BankLeadContact? contact;
  final DateTime? createdUtc;

  bool get isBooked => status == BankAppointmentStatus.booked;

  /// "10:00–10:30".
  String get timeText {
    final start = startTime ?? '';
    final end = endTime ?? '';
    if (start.isEmpty) return '';
    return end.isEmpty ? start : '$start–$end';
  }

  /// What the visit is about, for a list row.
  String get topic =>
      productName ?? purpose ?? productType?.label ?? 'Branch visit';

  /// The bank may mark Completed / No-show only after the start time.
  bool hasStarted(DateTime nowUtc) {
    final start = startUtc;
    return start != null && !nowUtc.isBefore(start);
  }

  BankAppointment copyWith({BankAppointmentStatus? status}) => BankAppointment(
    id: id,
    reference: reference,
    status: status ?? this.status,
    leadId: leadId,
    branchId: branchId,
    branchName: branchName,
    branchAddress: branchAddress,
    date: date,
    startTime: startTime,
    endTime: endTime,
    startUtc: startUtc,
    endUtc: endUtc,
    cancelledByBank: cancelledByBank,
    cancelledByBuyer: cancelledByBuyer,
    cancelReason: cancelReason,
    purpose: purpose,
    productType: productType,
    productName: productName,
    contact: contact,
    createdUtc: createdUtc,
  );
}

/// One lead as the bank sees it (`GET v1/vendor/bank/leads/{id}`).
class BankLead {
  const BankLead({
    required this.id,
    required this.reference,
    required this.kind,
    required this.status,
    this.statusChangedUtc,
    this.productId,
    this.productType,
    this.productName,
    this.branchId,
    this.branchName,
    this.answers = const [],
    this.message,
    this.contact,
    this.consent,
    this.appointment,
    this.closedReason,
    this.withdrawnUtc,
    this.noteCount = 0,
    this.createdUtc,
    this.updatedUtc,
  });

  final String id;
  final String reference;
  final BankLeadKind kind;
  final BankLeadStatus status;
  final DateTime? statusChangedUtc;
  final String? productId;
  final BankProductType? productType;
  final String? productName;
  final String? branchId;
  final String? branchName;
  final List<BankLeadAnswer> answers;
  final String? message;

  /// The buyer's consented contact details; null once withdrawn.
  final BankLeadContact? contact;
  final BankLeadConsent? consent;
  final BankAppointment? appointment;
  final String? closedReason;
  final DateTime? withdrawnUtc;
  final int noteCount;
  final DateTime? createdUtc;
  final DateTime? updatedUtc;

  bool get isWithdrawn => withdrawnUtc != null;

  /// A phone number the bank may call or WhatsApp: there is consent on this
  /// lead, it was not withdrawn, and a number was given.
  String? get consentedPhone {
    if (isWithdrawn) return null;
    final phone = contact?.phone?.trim();
    return phone == null || phone.isEmpty ? null : phone;
  }

  String get title =>
      productName ?? productType?.label ?? (kind == BankLeadKind.appointment
          ? 'Branch appointment'
          : 'Enquiry');

  String get displayName =>
      isWithdrawn ? 'Withdrawn by the buyer' : (contact?.name ?? 'Buyer');
}

class BankLeadNote {
  const BankLeadNote({required this.id, required this.text, this.createdUtc});

  final String id;
  final String text;
  final DateTime? createdUtc;
}

/// `GET v1/vendor/bank/profile`.
class BankVendorSummary {
  const BankVendorSummary({
    required this.businessName,
    this.newLeads = 0,
    this.upcomingAppointments = 0,
    this.publishedProducts = 0,
    this.branches = 0,
    this.isApproved = true,
  });

  final String businessName;
  final int newLeads;
  final int upcomingAppointments;
  final int publishedProducts;
  final int branches;
  final bool isApproved;
}
