/// Banks in the Services tab: products as information pages, enquiries and
/// branch appointments. No payment anywhere here (banks contract v1).
library;

import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum BankProductType {
  savings(1, 'Savings'),
  current(2, 'Current account'),
  fixedDeposit(3, 'Fixed deposit'),
  loan(4, 'Loan'),
  creditCard(5, 'Credit card'),
  remittance(6, 'Remittance'),
  other(99, 'Other');

  const BankProductType(this.wire, this.label);
  final int wire;
  final String label;

  static BankProductType? fromWire(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
    for (final t in values) {
      if (t.wire == n) return t;
    }
    return null;
  }
}

enum LeadKind {
  enquiry(1),
  appointment(2);

  const LeadKind(this.wire);
  final int wire;

  static LeadKind? fromWire(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
    for (final k in values) {
      if (k.wire == n) return k;
    }
    return null;
  }
}

enum LeadStatus {
  newLead(1, 'Sent'),
  contacted(2, 'Bank contacted you'),
  qualified(3, 'In progress'),
  converted(4, 'Completed'),
  closed(5, 'Closed');

  const LeadStatus(this.wire, this.label);
  final int wire;

  /// How the buyer reads the bank's workflow state.
  final String label;

  bool get isOpen => this == newLead || this == contacted || this == qualified;

  static LeadStatus fromWire(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
    for (final s in values) {
      if (s.wire == n) return s;
    }
    return newLead;
  }
}

enum AppointmentStatus {
  booked(1, 'Booked'),
  cancelled(2, 'Cancelled'),
  completed(3, 'Completed'),
  noShow(4, 'Missed');

  const AppointmentStatus(this.wire, this.label);
  final int wire;
  final String label;

  static AppointmentStatus fromWire(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
    for (final s in values) {
      if (s.wire == n) return s;
    }
    return booked;
  }
}

enum PreferredContactMethod {
  phone(1, 'Phone'),
  email(2, 'Email'),
  either(3, 'Either');

  const PreferredContactMethod(this.wire, this.label);
  final int wire;
  final String label;

  static PreferredContactMethod fromWire(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
    for (final m in values) {
      if (m.wire == n) return m;
    }
    return phone;
  }
}

enum FormFieldType {
  text(1),
  number(2),
  amount(3),
  select(4),
  date(5),
  boolean(6),
  textArea(7);

  const FormFieldType(this.wire);
  final int wire;

  static FormFieldType fromWire(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
    for (final t in values) {
      if (t.wire == n) return t;
    }
    return text;
  }
}

enum SlotAvailability {
  available(1),
  full(2),
  past(3),
  closed(4);

  const SlotAvailability(this.wire);
  final int wire;

  static SlotAvailability fromWire(Object? raw) {
    final n = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
    for (final s in values) {
      if (s.wire == n) return s;
    }
    return closed;
  }
}

class BankSummary {
  const BankSummary({
    required this.id,
    required this.name,
    this.logoUrl,
    this.coverImageUrl,
    this.tagline,
    this.isVerified = false,
    this.productCount = 0,
    this.branchCount = 0,
    this.productTypes = const [],
    this.appointmentsAvailable = false,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? tagline;
  final bool isVerified;
  final int productCount;
  final int branchCount;
  final List<BankProductType> productTypes;
  final bool appointmentsAvailable;
}

class BankDetail {
  const BankDetail({
    required this.summary,
    this.description,
    this.websiteUrl,
    this.licenceNumber,
    this.products = const [],
    this.branches = const [],
  });

  final BankSummary summary;
  final String? description;
  final String? websiteUrl;
  final String? licenceNumber;
  final List<BankProduct> products;
  final List<BankBranch> branches;

  String get id => summary.id;
  String get name => summary.name;
}

class BankProduct {
  const BankProduct({
    required this.id,
    required this.bankId,
    required this.bankName,
    required this.type,
    required this.name,
    this.summary,
    this.description,
    this.interestRateMinPercent,
    this.interestRateMaxPercent,
    this.rateNote,
    this.feesText,
    this.eligibilityText,
    this.documentsRequired = const [],
    this.photoUrls = const [],
    this.minAmount,
    this.maxAmount,
    this.minTenureMonths,
    this.maxTenureMonths,
  });

  final String id;
  final String bankId;
  final String bankName;
  final BankProductType type;
  final String name;
  final String? summary;
  final String? description;
  final double? interestRateMinPercent;
  final double? interestRateMaxPercent;
  final String? rateNote;
  final String? feesText;
  final String? eligibilityText;
  final List<String> documentsRequired;
  final List<String> photoUrls;
  final Money? minAmount;
  final Money? maxAmount;
  final int? minTenureMonths;
  final int? maxTenureMonths;

  /// "9.5% – 11.25% p.a.", "9.5% p.a.", or null without a rate.
  String? get rateLabel {
    String pct(double v) =>
        v == v.roundToDouble() ? '${v.toInt()}%' : '${_trim(v)}%';
    final lo = interestRateMinPercent;
    final hi = interestRateMaxPercent;
    if (lo == null && hi == null) return null;
    if (lo != null && hi != null && lo != hi) {
      return '${pct(lo)} – ${pct(hi)} p.a.';
    }
    return '${pct(lo ?? hi!)} p.a.';
  }

  static String _trim(double v) {
    var s = v.toStringAsFixed(2);
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    return s.endsWith('.') ? s.substring(0, s.length - 1) : s;
  }
}

class OpeningHours {
  const OpeningHours({
    required this.dayOfWeek,
    this.opens,
    this.closes,
    this.closed = false,
  });

  /// 0 Sunday … 6 Saturday.
  final int dayOfWeek;
  final String? opens;
  final String? closes;
  final bool closed;
}

class BankBranch {
  const BankBranch({
    required this.id,
    required this.bankId,
    required this.name,
    this.addressLine,
    this.city,
    this.district,
    this.latitude,
    this.longitude,
    this.phone,
    this.openingHours = const [],
    this.appointmentsEnabled = false,
  });

  final String id;
  final String bankId;
  final String name;
  final String? addressLine;
  final String? city;
  final String? district;
  final double? latitude;
  final double? longitude;

  /// The branch's public number — never a buyer's.
  final String? phone;
  final List<OpeningHours> openingHours;
  final bool appointmentsEnabled;

  String get address => [
    if (addressLine != null) addressLine!,
    if (city != null && !(addressLine?.contains(city!) ?? false)) city!,
  ].join(', ');
}

class AvailabilitySlot {
  const AvailabilitySlot({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.remaining,
    required this.status,
    this.startUtc,
  });

  final String slotId;

  /// "10:00", Kathmandu local.
  final String startTime;
  final String endTime;
  final int remaining;
  final SlotAvailability status;
  final DateTime? startUtc;

  bool get bookable => status == SlotAvailability.available && remaining > 0;
}

class AvailabilityDay {
  const AvailabilityDay({
    required this.date,
    this.closed = false,
    this.closedReason,
    this.slots = const [],
  });

  final DateTime date;
  final bool closed;
  final String? closedReason;
  final List<AvailabilitySlot> slots;

  bool get hasBookable => !closed && slots.any((s) => s.bookable);
}

class BranchAvailability {
  const BranchAvailability({required this.branchId, required this.days});

  final String branchId;
  final List<AvailabilityDay> days;
}

class EnquiryFormField {
  const EnquiryFormField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.options = const [],
    this.min,
    this.max,
    this.maxLength,
  });

  final String key;
  final String label;
  final FormFieldType type;
  final bool required;
  final List<String> options;
  final double? min;
  final double? max;
  final int? maxLength;
}

class BankConsent {
  const BankConsent({required this.version, required this.text});

  final String version;

  /// Shown verbatim beside an unticked checkbox.
  final String text;
}

class EnquiryForm {
  const EnquiryForm({
    required this.bankId,
    required this.bankName,
    required this.productType,
    required this.fields,
    required this.consent,
  });

  final String bankId;
  final String bankName;
  final BankProductType? productType;
  final List<EnquiryFormField> fields;
  final BankConsent consent;
}

class ContactDetails {
  const ContactDetails({
    required this.name,
    required this.phone,
    this.email,
    this.preferredMethod = PreferredContactMethod.phone,
  });

  final String name;
  final String phone;
  final String? email;
  final PreferredContactMethod preferredMethod;
}

class LeadAnswer {
  const LeadAnswer({required this.key, required this.label, required this.value});

  final String key;
  final String label;
  final String value;
}

/// An enquiry (or the lead behind an appointment), as the buyer sees it.
class BankLead {
  const BankLead({
    required this.id,
    required this.reference,
    required this.kind,
    required this.status,
    required this.bankId,
    required this.bankName,
    this.productId,
    this.productType,
    this.productName,
    this.branchName,
    this.answers = const [],
    this.message,
    this.contact,
    this.consentText,
    this.consentAcceptedAt,
    this.closedReason,
    this.withdrawnAt,
    this.createdAt,
    this.statusChangedAt,
    this.appointment,
  });

  final String id;
  final String reference;
  final LeadKind? kind;
  final LeadStatus status;
  final String bankId;
  final String bankName;
  final String? productId;
  final BankProductType? productType;
  final String? productName;
  final String? branchName;
  final List<LeadAnswer> answers;
  final String? message;
  final ContactDetails? contact;
  final String? consentText;
  final DateTime? consentAcceptedAt;
  final String? closedReason;
  final DateTime? withdrawnAt;
  final DateTime? createdAt;
  final DateTime? statusChangedAt;
  final BankAppointment? appointment;

  bool get isWithdrawn => withdrawnAt != null;
  bool get canWithdraw => status.isOpen && !isWithdrawn;

  String get title => productName ?? productType?.label ?? 'Enquiry';
}

class BankAppointment {
  const BankAppointment({
    required this.id,
    required this.reference,
    required this.bankId,
    required this.bankName,
    required this.branchName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.leadId,
    this.branchId,
    this.branchAddress,
    this.startUtc,
    this.endUtc,
    this.cancelledByBank = false,
    this.cancelReason,
    this.purpose,
    this.productName,
    this.productType,
    this.contact,
    this.createdAt,
  });

  final String id;
  final String reference;
  final String bankId;
  final String bankName;
  final String branchName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final AppointmentStatus status;
  final String? leadId;
  final String? branchId;
  final String? branchAddress;
  final DateTime? startUtc;
  final DateTime? endUtc;
  final bool cancelledByBank;
  final String? cancelReason;
  final String? purpose;
  final String? productName;
  final BankProductType? productType;
  final ContactDetails? contact;
  final DateTime? createdAt;

  /// Cancellable by the buyer until the start time.
  bool canCancel(DateTime nowUtc) =>
      status == AppointmentStatus.booked &&
      (startUtc == null || nowUtc.isBefore(startUtc!));

  bool isUpcoming(DateTime nowUtc) =>
      status == AppointmentStatus.booked &&
      (endUtc ?? startUtc ?? date.add(const Duration(days: 1))).isAfter(nowUtc);
}
