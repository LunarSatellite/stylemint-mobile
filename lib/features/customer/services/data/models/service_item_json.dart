import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/banks_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/bookings_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_item.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Readers for the service item fields on a `ProductDto` and a reel's
/// `TaggedProductDto` (service items contract v1 §4, §5.1).
///
/// A server before that contract sends none of them; every reader then
/// returns null and the item is a normal product.

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;

T? _try<T>(T Function() read) {
  try {
    return read();
  } on Object {
    // A part this build cannot read is left out, never shown half-read.
    return null;
  }
}

/// `serviceType`, or null for a normal product.
ServiceItemType? readServiceItemType(Map<String, dynamic> json) =>
    ServiceItemType.fromWire(json['serviceType']);

/// `displayPrice`, or null when absent.
DisplayPrice? readDisplayPrice(Object? raw) {
  final json = _map(raw);
  if (json == null) return null;
  final amount = readOptionalDouble(json['amount']);
  return DisplayPrice(
    amount: amount == null
        ? null
        : Money(
            amount: amount,
            currency: readOptionalString(json['currency']) ?? 'NPR',
          ),
    unit: readOptionalString(json['unit']),
    isFrom: readBool(json['isFrom']),
    label: readOptionalString(json['label']),
  );
}

/// The `service` block. Null when absent, or when the owning module could
/// not answer (§4: "best effort") — the page then says the item is being
/// set up. A part that cannot be read (a stay without its listing id, a
/// form without consent wording) is left out rather than shown wrong.
ServiceItem? readServiceItem(Object? raw) {
  final json = _map(raw);
  if (json == null) return null;
  final type = ServiceItemType.fromWire(json['type']);
  if (type == null) return null;
  final stay = _map(json['stay']);
  final package = _map(json['package']);
  final bank = _map(json['bank']);
  return ServiceItem(
    type: type,
    listingId: readString(json['listingId']),
    addableToCart: readBool(json['addableToCart']),
    priceUnit: readOptionalString(json['priceUnit']),
    stay: stay == null ? null : _try(() => readStayDetail(stay)),
    package: package == null ? null : _try(() => readPackageDetail(package)),
    bank: bank == null ? null : _try(() => _bank(bank)),
  );
}

BankItem _bank(Map<String, dynamic> json) {
  final product = _map(json['product']);
  final enquiry = _map(json['enquiryForm']);
  final appointment = _map(json['appointmentForm']);
  return BankItem(
    bankId: readString(json['bankId']),
    bankName: readString(json['bankName']),
    product: product == null ? null : _try(() => readBankProduct(product)),
    branches: List.unmodifiable(readBankBranches(json['branches'])),
    enquiryForm: enquiry == null ? null : _try(() => readEnquiryForm(enquiry)),
    appointmentForm: appointment == null
        ? null
        : _try(() => readEnquiryForm(appointment)),
  );
}
