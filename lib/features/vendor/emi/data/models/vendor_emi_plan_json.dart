import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi_plan.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// One `VendorCreditApplicationDto` from `v1/credit/vendor/plans` (contract
/// v1). The at-a-glance figures (`paidToDate`, `nextInstalment`,
/// `lateFeesOutstanding`, `downPaymentStatus`) are worked out from the
/// schedule when a server without them sends none.
VendorEmiPlan readVendorEmiPlan(Map<String, dynamic> json) {
  final raw = json['agreement'];
  if (raw is! Map) throw const FormatException('Plan: no agreement');
  final agreementJson = Map<String, dynamic>.from(raw);
  final a = readCreditAgreement(agreementJson);
  final currency = a.price.currency;
  Money money(double amount) => Money(amount: amount, currency: currency);

  final paidToDate = readOptionalDouble(agreementJson['paidToDate']);
  final collected =
      paidToDate ??
      ((a.activatedAt != null && a.downPayment.amount > 0
              ? a.downPayment.amount
              : 0.0) +
          a.instalments.fold<double>(0, (sum, i) => sum + i.paid.amount));

  var next = a.nextDue;
  final nextJson = agreementJson['nextInstalment'];
  if (nextJson is Map) {
    final number = readInt(nextJson['number']);
    for (final i in a.instalments) {
      if (i.number == number) next = i;
    }
  } else if (agreementJson.containsKey('nextInstalment')) {
    // The server says nothing is owed.
    next = null;
  }

  final lateFees =
      readOptionalDouble(agreementJson['lateFeesOutstanding']) ??
      a.instalments
          .where((i) => !i.status.isSettled)
          .fold<double>(0, (sum, i) => sum + i.lateFeeDue.amount);

  final firstScheduled = a.instalments.isEmpty
      ? 0.0
      : a.instalments.first.scheduled.amount;
  final monthly = readOptionalDouble(json['monthlyInstalment']);
  return VendorEmiPlan(
    agreement: a,
    buyerDisplayName: readOptionalString(json['buyerDisplayName']) ?? 'Buyer',
    productName: readString(json['productName']),
    monthlyInstalment: money(monthly ?? firstScheduled),
    downPaymentStatus:
        VendorDownPaymentStatus.fromWire(json['downPaymentStatus']) ??
        VendorDownPaymentStatus.of(a),
    collected: money(collected),
    lateFeesOutstanding: money(lateFees),
    nextInstalment: next,
    orderNumber: readOptionalString(json['orderNumber']),
    vendorSubOrderId: readOptionalString(json['vendorSubOrderId']),
  );
}

/// The list: a bare array (or `{ items: [...] }`). One unreadable row does
/// not hide the seller's other plans.
List<VendorEmiPlan> readVendorEmiPlans(Object? raw) {
  final items = raw is List
      ? raw
      : raw is Map && raw['items'] is List
      ? raw['items'] as List
      : const <dynamic>[];
  final plans = <VendorEmiPlan>[];
  for (final item in items) {
    if (item is! Map) continue;
    try {
      plans.add(readVendorEmiPlan(Map<String, dynamic>.from(item)));
    } on FormatException {
      continue;
    }
  }
  return List.unmodifiable(plans);
}
