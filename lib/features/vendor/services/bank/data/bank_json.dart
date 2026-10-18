import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';

/// JSON → bank lead entities (service-banks contract v1, §3). Tolerant: an
/// odd field reads as empty instead of failing the row; a row without an id
/// is unreadable ([FormatException]).

String _requireId(Map<String, dynamic> json) {
  final id = readOptionalString(json['id']);
  if (id == null) throw const FormatException('No id');
  return id;
}

int _enumInt(Object? raw) {
  final value = normalizeWireEnum(raw);
  return value is int ? value : 0;
}

BankLeadContact? readBankLeadContact(Object? raw) {
  if (raw is! Map) return null;
  final name = readOptionalString(raw['name']);
  final phone = readOptionalString(raw['phone']);
  final email = readOptionalString(raw['email']);
  if (name == null && phone == null && email == null) return null;
  return BankLeadContact(
    name: name ?? 'Buyer',
    phone: phone,
    email: email,
    preferredMethod: BankContactMethod.fromWire(
      _enumInt(raw['preferredMethod']),
    ),
  );
}

BankLeadConsent? readBankLeadConsent(Object? raw) {
  if (raw is! Map) return null;
  return BankLeadConsent(
    version: readOptionalString(raw['version']),
    text: readOptionalString(raw['text']),
    acceptedUtc: readDate(raw['acceptedUtc']),
  );
}

BankAppointment readBankAppointment(Map<String, dynamic> json) {
  final cancelledBy = _enumInt(json['cancelledBy']);
  return BankAppointment(
    id: _requireId(json),
    reference: readString(json['reference']),
    status: BankAppointmentStatus.fromWire(_enumInt(json['status'])),
    leadId: readOptionalString(json['leadId']),
    branchId: readOptionalString(json['branchId']),
    branchName: readOptionalString(json['branchName']),
    branchAddress: readOptionalString(json['branchAddress']),
    date: readWireDate(json['date']),
    startTime: readOptionalString(json['startTime']),
    endTime: readOptionalString(json['endTime']),
    startUtc: readDate(json['startUtc']),
    endUtc: readDate(json['endUtc']),
    cancelledByBuyer: cancelledBy == 1,
    cancelledByBank: cancelledBy == 2,
    cancelReason: readOptionalString(json['cancelReason']),
    purpose: readOptionalString(json['purpose']),
    productType: BankProductType.fromWire(_enumInt(json['productType'])),
    productName: readOptionalString(json['productName']),
    contact: readBankLeadContact(json['contact']),
    createdUtc: readDate(json['createdUtc']),
  );
}

BankLead readBankLead(Map<String, dynamic> json) {
  final rawAnswers = json['answers'];
  final answers = <BankLeadAnswer>[
    if (rawAnswers is List)
      for (final a in rawAnswers)
        if (a is Map && readOptionalString(a['value']) != null)
          BankLeadAnswer(
            key: readString(a['key']),
            label:
                readOptionalString(a['label']) ?? readString(a['key']),
            value: readString(a['value']),
          ),
  ];
  final rawAppointment = json['appointment'];
  BankAppointment? appointment;
  if (rawAppointment is Map) {
    try {
      appointment = readBankAppointment(
        Map<String, dynamic>.from(rawAppointment),
      );
    } on FormatException {
      appointment = null;
    }
  }
  final withdrawnUtc = readDate(json['withdrawnUtc']);
  return BankLead(
    id: _requireId(json),
    reference: readString(json['reference']),
    kind: BankLeadKind.fromWire(_enumInt(json['kind'])),
    status: BankLeadStatus.fromWire(_enumInt(json['status'])),
    statusChangedUtc: readDate(json['statusChangedUtc']),
    productId: readOptionalString(json['productId']),
    productType: BankProductType.fromWire(_enumInt(json['productType'])),
    productName: readOptionalString(json['productName']),
    branchId: readOptionalString(json['branchId']),
    branchName: readOptionalString(json['branchName']),
    answers: List.unmodifiable(answers),
    message: readOptionalString(json['message']),
    // After a withdrawal the server sends null; never show stale details.
    contact: withdrawnUtc != null ? null : readBankLeadContact(json['contact']),
    consent: readBankLeadConsent(json['consent']),
    appointment: appointment,
    closedReason: readOptionalString(json['closedReason']),
    withdrawnUtc: withdrawnUtc,
    noteCount: readInt(json['noteCount']),
    createdUtc: readDate(json['createdUtc']),
    updatedUtc: readDate(json['updatedUtc']),
  );
}

BankLeadNote readBankLeadNote(Map<String, dynamic> json) => BankLeadNote(
  id: _requireId(json),
  text: readString(json['text']),
  createdUtc: readDate(json['createdUtc']),
);

BankVendorSummary readBankVendorSummary(Map<String, dynamic> json) {
  final counts = json['counts'] is Map
      ? Map<String, dynamic>.from(json['counts'] as Map)
      : const <String, dynamic>{};
  return BankVendorSummary(
    businessName: readString(json['businessName']),
    isApproved: json['isApproved'] is bool ? json['isApproved'] as bool : true,
    newLeads: readInt(counts['newLeads']),
    upcomingAppointments: readInt(counts['upcomingAppointments']),
    publishedProducts: readInt(counts['publishedProducts']),
    branches: readInt(counts['branches']),
  );
}
