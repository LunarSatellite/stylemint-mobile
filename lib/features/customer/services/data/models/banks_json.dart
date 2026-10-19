import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Readers for the banks contract v1 payloads (`/v1/services/banks/*`,
/// `/v1/service-enquiries/*`, `/v1/service-appointments/*`).
///
/// Tolerant in the usual way, except that a record without an id is refused
/// with a [FormatException]: a row the buyer cannot open is worse than none.

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;

List<Map<String, dynamic>> _maps(Object? raw) => [
  for (final e in raw is List ? raw : const []) ?_map(e),
];

List<String> _strings(Object? raw) => raw is List
    ? List.unmodifiable(
        raw.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty),
      )
    : const <String>[];

String _id(Map<String, dynamic> json, String key, String what) {
  final id = readString(json[key]);
  if (id.isEmpty) throw FormatException('$what: no $key');
  return id;
}

Money? _money(Object? raw, String currency) {
  final amount = readOptionalDouble(raw);
  return amount == null ? null : Money(amount: amount, currency: currency);
}

int? _optionalInt(Object? raw) {
  if (raw == null) return null;
  final n = readInt(raw);
  return raw is String && int.tryParse(raw.trim()) == null ? null : n;
}

/// A `yyyy-MM-dd` calendar date as a local midnight, never shifted.
DateTime? readCalendarDate(Object? raw) {
  final s = readString(raw);
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

BankSummary readBankSummary(Map<String, dynamic> json) => BankSummary(
  id: _id(json, 'bankId', 'Bank'),
  name: readString(json['name']),
  logoUrl: readOptionalString(json['logoUrl']),
  coverImageUrl: readOptionalString(json['coverImageUrl']),
  tagline: readOptionalString(json['tagline']),
  isVerified: readBool(json['isVerified']),
  productCount: readInt(json['productCount']),
  branchCount: readInt(json['branchCount']),
  productTypes: List.unmodifiable([
    for (final t in json['productTypes'] is List
        ? json['productTypes'] as List
        : const [])
      ?BankProductType.fromWire(t),
  ]),
  appointmentsAvailable: readBool(json['appointmentsAvailable']),
);

/// A paged list of banks. Rows that cannot be read are skipped.
List<BankSummary> readBankSummaries(Object? raw) => [
  for (final item in raw is List ? _maps(raw) : readPagedItems(raw))
    ?_tryRead(() => readBankSummary(item)),
];

T? _tryRead<T>(T Function() read) {
  try {
    return read();
  } on FormatException {
    return null;
  }
}

BankDetail readBankDetail(Map<String, dynamic> json) => BankDetail(
  summary: readBankSummary(json),
  description: readOptionalString(json['description']),
  websiteUrl: readOptionalString(json['websiteUrl']),
  licenceNumber: readOptionalString(json['licenceNumber']),
  products: List.unmodifiable([
    for (final p in _maps(json['products'])) ?_tryRead(() => readBankProduct(p)),
  ]),
  branches: List.unmodifiable([
    for (final b in _maps(json['branches'])) ?_tryRead(() => readBankBranch(b)),
  ]),
);

BankProduct readBankProduct(Map<String, dynamic> json) {
  final currency = readOptionalString(json['currency']) ?? 'NPR';
  return BankProduct(
    id: _id(json, 'id', 'Bank product'),
    bankId: readString(json['bankId']),
    bankName: readString(json['bankName']),
    type: BankProductType.fromWire(json['type']) ?? BankProductType.other,
    name: readString(json['name']),
    summary: readOptionalString(json['summary']),
    description: readOptionalString(json['description']),
    interestRateMinPercent: readOptionalDouble(json['interestRateMinPercent']),
    interestRateMaxPercent: readOptionalDouble(json['interestRateMaxPercent']),
    rateNote: readOptionalString(json['rateNote']),
    feesText: readOptionalString(json['feesText']),
    eligibilityText: readOptionalString(json['eligibilityText']),
    documentsRequired: _strings(json['documentsRequired']),
    photoUrls: _strings(json['photoUrls']),
    minAmount: _money(json['minAmount'], currency),
    maxAmount: _money(json['maxAmount'], currency),
    minTenureMonths: _optionalInt(json['minTenureMonths']),
    maxTenureMonths: _optionalInt(json['maxTenureMonths']),
  );
}

List<BankProduct> readBankProducts(Object? raw) => [
  for (final item in raw is List ? _maps(raw) : readPagedItems(raw))
    ?_tryRead(() => readBankProduct(item)),
];

BankBranch readBankBranch(Map<String, dynamic> json) => BankBranch(
  id: _id(json, 'id', 'Branch'),
  bankId: readString(json['bankId']),
  name: readString(json['name']),
  addressLine: readOptionalString(json['addressLine']),
  city: readOptionalString(json['city']),
  district: readOptionalString(json['district']),
  latitude: readOptionalDouble(json['latitude']),
  longitude: readOptionalDouble(json['longitude']),
  phone: readOptionalString(json['phone']),
  openingHours: List.unmodifiable([
    for (final h in _maps(json['openingHours']))
      OpeningHours(
        dayOfWeek: readInt(h['dayOfWeek']),
        opens: readOptionalString(h['opens']),
        closes: readOptionalString(h['closes']),
        closed: readBool(h['closed']),
      ),
  ]),
  appointmentsEnabled: readBool(json['appointmentsEnabled']),
);

List<BankBranch> readBankBranches(Object? raw) => [
  for (final item in raw is List ? _maps(raw) : readPagedItems(raw))
    ?_tryRead(() => readBankBranch(item)),
];

BranchAvailability readBranchAvailability(Map<String, dynamic> json) =>
    BranchAvailability(
      branchId: readString(json['branchId']),
      days: List.unmodifiable([
        for (final d in _maps(json['days']))
          if (readCalendarDate(d['date']) case final date?)
            AvailabilityDay(
              date: date,
              closed: readBool(d['closed']),
              closedReason: readOptionalString(d['closedReason']),
              slots: List.unmodifiable([
                for (final s in _maps(d['slots']))
                  if (readString(s['slotId']).isNotEmpty)
                    AvailabilitySlot(
                      slotId: readString(s['slotId']),
                      startTime: readString(s['startTime']),
                      endTime: readString(s['endTime']),
                      remaining: readInt(s['remaining']),
                      status: SlotAvailability.fromWire(s['status']),
                      startUtc: readDate(s['startUtc']),
                    ),
              ]),
            ),
      ]),
    );

EnquiryForm readEnquiryForm(Map<String, dynamic> json) {
  final consent = _map(json['consent']) ?? const <String, dynamic>{};
  final version = readString(consent['version']);
  final text = readString(consent['text']);
  // Without the wording there is nothing the buyer can agree to.
  if (version.isEmpty || text.isEmpty) {
    throw const FormatException('Enquiry form: no consent');
  }
  return EnquiryForm(
    bankId: readString(json['bankId']),
    bankName: readString(json['bankName']),
    productType: BankProductType.fromWire(json['productType']),
    fields: List.unmodifiable([
      for (final f in _maps(json['fields']))
        if (readString(f['key']).isNotEmpty)
          EnquiryFormField(
            key: readString(f['key']),
            label: readOptionalString(f['label']) ?? readString(f['key']),
            type: FormFieldType.fromWire(f['type']),
            required: readBool(f['required']),
            options: _strings(f['options']),
            min: readOptionalDouble(f['min']),
            max: readOptionalDouble(f['max']),
            maxLength: f['maxLength'] == null ? null : readInt(f['maxLength']),
          ),
    ]),
    consent: BankConsent(version: version, text: text),
  );
}

ContactDetails? _contact(Object? raw) {
  final json = _map(raw);
  if (json == null) return null;
  return ContactDetails(
    name: readString(json['name']),
    phone: readString(json['phone']),
    email: readOptionalString(json['email']),
    preferredMethod: PreferredContactMethod.fromWire(json['preferredMethod']),
  );
}

BankLead readBankLead(Map<String, dynamic> json) {
  final consent = _map(json['consent']);
  final appointment = _map(json['appointment']);
  return BankLead(
    id: _id(json, 'id', 'Enquiry'),
    reference: readString(json['reference']),
    kind: LeadKind.fromWire(json['kind']),
    status: LeadStatus.fromWire(json['status']),
    bankId: readString(json['bankId']),
    bankName: readString(json['bankName']),
    productId: readOptionalString(json['productId']),
    productType: BankProductType.fromWire(json['productType']),
    productName: readOptionalString(json['productName']),
    branchName: readOptionalString(json['branchName']),
    answers: List.unmodifiable([
      for (final a in _maps(json['answers']))
        LeadAnswer(
          key: readString(a['key']),
          label: readOptionalString(a['label']) ?? readString(a['key']),
          value: readString(a['value']),
        ),
    ]),
    message: readOptionalString(json['message']),
    contact: _contact(json['contact']),
    consentText: consent == null ? null : readOptionalString(consent['text']),
    consentAcceptedAt: consent == null
        ? null
        : readDate(consent['acceptedUtc']),
    closedReason: readOptionalString(json['closedReason']),
    withdrawnAt: readDate(json['withdrawnUtc']),
    createdAt: readDate(json['createdUtc']),
    statusChangedAt: readDate(json['statusChangedUtc']),
    appointment: appointment == null
        ? null
        : _tryRead(() => readBankAppointment(appointment)),
  );
}

List<BankLead> readBankLeads(Object? raw) => [
  for (final item in raw is List ? _maps(raw) : readPagedItems(raw))
    ?_tryRead(() => readBankLead(item)),
];

BankAppointment readBankAppointment(Map<String, dynamic> json) {
  final date = readCalendarDate(json['date']);
  if (date == null) throw const FormatException('Appointment: no date');
  return BankAppointment(
    id: _id(json, 'id', 'Appointment'),
    reference: readString(json['reference']),
    bankId: readString(json['bankId']),
    bankName: readString(json['bankName']),
    branchName: readString(json['branchName']),
    date: date,
    startTime: readString(json['startTime']),
    endTime: readString(json['endTime']),
    status: AppointmentStatus.fromWire(json['status']),
    leadId: readOptionalString(json['leadId']),
    branchId: readOptionalString(json['branchId']),
    branchAddress: readOptionalString(json['branchAddress']),
    startUtc: readDate(json['startUtc']),
    endUtc: readDate(json['endUtc']),
    cancelledByBank: readInt(json['cancelledBy']) == 2,
    cancelReason: readOptionalString(json['cancelReason']),
    purpose: readOptionalString(json['purpose']),
    productName: readOptionalString(json['productName']),
    productType: BankProductType.fromWire(json['productType']),
    contact: _contact(json['contact']),
    createdAt: readDate(json['createdUtc']),
  );
}

List<BankAppointment> readBankAppointments(Object? raw) => [
  for (final item in raw is List ? _maps(raw) : readPagedItems(raw))
    ?_tryRead(() => readBankAppointment(item)),
];

Map<String, dynamic> contactJson(ContactDetails c) => <String, dynamic>{
  'name': c.name.trim(),
  'phone': c.phone.trim(),
  if (c.email != null && c.email!.trim().isNotEmpty) 'email': c.email!.trim(),
  'preferredMethod': c.preferredMethod.wire,
};
